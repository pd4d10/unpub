import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:http/http.dart' as http;
import 'package:googleapis/oauth2/v2.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:pub_semver/pub_semver.dart' as semver;
import 'package:yaml/yaml.dart';
import 'package:archive/archive.dart';
import 'package:unpub/src/meta_store.dart';
import 'package:unpub/src/package_store.dart';

part 'app.g.dart';

Response _ok(Map<String, dynamic> data, {int status = 200}) => Response(status,
    body: json.encode(data),
    headers: {HttpHeaders.contentTypeHeader: 'application/json'});

Response _successMessage(String message, {int status = 200}) => _ok({
      'success': {'message': message}
    }, status: status);

Response _badRequest(String message, {int status = 400}) => Response(status,
    body: json.encode({
      'error': {'message': message}
    }),
    headers: {HttpHeaders.contentTypeHeader: 'application/json'});

class UnpubApp {
  static var _httpClient = http.Client();

  final UnpubMetaStore metaStore;
  final UnpubPackageStore packageStore;
  final String proxyUrl;
  final Future<String> Function(String token) uploaderEmailGetter;
  final Future<void> Function(dynamic pubspecJson, String email)
      uploadValidator;

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

  Future<HttpServer> serve([String host = '0.0.0.0', int port = 4000]) async {
    var handler =
        const Pipeline().addMiddleware(logRequests()).addHandler((req) async {
      // Return 404 by default
      // https://github.com/google/dart-neats/issues/1
      var res = await router.handler(req);
      if (res == null) {
        return Response.notFound('Not found');
      } else {
        return res;
      }
    });
    var server = await shelf_io.serve(handler, host, port);
    return server;
  }

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
      'archive_url': baseUri
          .resolve('/packages/$name/versions/$version.tar.gz')
          .toString(),
      'pubspec': item.pubspec,
      'version': version,
    };
  }

  Router get router => _$UnpubAppRouter(this);

  @Route.get('/api/packages/<name>')
  Future<Response> getVersions(Request req, String name) async {
    var versions = await metaStore.getAllVersions(name).toList();

    if (versions.isEmpty) {
      var res = await _httpClient.send(http.Request(
          'GET', Uri.parse(proxyUrl).resolve('/api/packages/$name')));
      return Response(res.statusCode,
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: res.stream);
    }

    metaStore.increaseQueryCount(name);

    versions.sort((a, b) {
      return semver.Version.prioritize(
          semver.Version.parse(a.version), semver.Version.parse(b.version));
    });

    var versionMaps =
        versions.map((item) => _versionToJson(item, req.requestedUri)).toList();

    return _ok({
      'name': name,
      'latest': versionMaps.last,
      'versions': versionMaps,
    });
  }

  @Route.get('/api/packages/<name>/versions/<version>')
  Future<Response> getVersion(Request req, String name, String version) async {
    var item = await metaStore.getVersion(name, version);

    if (item == null) {
      var res = await _httpClient.send(http.Request(
          'GET',
          Uri.parse(proxyUrl)
              .resolve('/api/packages/$name/versions/$version')));
      return Response(res.statusCode,
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: res.stream);
    }

    metaStore.increaseQueryCount(name);
    return _ok(_versionToJson(item, req.requestedUri));
  }

  @Route.get('/packages/<name>/versions/<version>.tar.gz')
  Future<Response> download(Request req, String name, String version) async {
    var item = await metaStore.getVersion(name, version);

    Stream<List<int>> stream;

    if (item == null) {
      var res = await _httpClient.send(http.Request(
          'GET',
          Uri.parse(proxyUrl)
              .resolve('/packages/$name/versions/$version.tar.gz')));
      stream = res.stream;
    } else {
      metaStore.increaseDownloadCount(name);
      stream = packageStore.download(name, version);
    }

    return Response(200, body: stream);
  }

  @Route.get('/api/packages/versions/new')
  Future<Response> getUploadUrl(Request req) async {
    return _ok({
      'url': req.requestedUri
          .resolve('/api/packages/versions/newUpload')
          .toString(),
      'fields': {},
    });
  }

  @Route.post('/api/packages/versions/newUpload')
  Future<Response> upload(Request req) async {
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

      var bb = await fileData.fold(
          BytesBuilder(), (BytesBuilder byteBuilder, d) => byteBuilder..add(d));
      var tarballBytes = bb.takeBytes();
      var tarBytes = GZipDecoder().decodeBytes(tarballBytes);
      var archive = TarDecoder().decodeBytes(tarBytes);
      ArchiveFile pubspecArchiveFile;
      ArchiveFile readmeFile;
      ArchiveFile changelogFile;

      for (var file in archive.files) {
        if (file.name == 'pubspec.yaml') {
          pubspecArchiveFile = file;
          continue;
        }
        if (file.name.toLowerCase() == 'readme.md') {
          readmeFile = file;
          continue;
        }
        if (file.name.toLowerCase() == 'changelog.md') {
          changelogFile = file;
          continue;
        }
      }

      if (pubspecArchiveFile == null) {
        throw 'Did not find any pubspec.yaml file in upload. Aborting.';
      }

      var pubspecYaml = utf8.decode(pubspecArchiveFile.content);
      // TODO: Error handling.
      var pubspec = loadYaml(pubspecYaml);

      // Validator
      await uploadValidator(pubspec, email);

      var name = pubspec['name'] as String;
      var version = pubspec['version'] as String;

      var duplicatedVersion = await metaStore.getAllVersions(name).firstWhere(
            (item) => version == item.version,
            orElse: () => null,
          );

      if (duplicatedVersion != null) {
        throw 'version invalid: $name@$version already exists.';
      }

      var packageEmpty = await metaStore.getAllVersions(name).isEmpty;
      if (!packageEmpty) {
        var uploaders = await metaStore.getUploaders(name).toList();
        if (!uploaders.contains(email)) {
          throw 'UnauthorizedAccess';
        }
      }

      // Upload package tar to storage
      await packageStore.upload(name, version, tarballBytes);

      String readme;
      String changelog;
      if (readmeFile != null) {
        readme = utf8.decode(readmeFile.content);
      }
      if (changelogFile != null) {
        changelog = utf8.decode(changelogFile.content);
      }
      // Write package meta to database
      await metaStore.addVersion(name,
          UnpubVersion.fromPubspec(pubspecYaml, readme, changelog), email);

      // TODO: Upload docs
      return Response.found(req.requestedUri
          .resolve('/api/packages/versions/newUploadFinish')
          .toString());
    } catch (err) {
      return Response.found(req.requestedUri
          .resolve('/api/packages/versions/newUploadFinish?error=$err'));
    }
  }

  @Route.get('/api/packages/versions/newUploadFinish')
  Future<Response> uploadFinish(Request req) async {
    var error = req.requestedUri.queryParameters['error'];
    if (error != null) {
      return _badRequest(error);
    }
    return _successMessage('Successfully uploaded package.');
  }

  @Route.post('/api/packages/<name>/uploaders')
  Future<Response> addUploader(Request req, String name) async {
    var body = await req.readAsString();
    var email = Uri.splitQueryString(body)['email'];
    var operatorEmail = await _getUploaderEmail(req);
    var uploaders = await metaStore.getUploaders(name).toList();

    if (!uploaders.contains(operatorEmail)) {
      return _badRequest('no permission', status: 403);
    }
    if (uploaders.contains(email)) {
      return _badRequest('email already exists');
    }

    await metaStore.addUploader(name, email);
    return _successMessage('uploader added');
  }

  @Route.delete('/api/packages/<name>/uploaders/<email>')
  Future<Response> removeUploader(
      Request req, String name, String email) async {
    email = Uri.decodeComponent(email);
    var operatorEmail = await _getUploaderEmail(req);
    var uploaders = await metaStore.getUploaders(name).toList();

    if (!uploaders.contains(operatorEmail)) {
      return _badRequest('no permission', status: 403);
    }
    if (!uploaders.contains(email)) {
      return _badRequest('email not uploader');
    }

    await metaStore.removeUploader(name, email);
    return _successMessage('uploader removed');
  }
}
