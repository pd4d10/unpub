abstract class UnpubStorage {
  Uri downloadUri(String package, String version) {
    throw 'downloadUri not implemented';
  }

  Stream<List<int>> download(String package, String version) {
    throw 'download not implemented';
  }

  Future<void> upload(String package, String version, List<int> content);
}
