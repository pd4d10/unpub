import 'package:mongo_dart/mongo_dart.dart';
import 'package_database.dart';

final packageCollection = 'packages';

class MongodbPackageDatabase extends PackageDatabase {
  Db db;

  static Future<MongodbPackageDatabase> create(String url) async {
    var db = Db(url);
    await db.open();
    return MongodbPackageDatabase()..db = db;
  }

  @override
  Stream<PackageVersion> getAllVersions(String package) {
    return db
        .collection(packageCollection)
        .find(where.eq('name', package))
        .map((item) => PackageVersion(
              package,
              item['version'] as String,
              item['pubspec'] as String,
            ));
  }

  @override
  Future<PackageVersion> getVersion(String package, String version) async {
    var item = await db
        .collection(packageCollection)
        .findOne(where.eq('name', package).eq(version, 'version'));
    return PackageVersion(
      package,
      item['version'] as String,
      item['pubspec'] as String,
    );
  }

  @override
  Future<void> addVersion(
      String package, String version, String pubspecContent) async {
    await db.collection(packageCollection).insert({
      'name': package,
      'version': version,
      'pubspec': pubspecContent,
      'uploaders': [], // TODO:
      'create_at': DateTime.now(),
    });
  }
}
