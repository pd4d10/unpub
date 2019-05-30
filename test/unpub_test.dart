import 'dart:io';
import 'dart:convert';
import 'package:unpub/unpub.dart';
import 'package:unpub/unpub_file.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;
import 'package:mongo_dart/mongo_dart.dart';
import 'utils.dart';
import 'package:unpub/unpub_mongo.dart';

final baseDir = path.absolute('unpub-data');

final package0 = 'package_0';
final email0 = 'email0@example.com';
final email1 = 'email1@example.com';
final email2 = 'email2@example.com';

main() {
  Db _db;

  Future<Map<String, dynamic>> readMeta(String name) async {
    return _db.collection(packageCollection).findOne(where.eq('name', name));
  }

  setUpAll(() async {
    _db = Db('mongodb://localhost:27017/dart_pub_test');
    await _db.open();
    await _db.dropCollection(packageCollection);
    await _db.dropCollection(statsCollection);
  });

  tearDownAll(() async {
    await _db.close();
  });

  group('publish', () {
    test('fresh', () async {
      var name = 'package_0';
      var version = '0.0.1';

      var result = pubPublish(name, version);
      expect(result.stderr, '');

      var meta = await readMeta(name);
      expect(meta['name'], name);
      expect(meta['versions'][0]['version'], version);
      expect(meta['versions'][0]['pubspecYaml'], readPubspec(name, version));
    });

    test('existing package', () async {
      var name = 'package_0';
      var version = '0.0.3';

      var result = pubPublish(name, version);
      expect(result.stderr, '');

      var meta = await readMeta(name);

      expect(meta['name'], name);
      expect(meta['versions'][0]['version'], '0.0.1');
      expect(meta['versions'][0]['pubspecYaml'], readPubspec(name, '0.0.1'));
      expect(meta['versions'][1]['version'], version);
      expect(meta['versions'][1]['pubspecYaml'], readPubspec(name, version));
    });

    test('invalid version', () {
      var name = 'package_0';
      var version = '0.0.2';

      var result = pubPublish(name, version);
      expect(result.stderr, contains('version invalid'));
    });

    test('invalid version', () {
      var name = 'package_0';
      var version = '0.0.3';

      var result = pubPublish(name, version);
      expect(result.stderr, contains('version invalid'));
    });

    test('version number', () async {
      var name = 'package_0';
      var version = '0.0.3+1';

      var result = pubPublish(name, version);
      expect(result.stderr, '');

      var meta = await readMeta(name);

      expect(meta['name'], name);
      expect(meta['versions'][0]['version'], '0.0.1');
      expect(meta['versions'][0]['pubspecYaml'], readPubspec(name, '0.0.1'));
      expect(meta['versions'][1]['version'], '0.0.3');
      expect(meta['versions'][1]['pubspecYaml'], readPubspec(name, '0.0.3'));
      expect(meta['versions'][2]['version'], version);
      expect(meta['versions'][2]['pubspecYaml'], readPubspec(name, version));
    });
  });

  group('get versions', () {
    test('existing at local', () async {
      var name = 'package_0';
      var res = await getVersions(name);
      expect(res.statusCode, HttpStatus.ok);

      var body = json.decode(res.body);
      expect(body['name'], name);
      expect(body['latest']['version'], '0.0.3+1');
      expect(body['versions'][0]['version'], '0.0.1');
      expect(body['versions'][1]['version'], '0.0.3');
      expect(body['versions'][2]['version'], '0.0.3+1');
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

  group('add uploader', () {
    test('already exists', () async {
      var result = pubUploader(package0, 'add', email0);
      expect(result.stderr, contains('email already exists'));

      var meta = await readMeta(package0);
      expect(meta['uploaders'], unorderedEquals([email0]));
    });

    test('success', () async {
      var result = pubUploader(package0, 'add', email1);
      expect(result.stderr, '');

      var meta = await readMeta(package0);
      expect(meta['uploaders'], unorderedEquals([email0, email1]));
    });
  });

  group('remove uploader', () {
    test('not in uploader', () async {
      var result = pubUploader(package0, 'remove', email2);
      expect(result.stderr, contains('email not uploader'));

      var meta = await readMeta(package0);
      expect(meta['uploaders'], unorderedEquals([email0, email1]));
    });

    test('success', () async {
      var result = pubUploader(package0, 'remove', email1);
      expect(result.stderr, '');

      var meta = await readMeta(package0);
      expect(meta['uploaders'], unorderedEquals([email0]));
    });
  });
}
