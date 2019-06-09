import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:angular/core.dart';
import 'src/api/models.dart';

@Injectable()
class AppService {
  Future _fetch(String path) async {
    var uri = Uri.parse('http://localhost:4000');
    var res = await http.get(uri.resolve(path));
    var data = json.decode(res.body);
    return data['data'];
  }

  Future<List<PackageView>> fetchTop() async {
    var items = await _fetch('/webapi/top');
    return (items as List).map(((item) => PackageView.fromJson(item))).toList();
  }
}
