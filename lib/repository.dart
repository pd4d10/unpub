import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:pub_server/repository.dart';
import 'package:yaml/yaml.dart';
import 'package:archive/archive.dart';

import 'http_proxy_repository.dart';
import 'package_database.dart';
import 'package_storage.dart';

final Logger _logger = new Logger('private_pub.repository');

class Repository extends PackageRepository {
  PackageDatabase database;
  PackageStorage storage;
  HttpProxyRepository proxy;

  Repository({
    @required this.database,
    @required this.storage,
    String proxyUrl,
  }) : proxy = HttpProxyRepository(
            http.Client(), Uri.parse(proxyUrl ?? 'https://pub.dartlang.org'));

  @override
  Stream<PackageVersion> versions(String package) async* {
    var items = await database.getAllVersions(package).toList();

    if (items.isEmpty) {
      yield* proxy.versions(package);
    } else {
      yield* Stream.fromIterable(items);
    }
  }

  @override
  Future<PackageVersion> lookupVersion(String package, String version) async {
    var item = await database.getVersion(package, version);
    return item ?? proxy.lookupVersion(package, version);
  }

  @override
  bool get supportsUpload => true;

  @override
  Future<PackageVersion> upload(Stream<List<int>> data) async {
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

    var package = pubspec['name'] as String;
    var version = pubspec['version'] as String;

    var existing = await database.getVersion(package, version);

    if (existing != null) {
      throw StateError('`$package` already exists at version `$version`.');
    }

    var pubspecContent = utf8.decode(pubspecArchiveFile.content);

    // Upload package tar to storage
    await storage.upload(package, version, tarballBytes);

    // Write package meta to database
    await database.addVersion(package, version, pubspecContent);

    return PackageVersion(package, version, pubspecContent);
  }

  @override
  Future<Stream<List<int>>> download(String package, String version) async {
    throw 'Should redirect to tos';
  }

  @override
  bool get supportsDownloadUrl => true;

  @override
  Future<Uri> downloadUrl(String package, String version) async {
    var item = await database.getVersion(package, version);
    if (item == null) {
      return proxy.downloadUrl(package, version);
    }
    return storage.resolve(package, version);
  }

  bool get supportsUploaders => false;

  Future addUploader(String package, String userEmail) async {
    // TODO:
  }

  Future removeUploader(String package, String userEmail) async {
    // TODO:
  }
}

List<int> _getBytes(ArchiveFile file) => file.content as List<int>;
