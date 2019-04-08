import 'unpub.dart';

class UnpubFileMetaStore extends UnpubMetaStore {
  @override
  Stream<PackageVersion> getAllVersions(String package) {
    return null;
  }

  @override
  Future<PackageVersion> getVersion(String package, String version) {
    return null;
  }

  @override
  Future<void> addVersion(
      String package, String version, String pubspecContent) {
    return null;
  }

  @override
  Future<List<String>> getUploadersOfPackage(String package) {
    // TODO: implement getUploadersOfPackage
    return null;
  }

  @override
  Future<void> addUploader(String package, String email) {
    // TODO: implement addUploader
    return null;
  }

  @override
  Future<void> removeUploader(String package, String email) {
    // TODO: implement removeUploader
    return null;
  }
}

class UnpubFilePackageStore extends UnpubPackageStore {
  @override
  Future<void> upload(String package, String version, List<int> content) {
    return null;
  }

  @override
  Stream<List<int>> download(String package, String version) {
    return null;
  }
}
