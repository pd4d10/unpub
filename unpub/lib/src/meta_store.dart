import 'package:mongo_dart/mongo_dart.dart';
import 'package:intl/intl.dart';
import 'package:unpub/src/models.dart';

final packageCollection = 'packages';
final statsCollection = 'stats';

class MetaStore {
  Db db;

  MetaStore(String uri) : db = Db(uri);

  Future<UnpubPackage> queryPackage(String package) async {
    var json = await db
        .collection(packageCollection)
        .findOne(where.eq('name', package));
    if (json == null) return null;
    return UnpubPackage.fromJson(json);
  }

  Future<UnpubVersion> queryPackageVersion(String name, String version) async {
    var package = await queryPackage(name);
    if (package == null) return null;

    return package.versions
        .firstWhere((item) => item.version == version, orElse: () => null);
  }

  Future<void> addVersion(String name, UnpubVersion version) async {
    await Future.wait([
      db.collection(packageCollection).update(
          where.eq('name', name),
          {
            '\$push': {
              'versions': version.toJson(),
            },
            '\$addToSet': {
              'uploaders': version.uploader,
            }
          },
          upsert: true),
      db.collection(statsCollection).update(
          where.eq('name', name),
          {
            '\$setOnInsert': {'download': 0}
          },
          upsert: true)
    ]);
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

  void increaseDownloadCount(String name) {
    var today = DateFormat('yyyyMMdd').format(DateTime.now());
    db.collection(statsCollection).update(
        where.eq('name', name),
        {
          '\$inc': {'download': 1, 'd$today': 1}
        },
        upsert: true);
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

  Future<int> queryCount(String q) {
    return db.collection(packageCollection).count(_buildSearchSelector(q));
  }

  Future<List<UnpubPackage>> querySortedPackages(
      int size, int page, String sort, String q) async {
    var selector = _buildSearchSelector(q)
        .sortBy(sort, descending: true)
        .limit(size)
        .skip(page * size);

    var packages = await db
        .collection(packageCollection)
        .find(selector)
        .map((item) => UnpubPackage.fromJson(item))
        .toList();

    return packages;
  }
}
