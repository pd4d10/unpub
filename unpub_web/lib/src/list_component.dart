import 'dart:async';
import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:unpub_web/app_service.dart';
import 'package:unpub_web/src/api/models.dart';
import 'routes.dart';

@Component(
  selector: 'list',
  templateUrl: 'list_component.html',
  directives: [NgFor, NgIf, RouterLink],
  providers: [ClassProvider(AppService)],
  exports: [RoutePaths],
)
class ListComponent implements OnInit {
  final AppService appService;

  List<PackageView> packages = [];
  ListComponent(this.appService);

  @override
  Future<Null> ngOnInit() async {
    packages = await appService.fetchTop();
  }

  getDetailUrl(PackageView package) {
    return RoutePaths.detail.toUrl(parameters: {'name': package.name});
  }
}
