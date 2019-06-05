import 'package:angular/angular.dart';
import 'package:unpub_web/src/home_component.dart';

@Component(
  selector: 'my-app',
  styleUrls: ['app_component.css'],
  templateUrl: 'app_component.html',
  directives: [HomeComponent],
)
class AppComponent {
  // Nothing here yet. All logic is in TodoListComponent.
}
