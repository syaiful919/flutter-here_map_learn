import 'package:flutter/material.dart';

import 'package:flutter/services.dart' show rootBundle;
import 'package:here_ex/ui/pages/address_search/address_search_page.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/core.errors.dart';
import 'package:here_sdk/gestures.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/search.dart';

class PinLocationPage extends StatefulWidget {
  final SearchSuggestionModel initialLoc;

  const PinLocationPage({
    Key key,
    this.initialLoc,
  }) : super(key: key);
  @override
  _PinLocationPageState createState() => _PinLocationPageState();
}

class _PinLocationPageState extends State<PinLocationPage> {
  SearchEngine _searchEngine;

  SearchSuggestionModel _currentLocation;
  HereMapController _mapController;
  SearchSuggestionModel _locationAtCenter;

  @override
  void initState() {
    super.initState();
    initSeacrhEngine();
    getCurrentCoordinate();
  }

  void initSeacrhEngine() {
    try {
      _searchEngine = new SearchEngine();
    } on InstantiationException {
      print(">>> Initialization of SearchEngine failed.");
    }
  }

  void getCurrentCoordinate() async {
    GeoCoordinates _currentCoordinates =
        GeoCoordinates(-6.3052470084405545, 106.75474866898688);
    SearchSuggestionModel _loc = await _reverseGeocoding(_currentCoordinates);

    setState(() {
      _currentLocation = _loc;
    });
  }

  void goToCurrentLocation() {
    setState(() {});

    _mapController.camera.flyToWithOptions(
        _locationAtCenter.coordinates, MapCameraFlyToOptions.withDefaults());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            children: [
              Expanded(
                flex: 8,
                child: Stack(
                  children: [
                    HereMap(onMapCreated: _onMapCreated),
                    Center(child: Icon(Icons.location_pin)),
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: FloatingActionButton(
                        onPressed: () => goToCurrentLocation(),
                        child: Icon(
                          Icons.location_searching,
                          color: Colors.white,
                        ),
                      ),
                    )
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Container(
                  color: Colors.white,
                  alignment: Alignment.center,
                  child: _locationAtCenter == null
                      ? Container()
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_locationAtCenter.title),
                            Text(
                                "${_locationAtCenter.coordinates.latitude}, ${_locationAtCenter.coordinates.longitude}"),
                          ],
                        ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  void _onMapCreated(HereMapController hereMapController) {
    _mapController = hereMapController;

    _mapController.mapScene.loadSceneForMapScheme(MapScheme.normalDay,
        (MapError error) {
      if (error != null) {
        print('Map scene not loaded. MapError: ${error.toString()}');
        return;
      }

      const double distanceToEarthInMeters = 2000;
      _mapController.camera.lookAtPointWithDistance(
          widget.initialLoc.coordinates ?? _currentLocation,
          distanceToEarthInMeters);

      setState(() {
        _locationAtCenter = widget.initialLoc ?? _currentLocation;
      });
    });

    MapCameraObserver observer =
        MapCameraObserver.fromLambdas(lambda_onCameraUpdated: (val) {
      _getAddressForCoordinates(val.targetCoordinates);
    });

    _mapController.camera.addObserver(observer);
  }

  Future<void> _getAddressForCoordinates(GeoCoordinates geoCoordinates) async {
    int maxItems = 1;
    SearchOptions reverseGeocodingOptions =
        new SearchOptions(LanguageCode.idId, maxItems);

    _searchEngine.searchByCoordinates(geoCoordinates, reverseGeocodingOptions,
        (SearchError searchError, List<Place> list) async {
      if (searchError != null) {
        print(">>> Reverse geocoding Error: $searchError ");
        return null;
      }

      // If error is null, list is guaranteed to be not empty.
      SearchSuggestionModel _loc = SearchSuggestionModel(
          coordinates: list.first.geoCoordinates,
          title: list.first.address.addressText);

      setState(() {
        _locationAtCenter = _loc;
      });
    });
  }

  Future<SearchSuggestionModel> _reverseGeocoding(geoCoordinates) {
    int maxItems = 1;
    SearchOptions reverseGeocodingOptions =
        new SearchOptions(LanguageCode.idId, maxItems);

    _searchEngine.searchByCoordinates(geoCoordinates, reverseGeocodingOptions,
        (SearchError searchError, List<Place> list) async {
      if (searchError != null) {
        print(">>> Reverse geocoding Error: $searchError ");
        return null;
      }

      // If error is null, list is guaranteed to be not empty.

      print(">>> ${list.first.address.addressText}, ");

      return SearchSuggestionModel(
          coordinates: list.first.geoCoordinates,
          title: list.first.address.addressText);
    });
  }

  @override
  void dispose() {
    super.dispose();
    _mapController?.release();
  }
}
