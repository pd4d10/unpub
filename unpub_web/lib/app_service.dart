import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:angular/core.dart';
import 'src/routes.dart';
import 'package:unpub_api/models.dart';

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

  Future<List<WebapiListView>> fetchPackages(
      {int size, int page, String sort, String q}) async {
    var res = await _fetch(
        '/webapi/packages', {'size': size, 'page': page, 'sort': sort, 'q': q});
    return (res as List).map((item) => WebapiListView.fromJson(item)).toList();
  }

  Future<WebapiDetailView> fetchPackage(String name, String version) async {
    version = version ?? 'latest';
    var res = await _fetch('/webapi/package/$name/$version');
    return WebapiDetailView.fromJson(res);
  }

  getDetailUrl(package) {
    return RoutePaths.detail.toUrl(parameters: {'name': package['name']});
  }
}
