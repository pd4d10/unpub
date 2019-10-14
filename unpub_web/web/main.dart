import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:unpub_web/app_component.template.dart' as ng;
import 'package:unpub_web/constants.dart';
import 'main.template.dart' as self;

@GenerateInjector(isProduction ? routerProviders : routerProvidersHash)
final InjectorFactory injector = self.injector$Injector;

void main() {
  runApp(ng.AppComponentNgFactory, createInjector: injector);
}
