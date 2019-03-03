import 'dart:async';
import 'dart:convert';
import 'package:kamino/interface/settings/settings_prefs.dart' as settingsPref;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kamino/api/tmdb.dart' as tmdb;
import 'package:kamino/interface/smart_search/search_results.dart';
import 'package:kamino/interface/content/overview.dart';
import 'package:kamino/util/genre_names.dart' as genre;
import 'package:kamino/partials/poster_card.dart';
import 'package:kamino/models/content.dart';

class SmartSearch extends SearchDelegate<String> {
  bool _expandedSearchPref = false;

  SmartSearch() {
    settingsPref.getBoolPref("expandedSearch").then((data) {
      _expandedSearchPref = data;
    });
  }

  Future<List<SearchModel>> _fetchSearchList(String criteria) async {

    Future.delayed( new Duration(milliseconds: 500));

    List<SearchModel> _data = [];

    String url = "${tmdb.root_url}/search/"
        "multi${tmdb.defaultArguments}&"
        "query=$criteria&page=1&include_adult=false";

    http.Response res = await http.get(url);

    Map results = jsonDecode(res.body);
    //List<Map> _resultsList = [];

    var _resultsList = results["results"];

    if (_resultsList != null) {
      _resultsList.forEach((var element) {
        if (element["media_type"] != "person") {
          String name =
              element["name"] == null ? element["title"] : element["name"];
          _data.add(new SearchModel.fromJSON(element, 1));
        }
      });
    }
    return _data;
  }

  List<String> searchHistory = [];

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      primaryColor: Theme.of(context).cardColor,
      textTheme: TextTheme(
        title: TextStyle(
            fontFamily: "GlacialIndifference",
            fontSize: 19.0,
            color: Theme.of(context).primaryTextTheme.body1.color),
      ),
      textSelectionColor: Theme.of(context).textSelectionColor,
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    // actions for search bar
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = "";
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    // leading icon on the left of appbar
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    settingsPref.saveSearchHistory(query);
    return new SearchResult(query: query);
  }

  Widget _searchHistoryListView(AsyncSnapshot snapshot) {
    return ListView.builder(
        itemCount: snapshot.data.length,
        itemBuilder: (BuildContext context, int index) {
          return InkWell(
            onTap: () {
              showResults(context);
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 5.0, bottom: 5.0),
              child: InkWell(
                onTap: () {
                  query = snapshot.data[index].toString();
                  settingsPref.moveQueryToTop(snapshot.data[index]);
                  showResults(context);
                },
                child: ListTile(
                  leading: Icon(Icons.history),
                  title: RichText(
                    text: TextSpan(
                      text: snapshot.data[index],
                      style: TextStyle(
                          fontFamily: ("GlacialIndifference"),
                          fontSize: 19.0,
                          fontWeight: FontWeight.normal,
                          color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          );
        });
  }

  Widget _suggestionsPosterCard(AsyncSnapshot snapshot) {
    return ListView.builder(
      itemCount: snapshot.data.length,
      itemBuilder: (BuildContext context, int index) {
        return Padding(
          padding: const EdgeInsets.only(top: 5.0, left: 3.0, right: 3.0),
          child: InkWell(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ContentOverview(
                          contentId: snapshot.data[index].id,
                          contentType: snapshot.data[index].mediaType == "tv"
                              ? ContentType.TV_SHOW
                              : ContentType.MOVIE)));
            },
            child: PosterCard(
              isFav: false,
              background: snapshot.data[index].poster_path,
              name: snapshot.data[index].name,
              overview: snapshot.data[index].overview,
              ratings: snapshot.data[index].vote_average,
              elevation: 0.0,
              mediaType: snapshot.data[index].mediaType,
              genre: genre.getGenreNames(snapshot.data[index].genre_ids,
                  snapshot.data[index].mediaType),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchHistory() {
    return FutureBuilder<List<String>>(
        future: settingsPref.getSearchHistory(), // a previously-obtained Future<String> or null
        builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
              return Container();
            case ConnectionState.active:
            case ConnectionState.waiting:
              return Center(child: CircularProgressIndicator(
                valueColor: new AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor
                ),
              ));
            case ConnectionState.done:
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else if (snapshot.hasData) {
                return _searchHistoryListView(snapshot);
              }
            //return Text('Result: ${snapshot.data}');
          }
          return null; // unreachable
        });
  }

  Widget _simplifiedSuggestions(AsyncSnapshot snapshot) {
    return ListView.builder(
        itemCount: snapshot.data.length,
        itemBuilder: (BuildContext context, int index) {
          return InkWell(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ContentOverview(
                          contentId: snapshot.data[index].id,
                          contentType: snapshot.data[index].mediaType == "tv"
                              ? ContentType.TV_SHOW
                              : ContentType.MOVIE)));
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 2.0, bottom: 2.0),
              child: ListTile(
                leading: snapshot.data[index].mediaType == "tv"
                    ? Icon(Icons.live_tv)
                    : Icon(Icons.local_movies),
                title: RichText(
                  text: TextSpan(
                    text: _suggestionName(snapshot, index),
                    style: TextStyle(
                        fontFamily: ("GlacialIndifference"),
                        fontSize: 19.0,
                        fontWeight: FontWeight.normal,
                        color: Theme.of(context).primaryTextTheme.body1.color),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          );
        });
  }

  String _suggestionName(AsyncSnapshot snapshot, int index){

    if (snapshot.data[index].year != null && snapshot.data[index].year.length > 3){

      return snapshot.data[index].name +"  ("+snapshot.data[index].year.toString().substring(0,4)+")";
    }

    return snapshot.data[index].name;
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return query.isEmpty
        ? _buildSearchHistory()
        : FutureBuilder<List<SearchModel>>(
            future: _fetchSearchList(
                query), // a previously-obtained Future<String> or null
            builder: (BuildContext context,
                AsyncSnapshot<List<SearchModel>> snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.none:
                  return Container();
                case ConnectionState.active:
                case ConnectionState.waiting:
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor
                      ),
                    ));
                case ConnectionState.done:
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (snapshot.hasData) {
                    return _expandedSearchPref == false
                        ? _simplifiedSuggestions(snapshot)
                        : _suggestionsPosterCard(snapshot);
                  }
                //return Text('Result: ${snapshot.data}');
              }
              return null; // unreachable
            });
  }
}
