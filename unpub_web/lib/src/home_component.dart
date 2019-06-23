import 'dart:async';
import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:unpub_web/app_service.dart';
import 'routes.dart';
import 'package:unpub_api/models.dart';

@Component(
  selector: 'home',
  templateUrl: 'home_component.html',
  directives: [routerDirectives, coreDirectives],
  exports: [RoutePaths],
)
class HomeComponent implements OnInit {
  final AppService appService;

  ListApi data;
  HomeComponent(this.appService);

  @override
  Future<Null> ngOnInit() async {
    appService.setLoading(true);
    data = await appService.fetchPackages(size: 15);
    appService.setLoading(false);
  }

  getDetailUrl(ListApiPackage package) {
    return RoutePaths.detail.toUrl(parameters: {'name': package.name});
  }
}
