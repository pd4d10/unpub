import 'models.dart';
export 'models.dart';

abstract class UnpubMetaStore {
  Stream<UnpubVersion> getAllVersions(String name);

  Future<UnpubVersion> getVersion(String name, String version);

  Future<void> addVersion(UnpubVersion version);

  Future<List<UnpubUploader>> getUploaders(String name);

  Future<void> addUploader(String name, UnpubUploader uploader);

  Future<void> removeUploader(String name, UnpubUploader uploader);
}
