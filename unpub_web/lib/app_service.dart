import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:angular/core.dart';
import 'src/routes.dart';

@Injectable()
class AppService {
  Future _fetch(String path,
      [Map<String, dynamic> queryParameters = const {}]) async {
    queryParameters.entries
        .where((entry) => entry.value == null)
        .toList()
        .forEach((entry) => queryParameters.remove(entry.key));

    // TODO: production
    var uri = Uri.parse('http://localhost:4000').replace(
      path: path,
      queryParameters: queryParameters.map((k, v) => MapEntry(k, v.toString())),
    );
    var res = await http.get(uri);
    var data = json.decode(res.body);
    return data['data'];
  }

  Future fetchPackages({int size, int page, String sort, String q}) {
    return _fetch(
        '/webapi/packages', {'size': size, 'page': page, 'sort': sort, 'q': q});
  }

  Future fetchPackage(String name, String version) async {
    version = version ?? 'latest';
    return _fetch('/webapi/package/$name/$version');
  }

  getDetailUrl(package) {
    return RoutePaths.detail.toUrl(parameters: {'name': package['name']});
  }
}
