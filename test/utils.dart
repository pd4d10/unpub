import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:unpub/unpub.dart';
import 'package:unpub/unpub_file.dart';
import 'package:unpub/unpub_mongo.dart';

final notExistingPacakge = 'not_existing_package';
final baseDir = path.absolute('unpub-data');
final pubHostedUrl = 'http://localhost:4000';
final baseUri = Uri.parse(pubHostedUrl);

final package0 = 'package_0';
final email0 = 'email0@example.com';
final email1 = 'email1@example.com';
final email2 = 'email2@example.com';

startServer() async {
  var app = UnpubApp(
    metaStore:
        await UnpubMongo.connect('mongodb://localhost:27017/dart_pub_test'),
    packageStore: UnpubFileStore(baseDir),
    uploaderEmailGetter: (token) async => email0,
  );

  await app.serve('0.0.0.0', 4000);
}

String readPubspec(String package, String version) {
  return File(path.absolute('test/fixtures', package, version, 'pubspec.yaml'))
      .readAsStringSync();
}

Future<http.Response> getVersions(String package) {
  package = Uri.encodeComponent(package);
  return http.get(baseUri.resolve('/api/packages/$package'));
}

Future<http.Response> getSpecificVersion(String package, String version) {
  package = Uri.encodeComponent(package);
  version = Uri.encodeComponent(version);
  return http.get(baseUri.resolve('/api/packages/$package/versions/$version'));
}

var pubCommand = Platform.isWindows ? 'pub.bat' : 'pub';

Future<ProcessResult> pubPublish(String name, String version) {
  return Process.run(pubCommand, ['publish', '--force'],
      workingDirectory: path.absolute('test/fixtures', name, version),
      environment: {'PUB_HOSTED_URL': pubHostedUrl});
}

Future<ProcessResult> pubUploader(String name, String operation, String email) {
  assert(['add', 'remove'].contains(operation), 'operation error');

  return Process.run(pubCommand, ['uploader', operation, email],
      workingDirectory: path.absolute('test/fixtures', name, '0.0.1'),
      environment: {'PUB_HOSTED_URL': pubHostedUrl});
}
