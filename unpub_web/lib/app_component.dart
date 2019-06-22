import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:unpub_web/src/routes.dart';

@Component(
  selector: 'my-app',
  styleUrls: ['app_component.css'],
  templateUrl: 'app_component.html',
  directives: [RouterOutlet, RouterLink],
  exports: [RoutePaths, Routes],
)
class AppComponent {
  String get homeUrl => RoutePaths.home.toUrl();
}
