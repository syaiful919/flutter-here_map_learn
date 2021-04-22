import 'package:flutter/material.dart' hide Router;
import 'package:flutter/services.dart';
import 'package:here_ex/services/navigation_service/navigation_service.dart';
import 'package:here_ex/services/navigation_service/router.gr.dart';

import 'package:here_sdk/core.dart';

import 'locator/locator.dart';

void main() async {
  SdkContext.init(IsolateOrigin.main);

  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitDown,
    DeviceOrientation.portraitUp,
  ]);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Auto Route",
      debugShowCheckedModeBanner: false,
      onGenerateRoute: Router().onGenerateRoute,
      initialRoute: Routes.homePage,
      navigatorKey: locator<NavigationService>().navigationKey,
      builder: (context, widget) => Navigator(
        onGenerateRoute: (settings) {
          final mediaQueryData = MediaQuery.of(context);
          final constrainedTextScaleFactor =
              mediaQueryData.textScaleFactor.clamp(1.0, 1.1);

          return MaterialPageRoute(
            builder: (context) => MediaQuery(
              data: mediaQueryData.copyWith(
                textScaleFactor: constrainedTextScaleFactor,
              ),
              child: Scaffold(
                body: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 500),
                    child: Padding(
                      padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom),
                      child: Builder(builder: (context) => widget),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
