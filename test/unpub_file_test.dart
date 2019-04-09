import 'dart:io';
import 'dart:convert';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;
import 'utils.dart';
import 'package:unpub/unpub.dart';
import 'package:unpub/unpub_file.dart';

final baseDir = path.absolute('unpub-data');

main() {
  Future<Map> readMeta(String package) async {
    return json.decode(File(path.absolute('unpub-data', package, 'meta.json'))
        .readAsStringSync());
  }

  setUpAll(() {
    var dir = Directory(baseDir);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  group('file', () {
    group('publish', () {
      test('fresh', () async {
        var package = 'package_0';
        var version = '0.0.1';

        var result = pubPublish(package, version);
        expect(result.stderr, '');

        var meta = await readMeta(package);
        expect(meta['name'], package);
        expect(meta['versions'][0]['version'], version);
        expect(meta['versions'][0]['pubspec'], readPubspec(package, version));
      });

      test('existing package', () async {
        var package = 'package_0';
        var version = '0.0.3';

        var result = pubPublish(package, version);
        expect(result.stderr, '');

        var meta = await readMeta(package);

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
  });
}
