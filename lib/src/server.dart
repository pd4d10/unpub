import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:pub_server/shelf_pubserver.dart';

import 'database.dart';
import 'storage.dart';
import 'repository.dart';

class UnpubServer {
  ShelfPubServer _pubServer;

  UnpubDatabase database;
  UnpubStorage storage;

  UnpubServer({
    @required this.database,
    @required this.storage,

    // Upstream proxy
    String proxyUrl = 'https://pub.dartlang.org',

    /// Get Google account info via SSO
    bool shouldGetAccountInfo = false,
  }) : _pubServer = ShelfPubServer(UnpubRepository(
          database: database,
          storage: storage,
          proxyUrl: proxyUrl,
        ));

  serve(String host, int port) async {
    var handler = const shelf.Pipeline()
        .addMiddleware(shelf.logRequests())
        .addHandler(_pubServer.requestHandler);

    var server = await io.serve(handler, host, port);
    print('Serving at http://${server.address.host}:${server.port}');
  }
}
