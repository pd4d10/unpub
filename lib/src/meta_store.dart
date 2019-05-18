import 'models.dart';
export 'models.dart';

abstract class UnpubMetaStore {
  Stream<UnpubVersion> getAllVersions(String name);

  Future<UnpubVersion> getVersion(String name, String version);

  Future<void> addVersion(
      String name, UnpubVersion version, String uploaderEmail);

  Stream<String> getUploaders(String name);

  Future<void> addUploader(String name, String email);

  Future<void> removeUploader(String name, String email);

  void increaseDownloadCount(String name);

  void increaseQueryCount(String name);
}
