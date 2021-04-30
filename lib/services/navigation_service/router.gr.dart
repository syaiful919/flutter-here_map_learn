// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:auto_route/auto_route.dart';
import 'package:here_ex/ui/pages/home/home_page.dart';
import 'package:here_ex/ui/pages/map/map_page.dart';
import 'package:here_ex/ui/pages/pin_location/pin_location_page.dart';
import 'package:here_ex/ui/pages/address_search/address_search_page.dart';

abstract class Routes {
  static const homePage = '/';
  static const mapPage = '/map-page';
  static const pinLocationPage = '/pin-location-page';
  static const addressSearchPage = '/address-search-page';
  static const all = {
    homePage,
    mapPage,
    pinLocationPage,
    addressSearchPage,
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
    final args = settings.arguments;
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
      case Routes.pinLocationPage:
        if (hasInvalidArgs<PinLocationPageArguments>(args)) {
          return misTypedArgsRoute<PinLocationPageArguments>(args);
        }
        final typedArgs =
            args as PinLocationPageArguments ?? PinLocationPageArguments();
        return MaterialPageRoute<dynamic>(
          builder: (context) => PinLocationPage(
              key: typedArgs.key, initialLoc: typedArgs.initialLoc),
          settings: settings,
        );
      case Routes.addressSearchPage:
        return MaterialPageRoute<dynamic>(
          builder: (context) => AddressSearchPage(),
          settings: settings,
        );
      default:
        return unknownRoutePage(settings.name);
    }
  }
}

// *************************************************************************
// Arguments holder classes
// **************************************************************************

//PinLocationPage arguments holder class
class PinLocationPageArguments {
  final Key key;
  final SearchSuggestionModel initialLoc;
  PinLocationPageArguments({this.key, this.initialLoc});
}
