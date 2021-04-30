import 'package:flutter/material.dart';
import 'package:here_ex/locator/locator.dart';
import 'package:here_ex/services/navigation_service/navigation_service.dart';
import 'package:here_ex/services/navigation_service/router.gr.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  NavigationService navigationService = locator<NavigationService>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FlatButton(
          onPressed: () {
            navigationService.pushNamed(Routes.addressSearchPage);
          },
          child: Text("Go to map"),
        ),
      ),
    );
  }
}
