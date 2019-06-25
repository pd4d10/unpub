import 'package:unpub/src/models.dart';

abstract class MetaStore {
  Future<UnpubPackage> queryPackage(String name);

  Future<UnpubVersion> queryPackageVersion(String name, String version) async {
    var package = await queryPackage(name);
    if (package == null) return null;

    return package.versions
        .firstWhere((item) => item.version == version, orElse: () => null);
  }

  Future<void> addVersion(String name, UnpubVersion version);

  Future<void> addUploader(String name, String email);

  Future<void> removeUploader(String name, String email);

  void increaseDownloads(String name);

  Future<int> queryCount(String q);

  Stream<UnpubPackage> queryPackages(int size, int page, String sort, String q);
}
