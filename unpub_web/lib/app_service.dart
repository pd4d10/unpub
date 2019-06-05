import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:angular/core.dart';

@Injectable()
class AppService {
  Future _fetch(String path) async {
    var uri = Uri.parse('http://localhost:4000');
    var res = await http.get(uri.resolve(path));
    var data = json.decode(res.body);
    return data['data'];
  }

  fetchTop() => _fetch('/webapi/top');
}
