import 'package:flutter/material.dart';

class NavigationService {
  GlobalKey<NavigatorState> _navigationKey = GlobalKey<NavigatorState>();

  GlobalKey<NavigatorState> get navigationKey => _navigationKey;

  void pop({dynamic params}) => _navigationKey.currentState.pop(params);

  Future<dynamic> pushNamedAndRemoveUntil(String routeName,
          {dynamic arguments}) =>
      _navigationKey.currentState.pushNamedAndRemoveUntil(
          routeName, (_) => false,
          arguments: arguments);

  Future<dynamic> pushNamed(String routeName, {dynamic arguments}) =>
      _navigationKey.currentState.pushNamed(routeName, arguments: arguments);

  Future<dynamic> pushReplacementNamed(String routeName, {dynamic arguments}) =>
      _navigationKey.currentState
          .pushReplacementNamed(routeName, arguments: arguments);
}
