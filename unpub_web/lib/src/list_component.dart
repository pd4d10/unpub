import 'dart:async';
import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:unpub_web/app_service.dart';
import 'routes.dart';
import 'package:unpub_api/models.dart';

@Component(
  selector: 'list',
  templateUrl: 'list_component.html',
  directives: [NgFor, NgIf, RouterLink],
  providers: [ClassProvider(AppService)],
  exports: [RoutePaths],
)
class ListComponent implements OnInit {
  final AppService appService;

  List<WebapiListView> packages = [];
  ListComponent(this.appService);

  @override
  Future<Null> ngOnInit() async {
    packages = await appService.fetchPackages(size: 10);
  }

  getDetailUrl(WebapiListView package) {
    return RoutePaths.detail.toUrl(parameters: {'name': package.name});
  }
}
