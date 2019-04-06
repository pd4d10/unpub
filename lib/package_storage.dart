abstract class PackageStorage {
  Uri resolve(String package, String version);

  Future<void> upload(String package, String version, List<int> content);

  Future<void> uploadStream(
      String package, String version, Stream<List<int>> content);
}
