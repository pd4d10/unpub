import 'package:mongo_dart/mongo_dart.dart';
import 'package:unpub/unpub.dart';

final packageCollection = 'packages';
final statsCollection = 'stats';

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
      String name, UnpubVersion version, String uploaderEmail) async {
    await db.collection(packageCollection).update(
        where.eq('name', name),
        {
          '\$push': {
            'versions': version.toJson(),
          },
          '\$addToSet': {
            'uploaders': uploaderEmail,
          }
        },
        upsert: true);
  }

  @override
  Future<void> addUploader(String name, String email) async {
    await db.collection(packageCollection).update(
        where.eq('name', name),
        {
          '\$push': {
            'uploaders': email,
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
            'uploaders': email,
          }
        },
        upsert: true);
  }

  @override
  Stream<String> getUploaders(String name) async* {
    var package = await _queryPackage(name);
    yield* Stream.fromIterable(package.uploaders);
  }

  @override
  void increaseDownloadCount(String name) {
    db.collection(statsCollection).update(
        where.eq('name', name),
        {
          '\$inc': {'download': 1}
        },
        upsert: true);
  }

  @override
  void increaseQueryCount(String name) {
    db.collection(statsCollection).update(
        where.eq('name', name),
        {
          '\$inc': {'query': 1}
        },
        upsert: true);
  }
}
