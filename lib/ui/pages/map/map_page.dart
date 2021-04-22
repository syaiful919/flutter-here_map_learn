import 'package:flutter/material.dart';

import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/core.dart';

class MapPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return HereMap(onMapCreated: _onMapCreated);
  }

  void _onMapCreated(HereMapController hereMapController) {
    hereMapController.mapScene.loadSceneForMapScheme(MapScheme.normalDay,
        (MapError error) {
      if (error != null) {
        print('Map scene not loaded. MapError: ${error.toString()}');
        return;
      }

      const double distanceToEarthInMeters = 2000;
      hereMapController.camera.lookAtPointWithDistance(
          GeoCoordinates(-6.3052470084405545, 106.75474866898688),
          distanceToEarthInMeters);
    });
  }
}
