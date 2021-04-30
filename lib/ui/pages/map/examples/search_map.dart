import 'package:flutter/material.dart';

import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/core.errors.dart';
import 'package:here_sdk/gestures.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/search.dart';

class SearchMap extends StatefulWidget {
  @override
  _SearchMapState createState() => _SearchMapState();
}

class _SearchMapState extends State<SearchMap> {
  BuildContext _context;

  SearchExample _searchExample;

  @override
  Widget build(BuildContext context) {
    _context = context;
    return Scaffold(
      appBar: AppBar(
        title: Text('HERE SDK - Search Example'),
      ),
      body: Stack(
        children: [
          HereMap(onMapCreated: _onMapCreated),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              button('Search', _searchButtonClicked),
              button('Geocoding', _geocodeAnAddressButtonClicked),
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
        _searchExample = SearchExample(_showDialog, hereMapController);
      } else {
        print("Map scene not loaded. MapError: " + error.toString());
      }
    });
  }

  void _searchButtonClicked() {
    _searchExample.searchButtonClicked();
  }

  void _geocodeAnAddressButtonClicked() {
    _searchExample.geocodeAnAddressButtonClicked();
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

class SearchResultMetadata implements CustomMetadataValue {
  Place searchResult;

  SearchResultMetadata(Place place) {
    searchResult = place;
  }

  @override
  String getTag() {
    return "SearchResult Metadata";
  }

  @override
  void release() {
    searchResult.release();
  }
}

// A callback to notify the hosting widget.
typedef ShowDialogFunction = void Function(String title, String message);

class SearchExample {
  HereMapController _hereMapController;
  MapCamera _camera;
  MapImage _poiMapImage;
  List<MapMarker> _mapMarkerList = [];
  SearchEngine _searchEngine;
  ShowDialogFunction _showDialog;

  SearchExample(
      Function showDialogCallback, HereMapController hereMapController) {
    _showDialog = showDialogCallback;
    _hereMapController = hereMapController;
    _camera = _hereMapController.camera;

    double distanceToEarthInMeters = 10000;
    _camera.lookAtPointWithDistance(
        GeoCoordinates(52.520798, 13.409408), distanceToEarthInMeters);

    try {
      _searchEngine = new SearchEngine();
    } on InstantiationException {
      throw Exception("Initialization of SearchEngine failed.");
    }

    _setTapGestureHandler();
    _setLongPressGestureHandler();

    _showDialog("Note",
        "Long press on map to get the address for that position using reverse geocoding.");
  }

  Future<void> searchButtonClicked() async {
    // Search for "Pizza" and show the results on the map.
    _searchExample();

    // Search for auto suggestions and log the results to the console.
    _autoSuggestExample();
  }

  Future<void> geocodeAnAddressButtonClicked() async {
    // Search for the location that belongs to an address and show it on the map.
    _geocodeAnAddress();
  }

  void _searchExample() {
    String searchTerm = "Pizza";
    print("Searching in viewport for: " + searchTerm);
    _searchInViewport(searchTerm);
  }

  void _geocodeAnAddress() {
    // Move map near to expected location.
    GeoCoordinates geoCoordinates = new GeoCoordinates(52.537931, 13.384914);
    _camera.flyTo(geoCoordinates);

    String queryString = "Invalidenstraße 116, Berlin";

    print(
        "Finding locations for: $queryString. Tap marker to see the coordinates.");

    _geocodeAddressAtLocation(queryString, geoCoordinates);
  }

  void _setTapGestureHandler() {
    _hereMapController.gestures.tapListener =
        TapListener.fromLambdas(lambda_onTap: (Point2D touchPoint) {
      _pickMapMarker(touchPoint);
    });
  }

  void _setLongPressGestureHandler() {
    _hereMapController.gestures.longPressListener =
        LongPressListener.fromLambdas(lambda_onLongPress:
            (GestureState gestureState, Point2D touchPoint) {
      if (gestureState == GestureState.begin) {
        GeoCoordinates geoCoordinates =
            _hereMapController.viewToGeoCoordinates(touchPoint);
        if (geoCoordinates == null) {
          return;
        }
        _addPoiMapMarker(geoCoordinates);
        _getAddressForCoordinates(geoCoordinates);
      }
    });
  }

  Future<void> _getAddressForCoordinates(GeoCoordinates geoCoordinates) async {
    int maxItems = 1;
    SearchOptions reverseGeocodingOptions =
        new SearchOptions(LanguageCode.enGb, maxItems);

    _searchEngine.searchByCoordinates(geoCoordinates, reverseGeocodingOptions,
        (SearchError searchError, List<Place> list) async {
      if (searchError != null) {
        _showDialog("Reverse geocoding", "Error: " + searchError.toString());
        return;
      }

      // If error is null, list is guaranteed to be not empty.
      _showDialog("Reverse geocoded address:", list.first.address.addressText);
    });
  }

  void _pickMapMarker(Point2D touchPoint) {
    double radiusInPixel = 2;
    _hereMapController.pickMapItems(touchPoint, radiusInPixel,
        (pickMapItemsResult) {
      List<MapMarker> mapMarkerList = pickMapItemsResult.markers;
      if (mapMarkerList.length == 0) {
        print("No map markers found.");
        return;
      }

      MapMarker topmostMapMarker = mapMarkerList.first;
      Metadata metadata = topmostMapMarker.metadata;
      if (metadata != null) {
        CustomMetadataValue customMetadataValue =
            metadata.getCustomValue("key_search_result");
        if (customMetadataValue != null) {
          SearchResultMetadata searchResultMetadata =
              customMetadataValue as SearchResultMetadata;
          String title = searchResultMetadata.searchResult.title;
          String vicinity =
              searchResultMetadata.searchResult.address.addressText;
          _showDialog(
              "Picked Search Result", title + ". Vicinity: " + vicinity);
          return;
        }
      }

      double lat = topmostMapMarker.coordinates.latitude;
      double lon = topmostMapMarker.coordinates.longitude;
      _showDialog("Picked Map Marker", "Geographic coordinates: $lat, $lon.");
    });
  }

  Future<void> _searchInViewport(String queryString) async {
    _clearMap();

    GeoBox viewportGeoBox = _getMapViewGeoBox();
    TextQuery query = TextQuery.withBoxArea(queryString, viewportGeoBox);

    int maxItems = 30;
    SearchOptions searchOptions = SearchOptions(LanguageCode.enUs, maxItems);

    _searchEngine.searchByText(query, searchOptions,
        (SearchError searchError, List<Place> list) async {
      if (searchError != null) {
        _showDialog("Search", "Error: " + searchError.toString());
        return;
      }

      // If error is null, list is guaranteed to be not empty.
      int listLength = list.length;
      _showDialog("Search for $queryString",
          "Results: $listLength. Tap marker to see details.");

      // Add new marker for each search result on map.
      for (Place searchResult in list) {
        Metadata metadata = Metadata();
        metadata.setCustomValue(
            "key_search_result", SearchResultMetadata(searchResult));
        // Note: getGeoCoordinates() may return null only for Suggestions.
        addPoiMapMarker(searchResult.geoCoordinates, metadata);
      }
    });
  }

  Future<void> _autoSuggestExample() async {
    GeoCoordinates centerGeoCoordinates = _getMapViewCenter();
    int maxItems = 5;
    SearchOptions searchOptions = SearchOptions(LanguageCode.enUs, maxItems);

    // Simulate a user typing a search term.
    _searchEngine.suggest(
        TextQuery.withAreaCenter(
            "p", // User typed "p".
            centerGeoCoordinates),
        searchOptions, (SearchError searchError, List<Suggestion> list) async {
      _handleSuggestionResults(searchError, list);
    });

    _searchEngine.suggest(
        TextQuery.withAreaCenter(
            "pi", // User typed "pi".
            centerGeoCoordinates),
        searchOptions, (SearchError searchError, List<Suggestion> list) async {
      _handleSuggestionResults(searchError, list);
    });

    _searchEngine.suggest(
        TextQuery.withAreaCenter(
            "piz", // User typed "piz".
            centerGeoCoordinates),
        searchOptions, (SearchError searchError, List<Suggestion> list) async {
      _handleSuggestionResults(searchError, list);
    });
  }

  void _handleSuggestionResults(
      SearchError searchError, List<Suggestion> list) {
    if (searchError != null) {
      print("Autosuggest Error: " + searchError.toString());
      return;
    }

    // If error is null, list is guaranteed to be not empty.
    int listLength = list.length;
    print("Autosuggest results: $listLength.");

    for (Suggestion autosuggestResult in list) {
      String addressText = "Not a place.";
      Place place = autosuggestResult.place;
      if (place != null) {
        addressText = place.address.addressText;
      }

      print("Autosuggest result: " +
          autosuggestResult.title +
          " addressText: " +
          addressText);
    }
  }

  Future<void> _geocodeAddressAtLocation(
      String queryString, GeoCoordinates geoCoordinates) async {
    _clearMap();

    AddressQuery query =
        AddressQuery.withAreaCenter(queryString, geoCoordinates);

    int maxItems = 30;
    SearchOptions searchOptions = SearchOptions(LanguageCode.deDe, maxItems);

    _searchEngine.searchByAddress(query, searchOptions,
        (SearchError searchError, List<Place> list) async {
      if (searchError != null) {
        _showDialog("Geocoding", "Error: " + searchError.toString());
        return;
      }

      String locationDetails = "";

      for (Place geocodingResult in list) {
        // Note: getGeoCoordinates() may return null only for Suggestions.
        GeoCoordinates geoCoordinates = geocodingResult.geoCoordinates;
        Address address = geocodingResult.address;
        locationDetails = address.addressText +
            ". GeoCoordinates: " +
            geoCoordinates.latitude.toString() +
            ", " +
            geoCoordinates.longitude.toString();

        print("GeocodingResult: " + locationDetails);
        _addPoiMapMarker(geoCoordinates);
      }

      int itemsCount = list.length;
      _showDialog("Geocoding result: $itemsCount", locationDetails);
    });
  }

  Future<MapMarker> _addPoiMapMarker(GeoCoordinates geoCoordinates) async {
    // Reuse existing MapImage for new map markers.
    if (_poiMapImage == null) {
      Uint8List imagePixelData = await _loadFileAsUint8List('poi.png');
      _poiMapImage =
          MapImage.withPixelDataAndImageFormat(imagePixelData, ImageFormat.png);
    }

    MapMarker mapMarker = MapMarker(geoCoordinates, _poiMapImage);
    _hereMapController.mapScene.addMapMarker(mapMarker);
    _mapMarkerList.add(mapMarker);

    return mapMarker;
  }

  Future<Uint8List> _loadFileAsUint8List(String fileName) async {
    // The path refers to the assets directory as specified in pubspec.yaml.
    ByteData fileData = await rootBundle.load('assets/' + fileName);
    return Uint8List.view(fileData.buffer);
  }

  Future<void> addPoiMapMarker(
      GeoCoordinates geoCoordinates, Metadata metadata) async {
    MapMarker mapMarker = await _addPoiMapMarker(geoCoordinates);
    mapMarker.metadata = metadata;
  }

  GeoCoordinates _getMapViewCenter() {
    return _camera.state.targetCoordinates;
  }

  GeoBox _getMapViewGeoBox() {
    GeoBox geoBox = _camera.boundingBox;
    if (geoBox == null) {
      throw Exception("GeoBox creation failed, corners are null.");
    }
    return geoBox;
  }

  void _clearMap() {
    _mapMarkerList.forEach((mapMarker) {
      _hereMapController.mapScene.removeMapMarker(mapMarker);
    });
    _mapMarkerList.clear();
  }
}
