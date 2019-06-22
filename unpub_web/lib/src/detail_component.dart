import 'dart:async';
import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:markdown/markdown.dart';
import 'package:unpub_web/app_service.dart';
import 'routes.dart';
import 'package:unpub_api/models.dart';

@Component(
  selector: 'detail',
  templateUrl: 'detail_component.html',
  directives: [NgFor, NgIf, NgClass, RouterLink],
  providers: [ClassProvider(AppService)],
  exports: [RoutePaths],
)
class DetailComponent implements OnInit, OnActivate {
  final AppService appService;

  WebapiDetailView package;
  int activeTab = 0;
  DetailComponent(this.appService);

  String get readmeHtml =>
      package.readme == null ? null : markdownToHtml(package.readme);

  String get changelogHtml =>
      package.changelog == null ? null : markdownToHtml(package.changelog);

  @override
  Future<Null> ngOnInit() async {
    activeTab = 0;
  }

  @override
  void onActivate(_, RouterState current) async {
    final name = current.parameters['name'];
    final version = current.parameters['version'];

    if (name != null) {
      package = await appService.fetchPackage(name, version);
    }
  }

  getListUrl(String name) {
    return RoutePaths.list.toUrl(parameters: {'name': name});
  }

  getDetailUrl(String name, [String version]) {
    if (version == null) {
      return RoutePaths.detail.toUrl(parameters: {'name': name});
    } else {
      return RoutePaths.detailVersion
          .toUrl(parameters: {'name': name, 'version': version});
    }
  }
}
