import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:args/args.dart';
import 'package:unpub/src/app.dart';
import 'package:unpub/src/meta_store.dart';
import 'package:unpub/unpub_file.dart';

main(List<String> args) async {
  var parser = ArgParser();
  parser.addOption('host', abbr: 'h', defaultsTo: '0.0.0.0');
  parser.addOption('port', abbr: 'p', defaultsTo: '4000');

  var results = parser.parse(args);

  var host = results['host'] as String;
  var port = int.parse(results['port'] as String);

  if (results.rest.isNotEmpty) {
    print('Got unexpected arguments: "${results.rest.join(' ')}".\n\nUsage:\n');
    print(parser.usage);
    exit(1);
  }

  var baseDir = path.absolute('unpub-data');

  var metaStore = UnpubMetaStore('mongodb://localhost:27017/dart_pub');
  await metaStore.db.open();

  var app = UnpubApp(
    metaStore: metaStore,
    packageStore: UnpubFileStore(baseDir),
  );

  var server = await app.serve(host, port);
  host = server.address.host;
  port = server.port;
  print('Serving at http://$host:$port');
}
