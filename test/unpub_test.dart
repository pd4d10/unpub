import 'dart:io';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:unpub/src/utils.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;
import 'package:mongo_dart/mongo_dart.dart';
import 'utils.dart';
import 'package:unpub/unpub_mongo.dart';

main() {
  Db _db = Db('mongodb://localhost:27017/dart_pub_test');
  HttpServer _server;

  setUpAll(() async {
    await _db.open();
  });

  Future<Map<String, dynamic>> _readMeta(String name) async {
    var res =
        await _db.collection(packageCollection).findOne(where.eq('name', name));
    res.remove('_id');
    return res;
  }

  Map<String, String> _pubspecCache = {};

  Future<String> _readFile(
      String package, String version, String filename) async {
    var key = package + version + filename;
    if (_pubspecCache[key] == null) {
      var filePath = path.absolute('test/fixtures', package, version, filename);
      _pubspecCache[key] = await File(filePath).readAsString();
    }
    return _pubspecCache[key];
  }

  // Future<Map<String, dynamic>> _readPubSpec(
  //     String package, String version) async {
  //   var content = await _readFile(package, version, 'pubspec.yaml');
  //   return loadYamlAsMap(content);
  // }

  _cleanUpDb() async {
    await _db.dropCollection(packageCollection);
    await _db.dropCollection(statsCollection);
  }

  tearDownAll(() async {
    await _db.close();
  });

  group('publish', () {
    setUpAll(() async {
      await _cleanUpDb();
      _server = await createServer(email0);
    });

    tearDownAll(() async {
      await _server.close();
    });

    test('fresh', () async {
      var version = '0.0.1';

      var result = await pubPublish(package0, version);
      expect(result.stderr, '');

      var meta = await _readMeta(package0);
      (meta['versions'] as List).forEach((version) {
        version.remove('createAt');
      });

      expect(
        DeepCollectionEquality().equals(
          meta,
          {
            'name': package0,
            'uploaders': [email0],
            'versions': [
              {
                'version': version,
                'pubspecYaml':
                    await _readFile(package0, version, 'pubspec.yaml'),
                'pubspec': loadYamlAsMap(
                    await _readFile(package0, version, 'pubspec.yaml')),
                'readme': await _readFile(package0, version, 'README.md'),
                'changelog': await _readFile(package0, version, 'CHANGELOG.md')
              }
            ]
          },
        ),
        true,
      );
    });

    test('existing package', () async {
      var version = '0.0.3';

      var result = await pubPublish(package0, version);
      expect(result.stderr, '');

      var meta = await _readMeta(package0);
      (meta['versions'] as List).forEach((version) {
        version.remove('createAt');
      });

      expect(
        DeepCollectionEquality().equals(
          meta,
          {
            'name': package0,
            'uploaders': [email0],
            'versions': [
              {
                'version': '0.0.1',
                'pubspecYaml':
                    await _readFile(package0, '0.0.1', 'pubspec.yaml'),
                'pubspec': loadYamlAsMap(
                    await _readFile(package0, '0.0.1', 'pubspec.yaml')),
                'readme': await _readFile(package0, '0.0.1', 'README.md'),
                'changelog': await _readFile(package0, '0.0.1', 'CHANGELOG.md')
              },
              {
                'version': version,
                'pubspecYaml':
                    await _readFile(package0, version, 'pubspec.yaml'),
                'pubspec': loadYamlAsMap(
                    await _readFile(package0, version, 'pubspec.yaml')),
                'readme': await _readFile(package0, version, 'README.md'),
                'changelog': await _readFile(package0, version, 'CHANGELOG.md')
              }
            ]
          },
        ),
        true,
      );
    });

    test('invalid version', () async {
      var result = await pubPublish(package0, '0.0.2');
      expect(result.stderr, contains('version invalid'));
    });

    test('invalid version', () async {
      var result = await pubPublish(package0, '0.0.3');
      expect(result.stderr, contains('version invalid'));
    });

    test('hotfix version number', () async {
      var version = '0.0.3+1';

      var result = await pubPublish(package0, version);
      expect(result.stderr, '');

      var meta = await _readMeta(package0);
      (meta['versions'] as List).forEach((v) {
        v.remove('createAt');
      });

      expect(
        DeepCollectionEquality().equals(
          meta,
          {
            'name': package0,
            'uploaders': [email0],
            'versions': [
              {
                'version': '0.0.1',
                'pubspecYaml':
                    await _readFile(package0, '0.0.1', 'pubspec.yaml'),
                'pubspec': loadYamlAsMap(
                    await _readFile(package0, '0.0.1', 'pubspec.yaml')),
                'readme': await _readFile(package0, '0.0.1', 'README.md'),
                'changelog': await _readFile(package0, '0.0.1', 'CHANGELOG.md')
              },
              {
                'version': '0.0.3',
                'pubspecYaml':
                    await _readFile(package0, '0.0.3', 'pubspec.yaml'),
                'pubspec': loadYamlAsMap(
                    await _readFile(package0, '0.0.3', 'pubspec.yaml')),
                'readme': await _readFile(package0, '0.0.3', 'README.md'),
                'changelog': await _readFile(package0, '0.0.3', 'CHANGELOG.md')
              },
              {
                'version': version,
                'pubspecYaml':
                    await _readFile(package0, version, 'pubspec.yaml'),
                'pubspec': loadYamlAsMap(
                    await _readFile(package0, version, 'pubspec.yaml')),
                'readme': await _readFile(package0, version, 'README.md'),
                'changelog': await _readFile(package0, version, 'CHANGELOG.md')
              }
            ]
          },
        ),
        true,
      );
    });

    group('edge case', () {
      test('no readme and changelog', () async {
        var version = '1.0.0-noreadme';
        var result = await pubPublish(package0, version);
        // expect(result.stderr, ''); // Suggestions:

        var meta = await _readMeta(package0);
        (meta['versions'] as List).forEach((version) {
          version.remove('createAt');
        });
        var item = (meta['versions'] as List)
            .firstWhere((v) => v['version'] == version, orElse: () => null);

        expect(
          DeepCollectionEquality().equals(item, {
            'version': version,
            'pubspecYaml': await _readFile(package0, version, 'pubspec.yaml'),
            'pubspec': loadYamlAsMap(
                await _readFile(package0, version, 'pubspec.yaml')),
            'readme': null,
            'changelog': null
          }),
          true,
        );
      });
    });
  });

  group('get versions', () {
    setUpAll(() async {
      await _cleanUpDb();
      _server = await createServer(email0);
      await pubPublish(package0, '0.0.1');
      await pubPublish(package0, '0.0.2');
    });

    tearDownAll(() async {
      await _server.close();
    });

    test('existing at local', () async {
      var res = await getVersions(package0);
      expect(res.statusCode, HttpStatus.ok);

      var body = json.decode(res.body);
      expect(
        DeepCollectionEquality().equals(body, {
          "name": "package_0",
          "latest": {
            "archive_url":
                "http://localhost:4000/packages/package_0/versions/0.0.2.tar.gz",
            "pubspec": loadYamlAsMap(
                await _readFile('package_0', '0.0.2', 'pubspec.yaml')),
            "version": "0.0.2"
          },
          "versions": [
            {
              "archive_url":
                  "http://localhost:4000/packages/package_0/versions/0.0.1.tar.gz",
              "pubspec": loadYamlAsMap(
                  await _readFile('package_0', '0.0.1', 'pubspec.yaml')),
              "version": "0.0.1"
            },
            {
              "archive_url":
                  "http://localhost:4000/packages/package_0/versions/0.0.2.tar.gz",
              "pubspec": loadYamlAsMap(
                  await _readFile('package_0', '0.0.2', 'pubspec.yaml')),
              "version": "0.0.2"
            }
          ]
        }),
        true,
      );
    });

    test('existing at remote', () async {
      var name = 'http';
      var res = await getVersions(name);
      expect(res.statusCode, HttpStatus.ok);

      var body = json.decode(res.body);
      expect(body['name'], name);
    });

    test('not existing', () async {
      var res = await getVersions(notExistingPacakge);
      expect(res.statusCode, HttpStatus.notFound);
    });
  });

  group('get specific version', () {
    setUpAll(() async {
      await _cleanUpDb();
      _server = await createServer(email0);
      await pubPublish(package0, '0.0.1');
      await pubPublish(package0, '0.0.3');
    });

    tearDownAll(() async {
      await _server.close();
    });

    test('existing at local', () async {
      var res = await getSpecificVersion(package0, '0.0.1');
      expect(res.statusCode, HttpStatus.ok);

      var body = json.decode(res.body);
      expect(
        DeepCollectionEquality().equals(body, {
          "archive_url":
              "http://localhost:4000/packages/package_0/versions/0.0.1.tar.gz",
          "pubspec": loadYamlAsMap(
              await _readFile('package_0', '0.0.1', 'pubspec.yaml')),
          "version": '0.0.1'
        }),
        true,
      );
    });

    test('not existing version at local', () async {
      var res = await getSpecificVersion(package0, '0.0.2');
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

  group('uploader', () {
    setUpAll(() async {
      await _cleanUpDb();
      _server = await createServer(email0);
      await pubPublish(package0, '0.0.1');
    });

    tearDownAll(() async {
      await _server.close();
    });

    group('add', () {
      test('already exists', () async {
        var result = await pubUploader(package0, 'add', email0);
        expect(result.stderr, contains('email already exists'));

        var meta = await _readMeta(package0);
        expect(meta['uploaders'], unorderedEquals([email0]));
      });

      test('success', () async {
        var result = await pubUploader(package0, 'add', email1);
        expect(result.stderr, '');

        var meta = await _readMeta(package0);
        expect(meta['uploaders'], unorderedEquals([email0, email1]));

        result = await pubUploader(package0, 'add', email2);
        expect(result.stderr, '');

        meta = await _readMeta(package0);
        expect(meta['uploaders'], unorderedEquals([email0, email1, email2]));
      });
    });

    group('remove', () {
      test('not in uploader', () async {
        var result = await pubUploader(package0, 'remove', email3);
        expect(result.stderr, contains('email not uploader'));

        var meta = await _readMeta(package0);
        expect(meta['uploaders'], unorderedEquals([email0, email1, email2]));
      });

      test('success', () async {
        var result = await pubUploader(package0, 'remove', email2);
        expect(result.stderr, '');

        var meta = await _readMeta(package0);
        expect(meta['uploaders'], unorderedEquals([email0, email1]));

        result = await pubUploader(package0, 'remove', email1);
        expect(result.stderr, '');

        meta = await _readMeta(package0);
        expect(meta['uploaders'], unorderedEquals([email0]));
      });
    });

    group('permission', () {
      setUpAll(() async {
        await _server.close();
        _server = await createServer(email1);
      });

      tearDownAll(() async {
        await _server.close();
      });

      test('add', () async {
        var result = await pubUploader(package0, 'add', email0);
        expect(result.stderr, contains('no permission'));
      });

      test('remove', () async {
        var result = await pubUploader(package0, 'remove', email0);
        expect(result.stderr, contains('no permission'));
      });
    });
  });
}
