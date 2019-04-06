import 'src/storage.dart';

class UnpubFileStorage extends UnpubStorage {
  @override
  Future<void> upload(String package, String version, List<int> content) {
    return null;
  }

  @override
  Stream<List<int>> download(String package, String version) {
    return null;
  }
}
