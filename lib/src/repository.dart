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
import 'http_proxy_repository.dart';
import 'meta_store.dart';
import 'package_store.dart';

final Logger _logger = new Logger('unpub.repository');

Future<bool> defaultPackageValidator(String name) async => true;
Future<bool> defaultUploaderValidator(Tokeninfo info) async => true;

class UnpubRepository extends PackageRepository {
  UnpubMetaStore metaStore;
  UnpubPackageStore packageStore;
  HttpProxyRepository proxy;
  bool shouldCheckUploader;
  Future<bool> Function(String name) packageValidator;
  Future<bool> Function(Tokeninfo info) uploaderValidator;

  String googleapisProxy;
  HttpClient googleapisClient;

  static var _httpClient = http.Client();

  UnpubRepository({
    @required this.metaStore,
    @required this.packageStore,

    /// Upstream proxy
    String proxyUrl = 'https://pub.dartlang.org',

    ///
    this.shouldCheckUploader = true,

    ///
    this.packageValidator = defaultPackageValidator,

    ///
    this.uploaderValidator = defaultUploaderValidator,

    ///
    this.googleapisProxy,
  }) : proxy = HttpProxyRepository(_httpClient, Uri.parse(proxyUrl));

  @override
  Stream<PackageVersion> versions(String name) async* {
    var versions = await metaStore.getAllVersions(name).toList();

    if (versions.isEmpty) {
      yield* proxy.versions(name);
    } else {
      yield* Stream.fromIterable(versions
          .map((item) => PackageVersion(name, item.version, item.pubspecYaml)));
    }
  }

  @override
  Future<PackageVersion> lookupVersion(String name, String version) async {
    var item = await metaStore.getVersion(name, version);
    if (item == null) {
      return proxy.lookupVersion(name, version);
    } else {
      return PackageVersion(name, item.version, item.pubspecYaml);
    }
  }

  @override
  bool get supportsUpload => true;

  Future<Tokeninfo> _getOperatorTokenInfo(shelf.Request request) async {
    var authHeader = request.headers[HttpHeaders.authorizationHeader];
    if (authHeader == null) {
      throw UnauthorizedAccessException('no token');
    }

    var token = authHeader.split(' ').last;

    if (googleapisProxy != null && googleapisClient == null) {
      googleapisClient = HttpClient()
        ..findProxy = (url) {
          return HttpClient.findProxyFromEnvironment(url, environment: {
            'http_proxy': googleapisProxy,
            'https_proxy': googleapisProxy,
          });
        };
    }

    return Oauth2Api(googleapisClient ?? _httpClient)
        .tokeninfo(accessToken: token);
  }

  @override
  Future<PackageVersion> upload(Stream<List<int>> data, {request}) async {
    Tokeninfo info;
    if (shouldCheckUploader) {
      info = await _getOperatorTokenInfo(request);
      var isValidUser = await uploaderValidator(info);
      if (!isValidUser) {
        throw 'Uploader invalid: ${info.toJson()}';
      }
    }

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

    var name = pubspec['name'] as String;
    var isNameValid = await packageValidator(name);
    if (!isNameValid) {
      throw 'Package name invalid: $name';
    }

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

    if (shouldCheckUploader) {
      var packageEmpty = await metaStore.getAllVersions(name).isEmpty;
      if (!packageEmpty) {
        var uploaders = await metaStore.getUploaders(name).toList();
        if (!uploaders.contains(info.email)) {
          throw UnauthorizedAccessException(
              '${info.email} is not an uploader of $name package');
        }
      }
    }

    var pubspecContent = utf8.decode(pubspecArchiveFile.content);

    // Upload package tar to storage
    await packageStore.upload(name, version, tarballBytes);

    // Write package meta to database
    await metaStore.addVersion(name, UnpubVersion.fromPubspec(pubspecContent),
        info == null ? null : UnpubUploader(email: info.email));

    // TODO: Upload docs

    return PackageVersion(name, version, pubspecContent);
  }

  @override
  Future<Stream<List<int>>> download(String package, String version) async {
    throw 'Should redirect to tos';
  }

  @override
  bool get supportsDownloadUrl => true;

  @override
  Future<Uri> downloadUrl(String package, String version) async {
    var item = await metaStore.getVersion(package, version);
    if (item == null) {
      return proxy.downloadUrl(package, version);
    }
    return packageStore.downloadUri(package, version);
  }

  bool get supportsUploaders => false;

  Future addUploader(String package, String userEmail, {request}) async {
    var info = await _getOperatorTokenInfo(request);

    var uploaders = await metaStore.getUploaders(package).toList();
    if (!uploaders.contains(info.email)) {
      throw UnauthorizedAccessException(
          '${info.email} is not an uploader of $package package');
    }

    if (userEmail == info.email) {
      throw StateError('cannot add self');
    }

    await metaStore.addUploader(package, UnpubUploader(email: userEmail));
  }

  Future removeUploader(String package, String userEmail, {request}) async {
    var info = await _getOperatorTokenInfo(request);

    var uploaders = await metaStore.getUploaders(package).toList();
    if (!uploaders.contains(info.email)) {
      throw UnauthorizedAccessException(
          '${info.email} is not an uploader of $package package');
    }

    if (userEmail == info.email) {
      throw StateError('cannot remove self');
    }

    if (uploaders.length <= 1) {
      throw StateError('at least one uploader');
    }

    await metaStore.removeUploader(package, UnpubUploader(email: userEmail));
  }
}

List<int> _getBytes(ArchiveFile file) => file.content as List<int>;
