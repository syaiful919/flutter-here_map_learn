import 'package:flutter/material.dart';

import 'package:here_sdk/core.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/gestures.dart';

class GestureMap extends StatefulWidget {
  @override
  _GestureMapState createState() => _GestureMapState();
}

class _GestureMapState extends State<GestureMap> {
  BuildContext _context;

  @override
  Widget build(BuildContext context) {
    _context = context;

    return Scaffold(
      appBar: AppBar(
        title: Text('HERE SDK - Gesture Example'),
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
        GesturesExample(_context, hereMapController);
      } else {
        print("Map scene not loaded. MapError: " + error.toString());
      }
    });
  }
}

class GesturesExample {
  BuildContext _context;
  HereMapController _hereMapController;

  GesturesExample(BuildContext context, HereMapController hereMapController) {
    _context = context;
    _hereMapController = hereMapController;

    double distanceToEarthInMeters = 8000;
    _hereMapController.camera.lookAtPointWithDistance(
        GeoCoordinates(-6.3052470084405545, 106.75474866898688),
        distanceToEarthInMeters);

    _setTapGestureHandler();
    _setDoubleTapGestureHandler();
    _setTwoFingerTapGestureHandler();
    _setLongPressGestureHandler();

    _showDialog(
        "Gestures Example",
        "Shows Tap, DoubleTap, TwoFingerTap and LongPress gesture handling. " +
            "See log for details.");
  }

  void _setTapGestureHandler() {
    _hereMapController.gestures.tapListener =
        TapListener.fromLambdas(lambda_onTap: (Point2D touchPoint) {
      var geoCoordinates =
          _toString(_hereMapController.viewToGeoCoordinates(touchPoint));
      print('Tap at: $geoCoordinates');
    });
  }

  void _setDoubleTapGestureHandler() {
    _hereMapController.gestures.doubleTapListener =
        DoubleTapListener.fromLambdas(lambda_onDoubleTap: (Point2D touchPoint) {
      var geoCoordinates =
          _toString(_hereMapController.viewToGeoCoordinates(touchPoint));
      print('DoubleTap at: $geoCoordinates');
    });
  }

  void _setTwoFingerTapGestureHandler() {
    _hereMapController.gestures.twoFingerTapListener =
        TwoFingerTapListener.fromLambdas(
            lambda_onTwoFingerTap: (Point2D touchCenterPoint) {
      var geoCoordinates =
          _toString(_hereMapController.viewToGeoCoordinates(touchCenterPoint));
      print('TwoFingerTap at: $geoCoordinates');
    });
  }

  void _setLongPressGestureHandler() {
    _hereMapController.gestures.longPressListener =
        LongPressListener.fromLambdas(lambda_onLongPress:
            (GestureState gestureState, Point2D touchPoint) {
      var geoCoordinates =
          _toString(_hereMapController.viewToGeoCoordinates(touchPoint));

      if (gestureState == GestureState.begin) {
        print('LongPress detected at: $geoCoordinates');
      }

      if (gestureState == GestureState.update) {
        print('LongPress update at: $geoCoordinates');
      }

      if (gestureState == GestureState.end) {
        print('LongPress finger lifted at: $geoCoordinates');
      }
    });
  }

  String _toString(GeoCoordinates geoCoordinates) {
    return geoCoordinates.latitude.toString() +
        ", " +
        geoCoordinates.longitude.toString();
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
