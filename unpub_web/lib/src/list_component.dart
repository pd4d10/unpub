import 'dart:async';
import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:unpub_web/app_service.dart';
import 'routes.dart';
import 'package:unpub_api/models.dart';

@Component(
  selector: 'list',
  templateUrl: 'list_component.html',
  directives: [routerDirectives, coreDirectives],
  exports: [RoutePaths],
)
class ListComponent implements OnInit, OnActivate {
  final AppService appService;
  static final size = 10;

  String q;
  int currentPage;
  ListApi data;
  ListComponent(this.appService);

  List<int> get pages {
    if (data == null) return [];
    var pageCount = (data.count / size).ceil();
    return List.filled(pageCount, 0);
  }

  @override
  Future<Null> ngOnInit() async {}

  @override
  void onActivate(RouterState previous, RouterState current) async {
    q = current.queryParameters['q'];
    currentPage = int.tryParse(current.queryParameters['page'] ?? '0') ?? 0;
    appService.setLoading(true);
    data = await appService.fetchPackages(size: size, page: currentPage, q: q);
    appService.setLoading(false);
  }

  getListUrl(int page) {
    Map<String, String> queryParameters = {};
    if (q != null) queryParameters['q'] = q;
    if (page > 0) queryParameters['page'] = page.toString();

    return RoutePaths.list.toUrl(queryParameters: queryParameters);
  }

  getDetailUrl(ListApiPackage package) {
    return RoutePaths.detail.toUrl(parameters: {'name': package.name});
  }
}
