import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:http/http.dart' as http;
import 'package:pub_semver/pub_semver.dart' as semver;
import 'package:shelf/shelf.dart' as shelf;
import 'package:logging/logging.dart';
import 'package:pub_server/repository.dart';
import 'package:yaml/yaml.dart';
import 'package:archive/archive.dart';
import 'package:googleapis/oauth2/v2.dart';
import 'meta_store.dart';
import 'package_store.dart';

final Logger _logger = new Logger('unpub.repository');

class UnpubRepository extends PackageRepository {
  UnpubMetaStore metaStore;
  UnpubPackageStore packageStore;
  bool supportsDownloadUrl;
  String proxyUrl;

  Future<String> Function(String token) uploaderEmailGetter;
  Future<void> Function(dynamic pubspecJson, String email) uploadValidator;

  static var _httpClient = http.Client();

  static Future<void> defaultUploadValidator(_, __) async {}

  static Future<String> defaultUploaderEmailGetter(String token) async {
    var info = await Oauth2Api(_httpClient).tokeninfo(accessToken: token);
    if (info == null) return null;
    return info.email;
  }

  UnpubRepository({
    @required this.metaStore,
    @required this.packageStore,

    /// Upstream proxy
    this.proxyUrl = 'https://pub.dev',

    ///
    this.uploaderEmailGetter = defaultUploaderEmailGetter,

    ///
    this.uploadValidator = defaultUploadValidator,

    ///
    this.supportsDownloadUrl = true,
  });

  @override
  Stream<PackageVersion> versions(String name) async* {
    var versions = await metaStore.getAllVersions(name).toList();

    if (versions.isEmpty) {
      name = Uri.encodeComponent(name);
      var res = await _httpClient.get('$proxyUrl/api/packages/$name');
      if (res.statusCode != 200) return;

      // TODO: No need to parse
      var data = json.decode(res.body);
      var versions = data['versions'] as List<dynamic>;

      if (versions == null) return;

      for (var item in versions) {
        var pubspec = item['pubspec'];
        var pubspecString = json.encode(pubspec);
        yield PackageVersion(pubspec['name'] as String,
            pubspec['version'] as String, pubspecString);
      }
    } else {
      metaStore.increaseQueryCount(name);
      yield* Stream.fromIterable(versions
          .map((item) => PackageVersion(name, item.version, item.pubspecYaml)));
    }
  }

  @override
  Future<PackageVersion> lookupVersion(String name, String version) async {
    var item = await metaStore.getVersion(name, version);
    if (item == null) {
      name = Uri.encodeComponent(name);
      version = Uri.encodeComponent(version);
      var res = await _httpClient
          .get('$proxyUrl/api/packages/$name/versions/$version');
      if (res.statusCode != 200) return null;

      var data = json.decode(res.body);
      var pubspec = data['pubspec'];
      var pubspecString = json.encode(pubspec);

      return PackageVersion(pubspec['name'] as String,
          pubspec['version'] as String, pubspecString);
    } else {
      metaStore.increaseQueryCount(name);
      return PackageVersion(name, item.version, item.pubspecYaml);
    }
  }

  @override
  bool get supportsUpload => true;

  Future<String> _getUploaderEmail(shelf.Request request) async {
    var authHeader = request.headers[HttpHeaders.authorizationHeader];
    if (authHeader == null) {
      throw UnauthorizedAccessException('');
    }

    var token = authHeader.split(' ').last;
    var email = await uploaderEmailGetter(token);
    return email;
  }

