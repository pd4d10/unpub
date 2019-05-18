import 'package:mongo_dart/mongo_dart.dart';
import 'package:unpub/unpub.dart';

final packageCollection = 'packages';

class UnpubMongo extends UnpubMetaStore {
  Db db;

  static Future<UnpubMongo> connect(String url) async {
    var db = Db(url);
    await db.open();
    return UnpubMongo()..db = db;
  }

  Future<UnpubPackage> _queryPackage(String package) async {
    var map = await db
        .collection(packageCollection)
        .findOne(where.eq('name', package));
    if (map == null) return null;
    return UnpubPackage.fromJson(map);
  }

  @override
  Stream<UnpubVersion> getAllVersions(String name) async* {
    var package = await _queryPackage(name);
    if (package == null) return;
    yield* Stream.fromIterable(package.versions);
  }

  @override
  Future<UnpubVersion> getVersion(String package, String version) async {
    return getAllVersions(package)
        .firstWhere((item) => item.version == version, orElse: () => null);
  }

  @override
  Future<void> addVersion(
      String name, UnpubVersion version, UnpubUploader uploader) async {
    var dataToPush = {'versions': version.toJson()};
    if (uploader != null) {
      dataToPush['uploaders'] = uploader.toJson();
    }
    await db
        .collection(packageCollection)
        .update(where.eq('name', name), {'\$push': dataToPush}, upsert: true);
  }

  @override
  Future<void> addUploader(String name, String email) async {
    await db.collection(packageCollection).update(
        where.eq('name', name),
        {
          '\$push': {
            'uploaders.email': email,
          }
        },
        upsert: true);
  }

  @override
  Future<void> removeUploader(String name, String email) async {
    await db.collection(packageCollection).update(
        where.eq('name', name),
        {
          '\$pull': {
            'uploaders.email': email,
          }
        },
        upsert: true);
  }

  @override
  Stream<UnpubUploader> getUploaders(String name) async* {
    var package = await _queryPackage(name);
    yield* Stream.fromIterable(package.uploaders);
  }
}
