import 'package:flutter/material.dart';
import 'package:here_ex/ui/pages/map/examples/camera_map.dart';
import 'package:here_ex/ui/pages/map/examples/gesture_map.dart';
import 'package:here_ex/ui/pages/map/examples/hello_map.dart';
import 'package:here_ex/ui/pages/map/examples/marker_map.dart';

class MapPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MarkerMap();
  }
}
