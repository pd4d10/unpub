import 'dart:async';
import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:unpub_web/app_service.dart';
import 'package:unpub_web/src/api/models.dart';
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

  DetailView package;
  int activeTab = 0;
  DetailComponent(this.appService);

  get authors {
    if (package.pubspec['author'] != null) {
      return [package.pubspec['author']];
    }
    if (package.pubspec['authors'] != null) {
      return package.pubspec['authors'];
    }
    return [];
  }

  get dependencies {
    var deps = (package.pubspec['dependencies'] as Map).cast<String, String>();
    if (deps == null) return [];
    return deps.keys;
  }

  @override
  Future<Null> ngOnInit() async {
    package = await appService.fetchDetail('router', '0.2.6');
  }

  getDetailUrl(PackageView package) {
    return RoutePaths.detail.toUrl(parameters: {'name': package.name});
  }
}
