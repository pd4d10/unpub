import 'package:mongo_dart/mongo_dart.dart';
import 'package:intl/intl.dart';
import 'package:unpub/src/models.dart';

final packageCollection = 'packages';
final statsCollection = 'stats';

class UnpubMetaStore {
  Db db;

  UnpubMetaStore(String uri) : db = Db(uri);

  Future<UnpubPackage> _queryPackage(String package) async {
    var map = await db
        .collection(packageCollection)
        .findOne(where.eq('name', package));
    if (map == null) return null;
    return UnpubPackage.fromJson(map);
  }

  Stream<UnpubVersion> getAllVersions(String name) async* {
    var package = await _queryPackage(name);
    if (package == null) return;
    yield* Stream.fromIterable(package.versions);
  }

  Future<UnpubVersion> getVersion(String package, String version) async {
    return getAllVersions(package)
        .firstWhere((item) => item.version == version, orElse: () => null);
  }

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

  Stream<String> getUploaders(String name) async* {
    var package = await _queryPackage(name);
    yield* Stream.fromIterable(package.uploaders);
  }

  void increaseDownloadCount(String name) {
    var today = DateFormat('yyyyMMdd').format(DateTime.now());
    db.collection(statsCollection).update(
        where.eq('name', name),
        {
          '\$inc': {'download': 1, 'd$today': 1}
        },
        upsert: true);
  }

  void increaseQueryCount(String name) {
    db.collection(statsCollection).update(
        where.eq('name', name),
        {
          '\$inc': {'query': 1}
        },
        upsert: true);
  }
}
