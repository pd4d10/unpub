import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'unpub.dart';

class UnpubFileMetaStore extends UnpubMetaStore {
  String baseDir;

  UnpubFileMetaStore(this.baseDir);

  Future<Map> _getMeta(String package) async {
    var metaFile = File(path.join(baseDir, package, 'meta.json'));

    if (await metaFile.exists()) {
      var metaString = await metaFile.readAsString();
      var meta = json.decode(metaString);
      return meta;
    } else {
      return null;
    }
  }

  Future<void> _setMeta(String package, Map meta) async {
    var metaFile = File(path.join(baseDir, package, 'meta.json'));

    await metaFile.writeAsString(json.encode(meta));
  }

  @override
  Stream<PackageVersion> getAllVersions(String package) async* {
    var meta = await _getMeta(package);
    if (meta == null) return;

    var vs = meta['versions'] as List;
    var versions = vs
        .map((item) => PackageVersion(
            package, item['version'] as String, item['pubspec'] as String))
        .toList();
    yield* Stream.fromIterable(versions);
  }

  @override
  Future<PackageVersion> getVersion(String package, String version) async {
    var meta = await _getMeta(package);
    if (meta == null) return null;

    var vs = meta['versions'] as List;
    var v = vs.firstWhere((item) => item['version'] == version);
    if (v == null) return null;

    return PackageVersion(package, version, v['pubspec'] as String);
  }

  @override
  Future<void> addVersion(
      String package, String version, String pubspecContent) async {
    var meta = await _getMeta(package);
    (meta['versions'] as List).add({
      'version': version,
      'pubspec': pubspecContent,
    });
    await _setMeta(package, meta);
  }

  @override
  Future<List<String>> getUploadersOfPackage(String package) async {
    var meta = await _getMeta(package);
    return (meta['uploaders'] as List)
        .map((uploaders) => uploaders['email'] as String);
  }

  @override
  Future<void> addUploader(String package, String email) async {
    var meta = await _getMeta(package);
    (meta['uploaders'] as List).add({'email': email});
    await _setMeta(package, meta);
  }

  @override
  Future<void> removeUploader(String package, String email) async {
    var meta = await _getMeta(package);
    (meta['uploaders'] as List)
        .removeWhere((uploaders) => (uploaders['email'] as String) == email);
    await _setMeta(package, meta);
  }
}

class UnpubFilePackageStore extends UnpubPackageStore {
  String baseDir;

  UnpubFilePackageStore(this.baseDir);

  File _getTarballFile(String package, String version) {
    var tarballPath = path.join(baseDir, package, version, 'package.tar.gz');
    return File(tarballPath);
  }

  @override
  Future<void> upload(String package, String version, List<int> bytes) async {
    await _getTarballFile(package, version).writeAsBytes(bytes);
  }

  @override
  Stream<List<int>> download(String package, String version) {
    return _getTarballFile(package, version).openRead();
  }
}
