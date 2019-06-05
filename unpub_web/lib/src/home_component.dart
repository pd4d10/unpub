import 'dart:async';
import 'package:angular/angular.dart';
import 'package:unpub_web/app_service.dart';

@Component(
  selector: 'home',
  templateUrl: 'home_component.html',
  directives: [NgFor, NgIf],
  providers: [ClassProvider(AppService)],
)
class HomeComponent implements OnInit {
  final AppService appService;

  List packages = [];
  HomeComponent(this.appService);

  @override
  Future<Null> ngOnInit() async {
    packages = await appService.fetchTop();
  }
}
