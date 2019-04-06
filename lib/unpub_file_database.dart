import 'src/database.dart';

class UnpubFileDatabase extends UnpubDatabase {
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
}
