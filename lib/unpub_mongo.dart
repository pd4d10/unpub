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
    return UnpubPackage.fromJson(map);
  }

  @override
  Stream<UnpubVersion> getAllVersions(String name) async* {
    var package = await _queryPackage(name);
    yield* Stream.fromIterable(package.versions);
  }

  @override
  Future<UnpubVersion> getVersion(String package, String version) async {
    return getAllVersions(package)
        .firstWhere((item) => item.version == version, orElse: () => null);
  }

  @override
  Future<void> addVersion(UnpubVersion version) async {
    await db.collection(packageCollection).update(
        where.eq('name', version.name),
        {
          '\$push': {
            'versions': version.toJson(),
          }
        },
        upsert: true);
  }

  @override
  Future<void> addUploader(String name, UnpubUploader uploader) async {
    await db.collection(packageCollection).update(
        where.eq('name', name),
        {
          '\$push': {
            'uploaders': uploader.toJson(),
          }
        },
        upsert: true);
  }

  @override
  Future<void> removeUploader(String name, UnpubUploader uploader) async {
    await db.collection(packageCollection).update(
        where.eq('name', name),
        {
          '\$pull': {
            'uploaders.email': uploader.email,
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
