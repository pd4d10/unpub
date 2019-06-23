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
  exports: [RoutePaths],
  styles: ['.not-exists { margin-top: 100px }'],
)
class DetailComponent implements OnInit, OnActivate {
  final AppService appService;
  DetailComponent(this.appService);

  WebapiDetailView package;
  String packageName;
  String packageVersion;
  int activeTab = 0;
  bool packageNotExists = false;

  String get readmeHtml =>
      package.readme == null ? null : markdownToHtml(package.readme);

  String get changelogHtml =>
      package.changelog == null ? null : markdownToHtml(package.changelog);

  String get pubDevLink {
    var url = 'https://pub.dev/packages/$packageName';
    if (packageVersion != null) {
      url += '/versions/$packageVersion';
    }
    return url;
  }

  @override
  Future<Null> ngOnInit() async {
    activeTab = 0;
  }

  @override
  void onActivate(_, RouterState current) async {
    final name = current.parameters['name'];
    final version = current.parameters['version'];

    if (name != null) {
      packageName = name;
      packageVersion = version;
      appService.setLoading(true);
      try {
        package = await appService.fetchPackage(name, version);
      } on PackageNotExistsException catch (e) {
        packageNotExists = true;
      } finally {
        appService.setLoading(false);
      }
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
