# Unpub

[![pub](https://img.shields.io/pub/v/unpub.svg)](https://pub.dev/packages/unpub)

Private Dart Pub for Enterprise.

## Usage

### Via command line

```sh
pub global activate unpub
```

Then run it:

```sh
unpub
```

It will use file system as meta store and package(tarball) store

### Via Dart API

```dart
import 'package:unpub/unpub.dart' as unpub;

main(List<String> args) async {
  var basedir = '/path/to/basedir'; // Base directory to save pacakges
  var db = 'mongodb://localhost:27017/dart_pub'; // MongoDB uri

  var metaStore = unpub.MetaStore(db);
  await metaStore.db.open();

  var app = unpub.App(
    metaStore: metaStore,
    packageStore: unpub.FileStore(basedir),
  );

  var server = await app.serve('0.0.0.0', 4000);
  print('Serving at http://${server.address.host}:${server.port}');
}
```

## License

MIT
