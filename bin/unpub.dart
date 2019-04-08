import 'dart:io';

import 'package:args/args.dart';

import 'package:unpub/unpub.dart';
import 'package:unpub/unpub_file.dart';

main(List<String> args) async {
  var parser = ArgParser();
  parser.addOption('host', abbr: 'h', defaultsTo: 'localhost');
  parser.addOption('port', abbr: 'p', defaultsTo: '3000');

  var results = parser.parse(args);

  var host = results['host'] as String;
  var port = int.parse(results['port'] as String);

  if (results.rest.isNotEmpty) {
    print('Got unexpected arguments: "${results.rest.join(' ')}".\n\nUsage:\n');
    print(parser.usage);
    exit(1);
  }

  var baseDir = 'unpub-data';

  var repository = UnpubRepository(
    metaStore: UnpubFileMetaStore(baseDir),
    packageStore: UnpubFilePackageStore(baseDir),
  );
  var server = UnpubServer(repository);
  server.serve(host, port);
}
