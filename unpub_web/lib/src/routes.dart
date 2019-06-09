import 'package:angular_router/angular_router.dart';

import 'home_component.template.dart' as home_template;
// import 'not_found_component.template.dart' as not_found_template;

class RoutePaths {
  static final home = RoutePath(path: '');
  static final list = RoutePath(path: 'packages');
  static final detail = RoutePath(path: 'packages/:name');
}

String getName(Map<String, String> parameters) {
  return parameters['name'];
}

class Routes {
  static final home = RouteDefinition(
    routePath: RoutePaths.home,
    component: home_template.HomeComponentNgFactory,
  );

  static final all = <RouteDefinition>[
    home,
    // RouteDefinition.redirect(
    //   path: '',
    //   redirectTo: RoutePaths.heroes.toUrl(),
    // ),
    // RouteDefinition(
    //   path: '.*',
    //   component: not_found_template.NotFoundComponentNgFactory,
    // ),
  ];
}
