import 'package:mongo_dart/mongo_dart.dart';
import 'package:intl/intl.dart';
import 'package:unpub/src/models.dart';
import 'meta_store.dart';

final packageCollection = 'packages';
final statsCollection = 'stats';

class MongoStore extends MetaStore {
  Db db;

  MongoStore(String uri) : db = Db(uri);
  MongoStore.pool(List<String> uris) : db = Db.pool(uris);

  SelectorBuilder _selectByName(String name) => where.eq('name', name);

  @override
  Future<UnpubPackage> queryPackage(String name) async {
    var json =
        await db.collection(packageCollection).findOne(_selectByName(name));
    if (json == null) return null;
    return UnpubPackage.fromJson(json);
  }

  @override
  Future<void> addVersion(String name, UnpubVersion version) async {
    await db.collection(packageCollection).update(
        _selectByName(name),
        modify
            .push('versions', version.toJson())
            .addToSet('uploaders', version.uploader)
            .setOnInsert('createdAt', version.createdAt)
            .setOnInsert('private', true)
            .setOnInsert('download', 0)
            .set('updatedAt', version.createdAt),
        upsert: true);
  }

  @override
  Future<void> addUploader(String name, String email) async {
    await db
        .collection(packageCollection)
        .update(_selectByName(name), modify.push('uploaders', email));
  }

  @override
  Future<void> removeUploader(String name, String email) async {
    await db
        .collection(packageCollection)
        .update(_selectByName(name), modify.pull('uploaders', email));
  }

  @override
  void increaseDownloads(String name, String version) {
    var today = DateFormat('yyyyMMdd').format(DateTime.now());
    db
        .collection(packageCollection)
        .update(_selectByName(name), modify.inc('download', 1));
    db
        .collection(statsCollection)
        .update(_selectByName(name), modify.inc('d$today', 1));
  }

  static final _keywordPrefixes = {
    'email:': (String email) => where.eq('uploaders', email),
    'package:': (String package) => where.match('name', '^$package.*'),
    'dependency:': (String dependency) => where.raw({
          // FIXME: raw
          'versions': {
            '\$elemMatch': {
              'pubspec.dependencies.$dependency': {'\$exists': true}
            }
          }
        }),
  };

  SelectorBuilder _buildSearchSelector(String q) {
    if (q == null || q == '') return where;

    for (var entry in _keywordPrefixes.entries) {
      if (q.startsWith(entry.key)) {
        return entry.value(q.substring(entry.key.length).trim());
      }
    }

    return where.match('name', '.*$q.*');
  }

  @override
  Future<int> queryCount(String q) {
    return db.collection(packageCollection).count(_buildSearchSelector(q));
  }

  @override
  Stream<UnpubPackage> queryPackages(
      int size, int page, String sort, String q) {
    var selector = _buildSearchSelector(q)
        .sortBy(sort, descending: true)
        .limit(size)
        .skip(page * size);

    return db
        .collection(packageCollection)
        .find(selector)
        .map((item) => UnpubPackage.fromJson(item));
  }
}
