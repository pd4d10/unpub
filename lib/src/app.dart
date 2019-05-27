import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:http/http.dart' as http;
import 'package:shelf_router/shelf_router.dart';
import 'package:unpub/src/meta_store.dart';
import 'package:unpub/src/package_store.dart';

class UnpubApp {
  static var _httpClient = http.Client();

  var app = Router();
  UnpubMetaStore metaStore;
  UnpubPackageStore packageStore;
  String proxyUrl;

  UnpubApp({
    this.metaStore,
    this.packageStore,
    this.proxyUrl = 'https://pub.dev',
  });

  void init() {
    app.get('/api/packages/<name>', (Request request, String name) async {
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
        'versions': versions.map((item) {
          var version = item.version;

          return {
            'archive_url': request.requestedUri
                .resolve('/packages/$name/versions/$version.tar.gz'),
            'pubspec': item.pubspec,
            'version': version,
          };
        }),
      });
    });

    app.get('/api/packages/<name>/versions/<version>',
        (Request request, String name, String version) async {
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
      return Response.ok({
        'archive_url': request.requestedUri
            .resolve('/packages/$name/versions/$version.tar.gz'),
        'pubspec': item.pubspec,
        'version': version,
      });
    });
  }
}
