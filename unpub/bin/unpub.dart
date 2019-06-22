import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:args/args.dart';
import 'package:unpub/unpub.dart' as unpub;

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

  var baseDir = path.absolute('unpub-packages');
  var db = 'mongodb://localhost:27017/dart_pub';

  var metaStore = unpub.MetaStore(db);
  await metaStore.db.open();

  var app = unpub.App(
    metaStore: metaStore,
    packageStore: unpub.FileStore(baseDir),
  );

  var server = await app.serve(host, port);
  print('Serving at http://${server.address.host}:${server.port}');
}
