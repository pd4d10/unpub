import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis/oauth2/v2.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:pub_semver/pub_semver.dart' as semver;
import 'package:pub_server/repository.dart';
import 'package:yaml/yaml.dart';
import 'package:archive/archive.dart';
import 'package:unpub/src/meta_store.dart';
import 'package:unpub/src/package_store.dart';

List<int> _getBytes(ArchiveFile file) => file.content as List<int>;

class UnpubApp {
  static var _httpClient = http.Client();

  var app = Router();
  UnpubMetaStore metaStore;
  UnpubPackageStore packageStore;
  String proxyUrl;
  Future<String> Function(String token) uploaderEmailGetter;
  Future<void> Function(dynamic pubspecJson, String email) uploadValidator;

  static Future<String> defaultUploaderEmailGetter(String token) async {
    var info = await Oauth2Api(_httpClient).tokeninfo(accessToken: token);
    if (info == null) return null;
    return info.email;
  }

  static Future<void> defaultUploadValidator(_, __) async {}

  UnpubApp({
    this.metaStore,
    this.packageStore,
    this.proxyUrl = 'https://pub.dev',
    this.uploaderEmailGetter = defaultUploaderEmailGetter,
    this.uploadValidator = defaultUploadValidator,
  });

  Future<String> _getUploaderEmail(Request req) async {
    var authHeader = req.headers[HttpHeaders.authorizationHeader];
    if (authHeader == null) {
      throw 'No auth';
    }

    var token = authHeader.split(' ').last;
    var email = await uploaderEmailGetter(token);
    return email;
  }

  Map<String, dynamic> _versionToJson(UnpubVersion item, Uri baseUri) {
    var name = item.pubspec['name'] as String;
    var version = item.version;
    return {
      'archive_url':
          baseUri.resolve('/packages/$name/versions/$version.tar.gz'),
      'pubspec': item.pubspec,
      'version': version,
    };
  }

  void init() {
    app.get('/api/packages/<name>', (Request req, String name) async {
      var versions = await metaStore.getAllVersions(name).toList();

      if (versions.isEmpty) {
        name = Uri.encodeComponent(name);
        var res = await _httpClient.send(http.Request(
            'GET', Uri.parse(proxyUrl).resolve('/api/packages/$name')));
        return Response.ok(res.stream);
      }

      metaStore.increaseQueryCount(name);

      return Response.ok({
        'name': name,
        'latest': {}, // TODO:
        'versions':
            versions.map((item) => _versionToJson(item, req.requestedUri)),
      });
    });

    app.get('/api/packages/<name>/versions/<version>',
        (Request req, String name, String version) async {
      var item = await metaStore.getVersion(name, version);

      if (item == null) {
        name = Uri.encodeComponent(name);
        version = Uri.encodeComponent(version);
        var res = await _httpClient.send(http.Request(
            'GET',
            Uri.parse(proxyUrl)
                .resolve('/api/packages/$name/versions/$version')));
        return Response.ok(res.stream);
      }

      metaStore.increaseQueryCount(name);
      return Response.ok(_versionToJson(item, req.requestedUri));
    });

    app.get('/api/packages/versions/new', (Request req) {
      return Response.ok({
        'url': req.requestedUri.resolve('/api/packages/versions/newUpload'),
        'fields': {},
      });
    });

    app.post('/api/packages/versions/newUpload', (Request req) async {
      try {
        var email = await _getUploaderEmail(req);

        var mediaType = MediaType.parse(req.headers['content-type']);

        var boundary = mediaType.parameters['boundary'];
        MimeMultipart fileData;

        await for (MimeMultipart part
            in req.read().transform(MimeMultipartTransformer(boundary))) {
          if (fileData != null) continue;
          fileData = part;
        }

        var bb = await fileData.fold(BytesBuilder(),
            (BytesBuilder byteBuilder, d) => byteBuilder..add(d));
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

        var newerOrEqualVersion =
            await metaStore.getAllVersions(name).firstWhere(
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
            throw 'UnauthorizedAccess';
          }
        }

        var pubspecContent = utf8.decode(pubspecArchiveFile.content);

        // Upload package tar to storage
        await packageStore.upload(name, version, tarballBytes);

        // Write package meta to database
        await metaStore.addVersion(
            name, UnpubVersion.fromPubspec(pubspecContent), email);

        // TODO: Upload docs

        return Response.found(
            req.requestedUri.resolve('/api/packages/versions/newUploadFinish'));
      } catch (err) {
        return Response.found(req.requestedUri
            .resolve('/api/packages/versions/newUploadFinish?error=$err'));
      }
    });

    app.get('/api/packages/versions/newUploadFinish', (Request req) {
      var error = req.requestedUri.queryParameters['error'];
      if (error != null) {
        return _badRequest(error);
      }
      return _jsonResponse({
        'success': {'message': 'Successfully uploaded package.'}
      });
    });
  }

  Response _jsonResponse(Map<String, dynamic> data, {int status = 200}) =>
      Response(status,
          body: json.encode(data),
          headers: {'content-type': 'application/json'});

  Response _badRequest(String message) => Response(400,
      body: json.encode({
        'error': {'message': message}
      }),
      headers: {'content-type': 'application/json'});
}
