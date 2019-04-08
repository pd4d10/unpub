import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:unpub/unpub.dart';
import 'package:unpub/unpub_file.dart';

Map readMeta(String package) {
  return json.decode(File(path.absolute('unpub-data', package, 'meta.json'))
      .readAsStringSync());
}

String readPubspec(String package, String version) {
  return File(path.absolute('test/fixtures', package, version, 'pubspec.yaml'))
      .readAsStringSync();
}

ProcessResult pubPublish(String package, String version) {
  return Process.runSync('pub', ['publish', '--force'],
      workingDirectory: path.absolute('test/fixtures', package, version),
      environment: {'PUB_HOSTED_URL': 'http://localhost:3000'});
}

final baseDir = path.absolute('unpub-data');
final notExistingPacakge = 'not_existing_package';

cleanUp() {
  var dir = Directory(baseDir);
  if (dir.existsSync()) {
    dir.deleteSync(recursive: true);
  }
}

startServer() async {
  var repository = UnpubRepository(
    metaStore: UnpubFileMetaStore(baseDir),
    packageStore: UnpubFilePackageStore(baseDir),
    shouldCheckUploader: false,
  );
  var server = UnpubServer(repository);
  await server.serve('localhost', 3000);
}

final baseUri = Uri.parse('http://localhost:3000');

Future<http.Response> getVersions(String package) {
  package = Uri.encodeComponent(package);
  return http.get(baseUri.resolve('/api/packages/$package'));
}

Future<http.Response> getSpecificVersion(String package, String version) {
  package = Uri.encodeComponent(package);
  version = Uri.encodeComponent(version);
  return http.get(baseUri.resolve('/api/packages/$package/versions/$version'));
}

main() async {
  setUp(() async {
    // await startServer();
  });

  group('publish', () {
    cleanUp();

    test('fresh', () {
      var package = 'package_0';
      var version = '0.0.1';

      var result = pubPublish(package, version);
      expect(result.stderr, '');

      var meta = readMeta(package);
      expect(meta['name'], package);
      expect(meta['versions'][0]['version'], version);
      expect(meta['versions'][0]['pubspec'], readPubspec(package, version));
    });

    test('existing package', () {
      var package = 'package_0';
      var version = '0.0.3';

      var result = pubPublish(package, version);
      expect(result.stderr, '');

      var meta = readMeta(package);

      expect(meta['name'], package);
      expect(meta['versions'][0]['version'], '0.0.1');
      expect(meta['versions'][0]['pubspec'], readPubspec(package, '0.0.1'));
      expect(meta['versions'][1]['version'], version);
      expect(meta['versions'][1]['pubspec'], readPubspec(package, version));
    });

    test('duplicated version', () {
      var package = 'package_0';
      var version = '0.0.2';

      var result = pubPublish(package, version);
      expect(result.stderr, contains('version invalid'));
    });
  });

  group('get versions', () {
    test('existing at local', () async {
      var package = 'package_0';
      var res = await getVersions(package);
      expect(res.statusCode, HttpStatus.ok);

      var body = json.decode(res.body);
      expect(body['name'], package);
      expect(body['latest']['version'], '0.0.3');
      expect(body['versions'][0]['version'], '0.0.1');
      expect(body['versions'][1]['version'], '0.0.3');
    });

    test('existing at remote', () async {
      var package = 'http';
      var res = await getVersions(package);
      expect(res.statusCode, HttpStatus.ok);

      var body = json.decode(res.body);
      expect(body['name'], package);
    });

    test('not existing', () async {
      var res = await getVersions(notExistingPacakge);
      expect(res.statusCode, HttpStatus.notFound);
    });
  });

  group('get specific version', () {
    test('existing at local', () async {
      var res = await getSpecificVersion('package_0', '0.0.1');
      expect(res.statusCode, HttpStatus.ok);

      var body = json.decode(res.body);
      expect(body['version'], '0.0.1');
    });

    test('not existing version at local', () async {
      var res = await getSpecificVersion('package_0', '0.0.2');
      expect(res.statusCode, HttpStatus.notFound);
    });

    test('existing at remote', () async {
      var res = await getSpecificVersion('http', '0.12.0+2');
      expect(res.statusCode, HttpStatus.ok);

      var body = json.decode(res.body);
      expect(body['version'], '0.12.0+2');
    });

    test('not existing', () async {
      var res = await getSpecificVersion(notExistingPacakge, '0.0.1');
      expect(res.statusCode, HttpStatus.notFound);
    });
  });
}
