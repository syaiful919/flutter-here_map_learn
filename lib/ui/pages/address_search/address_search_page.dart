import 'package:flutter/material.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/core.errors.dart';
import 'package:here_sdk/search.dart';

class SearchSuggestionModel {
  GeoCoordinates coordinates;
  String title;

  SearchSuggestionModel({
    this.title,
    this.coordinates,
  });
}

class AddressSearchPage extends StatefulWidget {
  @override
  _AddressSearchPageState createState() => _AddressSearchPageState();
}

class _AddressSearchPageState extends State<AddressSearchPage> {
  TextEditingController _searchCon = TextEditingController();
  List<SearchSuggestionModel> _searchResult = [];

  GeoCoordinates _currentCoordinate;

  SearchEngine _searchEngine;

  @override
  void initState() {
    super.initState();
    getCurrentCoordinate();
    initSeacrhEngine();
  }

  void initSeacrhEngine() {
    try {
      _searchEngine = new SearchEngine();
    } on InstantiationException {
      print(">>> Initialization of SearchEngine failed.");
    }
  }

  void getCurrentCoordinate() {
    _currentCoordinate =
        GeoCoordinates(-6.3052470084405545, 106.75474866898688);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            TextField(
              controller: _searchCon,
              onChanged: (val) {
                onSearch(val);
                setState(() {});
              },
            ),
            SizedBox(height: 8),
            if (_searchResult.isNotEmpty)
              ListView.builder(
                itemBuilder: (_, i) => _SearchItem(
                  suggestion: _searchResult[i],
                ),
                itemCount: _searchResult.length,
                shrinkWrap: true,
              )
          ],
        ),
      ),
    );
  }

  onSearch(String val) {
    int maxItems = 5;
    SearchOptions searchOptions = SearchOptions(LanguageCode.idId, maxItems);

    _searchEngine.suggest(
      TextQuery.withAreaCenter(val, _currentCoordinate),
      searchOptions,
      (SearchError searchError, List<Suggestion> list) async {
        if (searchError != null) {
          print("Autosuggest Error: " + searchError.toString());
          return;
        }

        // If error is null, list is guaranteed to be not empty.
        int listLength = list.length;
        print("Autosuggest results: $listLength.");

        _searchResult.clear();

        for (Suggestion autosuggestResult in list) {
          String addressText = "Not a place.";
          GeoCoordinates coordinates;
          Place place = autosuggestResult.place;
          if (place != null) {
            addressText = place.address.addressText;
            coordinates = place.geoCoordinates;
          }

          _searchResult.add(SearchSuggestionModel(
              title: addressText, coordinates: coordinates));

          print(
              "Autosuggest result: ${autosuggestResult.title}, addressText: $addressText, (${coordinates.latitude}, ${coordinates.longitude})");
        }
      },
    );
  }
}

class _SearchItem extends StatelessWidget {
  final SearchSuggestionModel suggestion;
  const _SearchItem({
    Key key,
    this.suggestion,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      child: Text(suggestion.title),
    );
  }
}
