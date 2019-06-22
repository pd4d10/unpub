import 'dart:async';
import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:markdown/markdown.dart';
import 'package:unpub_web/app_service.dart';
import 'routes.dart';

@Component(
  selector: 'detail',
  templateUrl: 'detail_component.html',
  directives: [NgFor, NgIf, NgClass, RouterLink],
  providers: [ClassProvider(AppService)],
  exports: [RoutePaths],
)
class DetailComponent implements OnInit, OnActivate {
  final AppService appService;

  Map<String, dynamic> package;
  int activeTab = 0;
  DetailComponent(this.appService);

  get name => package['version']['name'];
  get version => package['version']['version'];
  get createdAt => package['version']['createdAt'];
  get pubspec => package['version']['pubspec'];
  get versions => package['versions'];
  get uploaders => package['version']['uploaders'];

  get authors {
    if (pubspec['author'] != null) {
      return [pubspec['author']];
    }
    if (pubspec['authors'] != null) {
      return pubspec['authors'];
    }
    return [];
  }

  get readmeHtml {
    var readme = package['version']['readme'];
    if (readme == null) return null;
    return markdownToHtml(readme);
  }

  get changelogHtml {
    var changelog = package['version']['changelog'];
    if (changelog == null) return null;
    return markdownToHtml(changelog);
  }

  get dependencies {
    var deps = (pubspec['dependencies'] as Map).cast<String, String>();
    if (deps == null) return [];
    return deps.keys;
  }

  @override
  Future<Null> ngOnInit() async {}

  @override
  void onActivate(_, RouterState current) async {
    final name = current.parameters['name'];
    final version = current.parameters['version'];

    if (name != null) {
      package = await appService.fetchPackage(name, version);
    }
  }

  getDetailUrl(package) {
    return RoutePaths.detail.toUrl(parameters: {'name': package['name']});
  }
}
