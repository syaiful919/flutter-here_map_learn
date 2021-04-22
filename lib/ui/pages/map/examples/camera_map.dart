import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/mapview.dart';

class CameraMap extends StatefulWidget {
  @override
  _CameraMapState createState() => _CameraMapState();
}

class _CameraMapState extends State<CameraMap> with TickerProviderStateMixin {
  CameraExample _cameraExample;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('HERE SDK - Camera Example'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _moveButtonClicked,
        child: Icon(
          Icons.location_searching,
          color: Colors.white,
        ),
      ),
      body: Stack(
        children: [
          HereMap(onMapCreated: _onMapCreated),
        ],
      ),
    );
  }

  void _onMapCreated(HereMapController hereMapController) {
    hereMapController.mapScene.loadSceneForMapScheme(MapScheme.normalDay,
        (MapError error) {
      if (error == null) {
        _cameraExample = CameraExample(hereMapController);
      } else {
        print("Map scene not loaded. MapError: " + error.toString());
      }
    });
  }

  void _moveButtonClicked() {
    _cameraExample.move();
  }
}

// This example shows how to animate the MapCamera from A to B with the Camera's flyTo()-method
class CameraExample {
  HereMapController _hereMapController;
  final double distanceToEarthInMeters = 2000;
  MapPolygon centerMapCircle;

  CameraExample(HereMapController hereMapController) {
    _hereMapController = hereMapController;

    // Set initial map center to a location in Berlin.
    GeoCoordinates mapCenter =
        GeoCoordinates(-6.3052470084405545, 106.75474866898688);
    _hereMapController.camera
        .lookAtPointWithDistance(mapCenter, distanceToEarthInMeters);
    _setNewMapCircle(mapCenter);
  }

  void move() {
    GeoCoordinates newTarget = _createRandomGeoCoordinatesNearby();

    // Indicate the new map center with a circle.
    _setNewMapCircle(newTarget);

    _hereMapController.camera
        .flyToWithOptions(newTarget, MapCameraFlyToOptions.withDefaults());
  }

  void _setNewMapCircle(GeoCoordinates geoCoordinates) {
    if (centerMapCircle != null) {
      _hereMapController.mapScene.removeMapPolygon(centerMapCircle);
    }
    centerMapCircle = _createMapCircle(geoCoordinates);
    _hereMapController.mapScene.addMapPolygon(centerMapCircle);
  }

  MapPolygon _createMapCircle(GeoCoordinates geoCoordinates) {
    double radiusInMeters = 50;
    GeoCircle geoCircle = GeoCircle(geoCoordinates, radiusInMeters);

    GeoPolygon geoPolygon = GeoPolygon.withGeoCircle(geoCircle);
    Color fillColor = Colors.blue.withOpacity(0.5);
    MapPolygon mapPolygon = MapPolygon(geoPolygon, fillColor);

    return mapPolygon;
  }

  GeoCoordinates _createRandomGeoCoordinatesNearby() {
    GeoBox geoBox = _hereMapController.camera.boundingBox;
    if (geoBox == null) {
      // Happens only when map is not fully covering the viewport.
      return GeoCoordinates(52.530932, 13.384915);
    }

    GeoCoordinates northEast = geoBox.northEastCorner;
    GeoCoordinates southWest = geoBox.southWestCorner;

    double minLat = southWest.latitude;
    double maxLat = northEast.latitude;
    double lat = _getRandom(minLat, maxLat);

    double minLon = southWest.longitude;
    double maxLon = northEast.longitude;
    double lon = _getRandom(minLon, maxLon);

    int sign1 = math.Random().nextBool() ? 1 : -1;
    int sign2 = math.Random().nextBool() ? 1 : -1;

    return GeoCoordinates(lat + 0.05 * sign1, lon + 0.05 * sign2);
  }

  double _getRandom(double min, double max) {
    return min + math.Random().nextDouble() * (max - min);
  }
}
