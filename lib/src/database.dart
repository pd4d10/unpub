import 'package:pub_server/repository.dart';
export 'package:pub_server/repository.dart';

abstract class UnpubDatabase {
  Stream<PackageVersion> getAllVersions(String package);

  Future<PackageVersion> getVersion(String package, String version);

  Future<void> addVersion(
      String package, String version, String pubspecContent);

  Future<List<String>> getUploadersOfPackage(String package);

  Future<void> addUploader(String package, String email);

  Future<void> removeUploader(String package, String email);
}
