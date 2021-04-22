import 'package:here_ex/services/navigation_service/navigation_service.dart';
import 'package:get_it/get_it.dart';

final locator = GetIt.instance;

Future<void> setupLocator() async {
  // -------- SERVICE -------- //
  locator.registerSingleton<NavigationService>(NavigationService());
}
