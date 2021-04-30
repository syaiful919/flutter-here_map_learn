import 'package:auto_route/auto_route_annotations.dart';
import 'package:here_ex/ui/pages/address_search/address_search_page.dart';
import 'package:here_ex/ui/pages/home/home_page.dart';
import 'package:here_ex/ui/pages/map/map_page.dart';
import 'package:here_ex/ui/pages/pin_location/pin_location_page.dart';

@MaterialAutoRouter()
class $Router {
  @initial
  HomePage homePage;
  MapPage mapPage;
  PinLocationPage pinLocationPage;
  AddressSearchPage addressSearchPage;
}
