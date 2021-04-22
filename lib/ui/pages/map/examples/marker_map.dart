import 'package:flutter/material.dart';

import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:here_sdk/core.dart';
import 'package:here_sdk/gestures.dart';
import 'package:here_sdk/mapview.dart';

class MarkerMap extends StatefulWidget {
  // Use _context only within the scope of this widget.
  @override
  _MarkerMapState createState() => _MarkerMapState();
}

class _MarkerMapState extends State<MarkerMap> {
  BuildContext _context;

  MapMarkerExample _mapMarkerExample;

  @override
  Widget build(BuildContext context) {
    _context = context;

    return Scaffold(
      appBar: AppBar(
        title: Text('HERE SDK - Marker Example'),
      ),
      body: Stack(
        children: [
          HereMap(onMapCreated: _onMapCreated),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  button('Anchored (2D)', _anchoredMapMarkersButtonClicked),
                  button('Centered (2D)', _centeredMapMarkersButtonClicked),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  button('Flat', _flatMapMarkersButtonClicked),
                  button('3D OBJ', _mapMarkers3DButtonClicked),
                  button('Clear', _clearButtonClicked),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onMapCreated(HereMapController hereMapController) {
    hereMapController.mapScene.loadSceneForMapScheme(MapScheme.normalDay,
        (MapError error) {
      if (error == null) {
        _mapMarkerExample =
            MapMarkerExample(_context, _showDialog, hereMapController);
      } else {
        print("Map scene not loaded. MapError: " + error.toString());
      }
    });
  }

  void _anchoredMapMarkersButtonClicked() {
    _mapMarkerExample.showAnchoredMapMarkers();
  }

  void _centeredMapMarkersButtonClicked() {
    _mapMarkerExample.showCenteredMapMarkers();
  }

  void _flatMapMarkersButtonClicked() {
    _mapMarkerExample.showFlatMapMarkers();
  }

  void _mapMarkers3DButtonClicked() {
    _mapMarkerExample.showMapMarkers3D();
  }

  void _clearButtonClicked() {
    _mapMarkerExample.clearMap();
  }

  Align button(String buttonLabel, Function callbackFunction) {
    return Align(
      alignment: Alignment.topCenter,
      child: RaisedButton(
        color: Colors.lightBlueAccent,
        textColor: Colors.white,
        onPressed: () => callbackFunction(),
        child: Text(buttonLabel, style: TextStyle(fontSize: 20)),
      ),
    );
  }

  Future<void> _showDialog(String title, String message) async {
    return showDialog<void>(
      context: _context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

// A callback to notifiy the hosting widget.
typedef ShowDialogFunction = void Function(String title, String message);

class MapMarkerExample {
  BuildContext _context;
  HereMapController _hereMapController;
  List<MapMarker> _mapMarkerList = [];
  List<MapMarker3D> _mapMarker3DList = [];
  MapImage _poiMapImage;
  MapImage _photoMapImage;
  MapImage _circleMapImage;
  ShowDialogFunction _showDialog;

  MapMarkerExample(BuildContext context, ShowDialogFunction showDialogCallback,
      HereMapController hereMapController) {
    _context = context;
    _showDialog = showDialogCallback;
    _hereMapController = hereMapController;

    double distanceToEarthInMeters = 8000;
    _hereMapController.camera.lookAtPointWithDistance(
        GeoCoordinates(52.530932, 13.384915), distanceToEarthInMeters);

    // Setting a tap handler to pick markers from map.
    _setTapGestureHandler();

    _showDialog("Note", "You can tap 2D markers.");
  }

  void showAnchoredMapMarkers() {
    _unTiltMap();

    GeoCoordinates geoCoordinates =
        _createRandomGeoCoordinatesAroundMapCenter();

    // Centered on location. Shown below the POI image to indicate the location.
    // The draw order is determined from what is first added to the map,
    // but since loading images is done async, we can make this explicit by setting
    // a draw order. High numbers are drawn on top of lower numbers.
    _addCircleMapMarker(geoCoordinates, 0);

    // Anchored, pointing to location.
    _addPOIMapMarker(geoCoordinates, 1);
  }

  void showCenteredMapMarkers() {
    _unTiltMap();

    GeoCoordinates geoCoordinates =
        _createRandomGeoCoordinatesAroundMapCenter();

    // Centered on location.
    _addPhotoMapMarker(geoCoordinates, 0);

    // Centered on location. Shown above the photo marker to indicate the location.
    _addCircleMapMarker(geoCoordinates, 1);
  }

  void showFlatMapMarkers() {
    // Tilt the map for a better 3D effect.
    _tiltMap();

    GeoCoordinates geoCoordinates =
        _createRandomGeoCoordinatesAroundMapCenter();

    // Adds a flat POI marker that rotates and tilts together with the map.
    _addFlatMarker3D(geoCoordinates);

    // A centered 2D map marker to indicate the exact location.
    // Note that 3D map markers are always drawn on top of 2D map markers.
    _addCircleMapMarker(geoCoordinates, 1);
  }

  void showMapMarkers3D() {
    // Tilt the map for a better 3D effect.
    _tiltMap();

    GeoCoordinates geoCoordinates =
        _createRandomGeoCoordinatesAroundMapCenter();

    // Adds a textured 3D model.
    // It's origin is centered on the location.
    _addMapMarker3D(geoCoordinates);
  }

  void clearMap() {
    for (var mapMarker in _mapMarkerList) {
      _hereMapController.mapScene.removeMapMarker(mapMarker);
    }
    _mapMarkerList.clear();

    for (var mapMarker3D in _mapMarker3DList) {
      _hereMapController.mapScene.removeMapMarker3d(mapMarker3D);
    }
    _mapMarker3DList.clear();
  }

  Future<void> _addPOIMapMarker(
      GeoCoordinates geoCoordinates, int drawOrder) async {
    // Reuse existing MapImage for new map markers.
    if (_poiMapImage == null) {
      Uint8List imagePixelData = await _loadFileAsUint8List('assets/poi.png');
      _poiMapImage =
          MapImage.withPixelDataAndImageFormat(imagePixelData, ImageFormat.png);
    }

    // By default, the anchor point is set to 0.5, 0.5 (= centered).
    // Here the bottom, middle position should point to the location.
    Anchor2D anchor2D = Anchor2D.withHorizontalAndVertical(0.5, 1);

    MapMarker mapMarker =
        MapMarker.withAnchor(geoCoordinates, _poiMapImage, anchor2D);
    mapMarker.drawOrder = drawOrder;

    Metadata metadata = new Metadata();
    metadata.setString("key_poi", "Metadata: This is a POI.");
    mapMarker.metadata = metadata;

    _hereMapController.mapScene.addMapMarker(mapMarker);
    _mapMarkerList.add(mapMarker);
  }

  Future<void> _addPhotoMapMarker(
      GeoCoordinates geoCoordinates, int drawOrder) async {
    // Reuse existing MapImage for new map markers.
    if (_photoMapImage == null) {
      Uint8List imagePixelData =
          await _loadFileAsUint8List('assets/here_car.png');
      _photoMapImage =
          MapImage.withPixelDataAndImageFormat(imagePixelData, ImageFormat.png);
    }

    MapMarker mapMarker = MapMarker(geoCoordinates, _photoMapImage);
    mapMarker.drawOrder = drawOrder;

    _hereMapController.mapScene.addMapMarker(mapMarker);
    _mapMarkerList.add(mapMarker);
  }

  Future<void> _addCircleMapMarker(
      GeoCoordinates geoCoordinates, int drawOrder) async {
    // Reuse existing MapImage for new map markers.
    if (_circleMapImage == null) {
      Uint8List imagePixelData =
          await _loadFileAsUint8List('assets/circle.png');
      _circleMapImage =
          MapImage.withPixelDataAndImageFormat(imagePixelData, ImageFormat.png);
    }

    MapMarker mapMarker = MapMarker(geoCoordinates, _circleMapImage);
    mapMarker.drawOrder = drawOrder;

    _hereMapController.mapScene.addMapMarker(mapMarker);
    _mapMarkerList.add(mapMarker);
  }

  void _addFlatMarker3D(GeoCoordinates geoCoordinates) {
    // Place the files in the "assets" directory as specified in pubspec.yaml.
    // Adjust file name and path as appropriate for your project.
    // Note: The bottom of the plane is centered on the origin.
    String geometryFilePath = "assets/models/plane.obj";

    // The POI texture is a square, so we can easily wrap it onto the 2 x 2 plane model.
    String textureFilePath = "assets/models/poi_texture.png";

    // Optionally, consider to store the model for reuse (like we showed for MapImages above).
    MapMarker3DModel mapMarker3DModel =
        MapMarker3DModel.withTextureFilePath(geometryFilePath, textureFilePath);
    MapMarker3D mapMarker3D = MapMarker3D(geoCoordinates, mapMarker3DModel);
    // Scale marker. Note that we used a normalized length of 2 units in 3D space.
    mapMarker3D.scale = 50;

    _hereMapController.mapScene.addMapMarker3d(mapMarker3D);
    _mapMarker3DList.add(mapMarker3D);
  }

  void _addMapMarker3D(GeoCoordinates geoCoordinates) {
    // Place the files in the "assets" directory as specified in pubspec.yaml.
    // Adjust file name and path as appropriate for your project.
    String geometryFilePath = "assets/models/obstacle.obj";
    String textureFilePath = "assets/models/obstacle_texture.png";

    // Optionally, consider to store the model for reuse (like we showed for MapImages above).
    MapMarker3DModel mapMarker3DModel =
        MapMarker3DModel.withTextureFilePath(geometryFilePath, textureFilePath);
    MapMarker3D mapMarker3D = MapMarker3D(geoCoordinates, mapMarker3DModel);
    mapMarker3D.scale = 6;

    _hereMapController.mapScene.addMapMarker3d(mapMarker3D);
    _mapMarker3DList.add(mapMarker3D);
  }

  Future<Uint8List> _loadFileAsUint8List(String assetPathToFile) async {
    // The path refers to the assets directory as specified in pubspec.yaml.
    ByteData fileData = await rootBundle.load(assetPathToFile);
    return Uint8List.view(fileData.buffer);
  }

  void _setTapGestureHandler() {
    _hereMapController.gestures.tapListener =
        TapListener.fromLambdas(lambda_onTap: (Point2D touchPoint) {
      _pickMapMarker(touchPoint);
    });
  }

  void _pickMapMarker(Point2D touchPoint) {
    double radiusInPixel = 2;
    _hereMapController.pickMapItems(touchPoint, radiusInPixel,
        (pickMapItemsResult) {
      // Note that 3D map markers can't be picked yet. Only marker, polgon and polyline map items are pickable.
      List<MapMarker> mapMarkerList = pickMapItemsResult.markers;
      if (mapMarkerList.length == 0) {
        print("No map markers found.");
        return;
      }

      MapMarker topmostMapMarker = mapMarkerList.first;
      Metadata metadata = topmostMapMarker.metadata;
      if (metadata != null) {
        String message = metadata.getString("key_poi") ?? "No message found.";
        _showDialog("Map Marker picked", message);
        return;
      }

      _showDialog("Map Marker picked", "No metadata attached.");
    });
  }

  void _tiltMap() {
    MapCameraOrientationUpdate targetOrientation =
        MapCameraOrientationUpdate.withDefaults();
    targetOrientation.tilt = 60;
    _hereMapController.camera.setTargetOrientation(targetOrientation);
  }

  void _unTiltMap() {
    MapCameraOrientationUpdate targetOrientation =
        MapCameraOrientationUpdate.withDefaults();
    targetOrientation.tilt = 0;
    _hereMapController.camera.setTargetOrientation(targetOrientation);
  }

  GeoCoordinates _createRandomGeoCoordinatesAroundMapCenter() {
    GeoCoordinates centerGeoCoordinates =
        _hereMapController.viewToGeoCoordinates(Point2D(
            _hereMapController.viewportSize.width / 2,
            _hereMapController.viewportSize.height / 2));
    if (centerGeoCoordinates == null) {
      // Should never happen for center coordinates.
      throw Exception("CenterGeoCoordinates are null");
    }
    double lat = centerGeoCoordinates.latitude;
    double lon = centerGeoCoordinates.longitude;
    return GeoCoordinates(
        _getRandom(lat - 0.02, lat + 0.02), _getRandom(lon - 0.02, lon + 0.02));
  }

  double _getRandom(double min, double max) {
    return min + Random().nextDouble() * (max - min);
  }
}