  @override
  Future<PackageVersion> upload(Stream<List<int>> data, {request}) async {
    var email = await _getUploaderEmail(request);

    _logger.info('Start uploading package.');
    var bb = await data.fold(
        BytesBuilder(), (BytesBuilder byteBuilder, d) => byteBuilder..add(d));
    var tarballBytes = bb.takeBytes();
    var tarBytes = GZipDecoder().decodeBytes(tarballBytes);
    var archive = TarDecoder().decodeBytes(tarBytes);
    ArchiveFile pubspecArchiveFile;
    for (var file in archive.files) {
      if (file.name == 'pubspec.yaml') {
        pubspecArchiveFile = file;
        break;
      }
    }

    if (pubspecArchiveFile == null) {
      throw 'Did not find any pubspec.yaml file in upload. Aborting.';
    }

    // TODO: Error handling.
    var pubspec = loadYaml(utf8.decode(_getBytes(pubspecArchiveFile)));

    // Validator
    await uploadValidator(pubspec, email);

    var name = pubspec['name'] as String;
    var version = pubspec['version'] as String;

    var newerOrEqualVersion = await metaStore.getAllVersions(name).firstWhere(
      (item) {
        var existingVersion = semver.Version.parse(item.version);
        var newVersion = semver.Version.parse(version);
        return existingVersion.compareTo(newVersion) >= 0;
      },
      orElse: () => null,
    );

    if (newerOrEqualVersion != null) {
      throw StateError(
          'version invalid: ${newerOrEqualVersion.version} exists, which is newer than $version, aborting');
    }

    var packageEmpty = await metaStore.getAllVersions(name).isEmpty;
    if (!packageEmpty) {
      var uploaders = await metaStore.getUploaders(name).toList();
      if (!uploaders.contains(email)) {
        throw UnauthorizedAccessException('');
      }
    }

    var pubspecContent = utf8.decode(pubspecArchiveFile.content);

    // Upload package tar to storage
    await packageStore.upload(name, version, tarballBytes);

    // Write package meta to database
    await metaStore.addVersion(
        name, UnpubVersion.fromPubspec(pubspecContent), email);

    // TODO: Upload docs

    return PackageVersion(name, version, pubspecContent);
  }

  @override
  Future<Stream<List<int>>> download(String package, String version) async {
    var item = await metaStore.getVersion(package, version);
    if (item == null) {
      _logger.info('Downloading package $package/$version.');
      package = Uri.encodeComponent(package);
      version = Uri.encodeComponent(version);

      var response = await _httpClient.send(http.Request(
          'GET',
          Uri.parse(proxyUrl)
              .resolve('/packages/$package/versions/$version.tar.gz')));
      return response.stream;
    } else {
      metaStore.increaseDownloadCount(package);
      return packageStore.download(package, version);
    }
  }

  @override
  Future<Uri> downloadUrl(String package, String version) async {
    var item = await metaStore.getVersion(package, version);
    if (item == null) {
      package = Uri.encodeComponent(package);
      version = Uri.encodeComponent(version);
      return Uri.parse(proxyUrl)
          .resolve('/packages/$package/versions/$version.tar.gz');
    } else {
      metaStore.increaseDownloadCount(package);
      return packageStore.downloadUri(package, version);
    }
  }

  bool get supportsUploaders => true;

  Future addUploader(String package, String emailToAdd, {request}) async {
    var email = await _getUploaderEmail(request);

    var uploaders = await metaStore.getUploaders(package).toList();
    if (!uploaders.contains(email)) {
      throw UnauthorizedAccessException('');
    }

    if (uploaders.contains(emailToAdd)) {
      throw UploaderAlreadyExistsException();
    }

    if (emailToAdd == email) {
      throw GenericProcessingException('Cannot remove self');
    }

    await metaStore.addUploader(package, emailToAdd);
  }

  Future removeUploader(String package, String emailToAdd, {request}) async {
    var email = await _getUploaderEmail(request);

    var uploaders = await metaStore.getUploaders(package).toList();
    if (!uploaders.contains(email)) {
      throw UnauthorizedAccessException('');
    }

    if (emailToAdd == email) {
      throw GenericProcessingException('Cannot remove self');
    }

    if (uploaders.length <= 1) {
      throw LastUploaderRemoveException();
    }

    await metaStore.removeUploader(package, emailToAdd);
  }
}

List<int> _getBytes(ArchiveFile file) => file.content as List<int>;
