import 'package:flutter/material.dart';

import 'package:flutter/services.dart' show rootBundle;
import 'package:here_sdk/core.dart';
import 'package:here_sdk/gestures.dart';
import 'package:here_sdk/mapview.dart';

class PinLocationPage extends StatefulWidget {
  @override
  _PinLocationPageState createState() => _PinLocationPageState();
}

class _PinLocationPageState extends State<PinLocationPage> {
  GeoCoordinates _coordinatesAtCenter;
  GeoCoordinates _currentCoordinate;
  HereMapController _mapController;

  @override
  void initState() {
    super.initState();
    getCurrentCoordinate();
  }

  void getCurrentCoordinate() {
    _currentCoordinate =
        GeoCoordinates(-6.3052470084405545, 106.75474866898688);
  }

  void goToCurrentLocation() {
    setState(() {
      _coordinatesAtCenter =
          GeoCoordinates(-6.3052470084405545, 106.75474866898688);
    });
    _mapController.camera.flyToWithOptions(
        _coordinatesAtCenter, MapCameraFlyToOptions.withDefaults());
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
                  child: _coordinatesAtCenter == null
                      ? Container()
                      : Text(
                          "${_coordinatesAtCenter.latitude}, ${_coordinatesAtCenter.longitude}"),
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
      _mapController.camera
          .lookAtPointWithDistance(_currentCoordinate, distanceToEarthInMeters);

      setState(() {
        _coordinatesAtCenter = _currentCoordinate;
      });
    });

    MapCameraObserver observer =
        MapCameraObserver.fromLambdas(lambda_onCameraUpdated: (val) {
      setState(() {
        _coordinatesAtCenter = val.targetCoordinates;
      });
    });

    _mapController.camera.addObserver(observer);
  }

  @override
  void dispose() {
    super.dispose();
    _mapController?.release();
  }
}
