import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:pub_server/shelf_pubserver.dart';
// import 'package:pub_dartlang_org/frontend/handlers.dart';

import 'repository.dart';

class UnpubServer {
  ShelfPubServer _pubServer;

  UnpubRepository repository;

  UnpubServer(this.repository) : _pubServer = ShelfPubServer(repository);

  serve(String host, int port) async {
    var handler = const shelf.Pipeline()
        .addMiddleware(shelf.logRequests())
        .addHandler(_pubServer.requestHandler);
    // .addHandler((shelf.Request request) =>
    //     appHandler(request, _pubServer.requestHandler));

    var server = await io.serve(handler, host, port);
    print('Serving at http://${server.address.host}:${server.port}');
  }
}
