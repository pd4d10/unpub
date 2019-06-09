import 'package:angular/angular.dart';
import 'package:unpub_web/src/home_component.dart';
import 'package:unpub_web/src/routes.dart';

@Component(
  selector: 'my-app',
  styleUrls: ['app_component.css'],
  templateUrl: 'app_component.html',
  directives: [HomeComponent],
  exports: [RoutePaths, Routes],
)
class AppComponent {
  // Nothing here yet. All logic is in TodoListComponent.
}
