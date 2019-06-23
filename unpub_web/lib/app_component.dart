import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:unpub_web/src/routes.dart';
import 'app_service.dart';

@Component(
  selector: 'my-app',
  styleUrls: ['app_component.css'],
  templateUrl: 'app_component.html',
  directives: [RouterOutlet, RouterLink, NgIf],
  exports: [RoutePaths, Routes],
  providers: [ClassProvider(AppService)],
)
class AppComponent {
  final AppService appService;

  AppComponent(this.appService);

  String get homeUrl => RoutePaths.home.toUrl();
  bool get loading {
    print(appService.loading);
    return appService.loading;
  }
}
