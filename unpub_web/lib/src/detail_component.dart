import 'dart:async';
import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:unpub_web/app_service.dart';
import 'routes.dart';

@Component(
  selector: 'detail',
  templateUrl: 'detail_component.html',
  directives: [NgFor, NgIf, NgClass, RouterLink],
  providers: [ClassProvider(AppService)],
  exports: [RoutePaths],
)
class DetailComponent implements OnInit {
  final AppService appService;

  Map<String, dynamic> package;
  int activeTab = 0;
  DetailComponent(this.appService);

  get name => package['name'];
  get version => package['version'];
  get createdAt => package['createdAt'];
  get pubspec => package['pubspec'];
  get versions => package['versions'];
  get readme => package['readme'];
  get changelog => package['changelog'];
  get uploaders => package['uploaders'];

  get authors {
    if (pubspec['author'] != null) {
      return [pubspec['author']];
    }
    if (pubspec['authors'] != null) {
      return pubspec['authors'];
    }
    return [];
  }

  get dependencies {
    var deps = (pubspec['dependencies'] as Map).cast<String, String>();
    if (deps == null) return [];
    return deps.keys;
  }

  @override
  Future<Null> ngOnInit() async {
    package = await appService.fetchPackage('router');
  }

  getDetailUrl(package) {
    return RoutePaths.detail.toUrl(parameters: {'name': package['name']});
  }
}
