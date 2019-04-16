# Unpub

[![pub](https://img.shields.io/pub/v/unpub.svg)](https://pub.dartlang.org/packages/unpub)

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
import 'package:unpub/unpub.dart';

var baseDir = path.absolute('unpub-data');

var repository = UnpubRepository(
  metaStore: UnpubFileMetaStore(baseDir),
  // You can also use MongoDB as meta store
  // metaStore: await UnpubMongo.connect('mongodb://localhost:27017/dart_pub'),

  packageStore: UnpubFilePackageStore(baseDir),

  shouldCheckUploader: true,
);

var server = UnpubServer(repository);
server.serve('0.0.0.0', 3000);

```

## License

MIT
