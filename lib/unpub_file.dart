import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'unpub.dart';

class UnpubFileMetaStore extends UnpubMetaStore {
  String baseDir;

  UnpubFileMetaStore(this.baseDir);

  Future<UnpubPackage> _getPackageMeta(String package) async {
    var metaFile = File(path.join(baseDir, package, 'meta.json'));

    if (await metaFile.exists()) {
      var metaString = await metaFile.readAsString();
      return UnpubPackage.fromJson(json.decode(metaString));
    } else {
      return null;
    }
  }

  Future<void> _setPackageMeta(UnpubPackage package) async {
    var metaFile = File(path.join(baseDir, package.name, 'meta.json'));
    await metaFile.create(recursive: true);
    await metaFile.writeAsString(json.encode(package.toJson()));
  }

  @override
  Stream<UnpubVersion> getAllVersions(String name) async* {
    var package = await _getPackageMeta(name);
    if (package == null) return;

    yield* Stream.fromIterable(package.versions);
  }

  @override
  Future<UnpubVersion> getVersion(String name, String version) async {
    return getAllVersions(name)
        .firstWhere((item) => item.version == version, orElse: () => null);
  }

  @override
  Future<void> addVersion(
      String name, UnpubVersion version, UnpubUploader uploader) async {
    var package = await _getPackageMeta(name);
    if (package == null) {
      package = UnpubPackage(name: name, versions: [], uploaders: []);
    }

    package.versions.add(version);
    if (uploader != null) {
      package.uploaders.add(uploader);
    }
    await _setPackageMeta(package);
  }

  @override
  Stream<UnpubUploader> getUploaders(String name) async* {
    var package = await _getPackageMeta(name);
    yield* Stream.fromIterable(package.uploaders);
  }

  @override
  Future<void> addUploader(String name, UnpubUploader uploader) async {
    var package = await _getPackageMeta(name);
    package.uploaders.add(uploader);
    await _setPackageMeta(package);
  }

  @override
  Future<void> removeUploader(String name, UnpubUploader uploader) async {
    var package = await _getPackageMeta(name);
    package.uploaders.removeWhere((item) => item.email == uploader.email);
    await _setPackageMeta(package);
  }
}

class UnpubFilePackageStore extends UnpubPackageStore {
  String baseDir;

  UnpubFilePackageStore(this.baseDir);

  File _getTarballFile(String package, String version) {
    return File(path.join(baseDir, package, version, 'package.tar.gz'));
  }

  @override
  Future<void> upload(String package, String version, List<int> content) async {
    var file = _getTarballFile(package, version);
    await file.create(recursive: true);
    await file.writeAsBytes(content);
  }

  @override
  Stream<List<int>> download(String package, String version) {
    return _getTarballFile(package, version).openRead();
  }
}
