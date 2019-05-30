import 'dart:io';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;
import 'package:mongo_dart/mongo_dart.dart';
import 'utils.dart';
import 'package:unpub/unpub_mongo.dart';

main() {
  Db _db;

  Future<Map<String, dynamic>> readMeta(String name) async {
    return _db.collection(packageCollection).findOne(where.eq('name', name));
  }

  setUpAll(() async {
    await startServer();

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
      var version = '0.0.1';

      var result = await pubPublish(package0, version);
      expect(result.stderr, '');

      var meta = await readMeta(package0);
      expect(meta['name'], package0);
      expect(meta['versions'][0]['version'], version);
      expect(
          meta['versions'][0]['pubspecYaml'], readPubspec(package0, version));
    });

    test('existing package', () async {
      var version = '0.0.3';

      var result = await pubPublish(package0, version);
      expect(result.stderr, '');

      var meta = await readMeta(package0);

      expect(meta['name'], package0);
      expect(meta['versions'][0]['version'], '0.0.1');
      expect(
          meta['versions'][0]['pubspecYaml'], readPubspec(package0, '0.0.1'));
      expect(meta['versions'][1]['version'], version);
      expect(
          meta['versions'][1]['pubspecYaml'], readPubspec(package0, version));
    });

    test('invalid version', () async {
      var version = '0.0.2';

      var result = await pubPublish(package0, version);
      expect(result.stderr, contains('version invalid'));
    });

    test('invalid version', () async {
      var version = '0.0.3';
      var result = await pubPublish(package0, version);
      expect(result.stderr, contains('version invalid'));
    });

    test('version number', () async {
      var version = '0.0.3+1';

      var result = await pubPublish(package0, version);
      expect(result.stderr, '');

      var meta = await readMeta(package0);

      expect(meta['name'], package0);
      expect(meta['versions'][0]['version'], '0.0.1');
      expect(
          meta['versions'][0]['pubspecYaml'], readPubspec(package0, '0.0.1'));
      expect(meta['versions'][1]['version'], '0.0.3');
      expect(
          meta['versions'][1]['pubspecYaml'], readPubspec(package0, '0.0.3'));
      expect(meta['versions'][2]['version'], version);
      expect(
          meta['versions'][2]['pubspecYaml'], readPubspec(package0, version));
    });
  });

  group('get versions', () {
    test('existing at local', () async {
      var res = await getVersions(package0);
      expect(res.statusCode, HttpStatus.ok);

      var body = json.decode(res.body);
      expect(body['name'], package0);
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
      var result = await pubUploader(package0, 'add', email0);
      expect(result.stderr, contains('email already exists'));

      var meta = await readMeta(package0);
      expect(meta['uploaders'], unorderedEquals([email0]));
    });

    test('success', () async {
      var result = await pubUploader(package0, 'add', email1);
      expect(result.stderr, '');

      var meta = await readMeta(package0);
      expect(meta['uploaders'], unorderedEquals([email0, email1]));
    });
  });

  group('remove uploader', () {
    test('not in uploader', () async {
      var result = await pubUploader(package0, 'remove', email2);
      expect(result.stderr, contains('email not uploader'));

      var meta = await readMeta(package0);
      expect(meta['uploaders'], unorderedEquals([email0, email1]));
    });

    test('success', () async {
      var result = await pubUploader(package0, 'remove', email1);
      expect(result.stderr, '');

      var meta = await readMeta(package0);
      expect(meta['uploaders'], unorderedEquals([email0]));
    });
  });
}
