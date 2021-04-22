// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:auto_route/auto_route.dart';
import 'package:here_ex/ui/pages/home/home_page.dart';
import 'package:here_ex/ui/pages/map/map_page.dart';

abstract class Routes {
  static const homePage = '/';
  static const mapPage = '/map-page';
  static const all = {
    homePage,
    mapPage,
  };
}

class Router extends RouterBase {
  @override
  Set<String> get allRoutes => Routes.all;

  @Deprecated('call ExtendedNavigator.ofRouter<Router>() directly')
  static ExtendedNavigatorState get navigator =>
      ExtendedNavigator.ofRouter<Router>();

  @override
  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.homePage:
        return MaterialPageRoute<dynamic>(
          builder: (context) => HomePage(),
          settings: settings,
        );
      case Routes.mapPage:
        return MaterialPageRoute<dynamic>(
          builder: (context) => MapPage(),
          settings: settings,
        );
      default:
        return unknownRoutePage(settings.name);
    }
  }
}
