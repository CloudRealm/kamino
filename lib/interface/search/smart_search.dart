import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kamino/animation/transition.dart';
import 'package:kamino/external/ExternalService.dart';
import 'package:kamino/external/api/tmdb.dart';
import 'package:kamino/generated/i18n.dart';
import 'package:kamino/interface/search/search_results.dart';
import 'package:kamino/interface/content/overview.dart';
import 'package:kamino/ui/elements.dart';
import 'package:kamino/util/database_helper.dart';
import 'package:kamino/models/content.dart';

class SmartSearch extends SearchDelegate<String> {

  final AsyncMemoizer<List<String>> _memoizer = AsyncMemoizer();

  Future<List<SearchModel>> _fetchSearchList(BuildContext context, String criteria) async {
    List<SearchModel> _data = [];

    String url = "${TMDB.ROOT_URL}/search/"
        "multi${Service.get<TMDB>().getDefaultArguments(context)}&"
        "query=$criteria&page=1&include_adult=false";

    http.Response res = await http.get(url);

    Map results = jsonDecode(res.body);

    var _resultsList = results["results"];

    if (_resultsList != null) {
      _resultsList.forEach((var element) {
        if (element["media_type"] != "person") {
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
      primaryColor: Theme.of(context).backgroundColor,
      textTheme: TextTheme(
        title: TextStyle(
          fontFamily: 'GlacialIndifference',
          fontSize: 19.0,
          color: Colors.white
        ),
      ),
      // These values are not yet used.
      // We're waiting on https://github.com/flutter/flutter/pull/30388
      // We adjusted this in the application theme instead.
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          color: Colors.grey[400]
        )
      ),
      cursorColor: Theme.of(context).primaryColor
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
    if(query == null || query.isEmpty) return Container();

    DatabaseHelper.writeToSearchHistory(query);
    return SearchResultView(query: query);
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
                  query = snapshot.data[index];
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

  Widget _buildSearchHistory() {
    return FutureBuilder<List<String>>(
      future: _memoizer.runOnce(DatabaseHelper.getSearchHistory),
      builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.active:
          case ConnectionState.waiting:
            return Container();
          case ConnectionState.done:
            if (snapshot.hasError) {
              return ErrorLoadingMixin(
                errorMessage: snapshot.error.toString(),
              );
            }

            return _searchHistoryListView(snapshot);
        }
        return null;
      }
    );
  }

  Widget _simplifiedSuggestions(AsyncSnapshot snapshot) {
    return ListView.builder(
        itemCount: snapshot.data.length,
        itemBuilder: (BuildContext context, int index) {
          return InkWell(
            onTap: () {
              Navigator.push(
                  context,
                  ApolloTransitionRoute(
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
      return "${snapshot.data[index].name} (${snapshot.data[index].year.toString().substring(0,4)})";
    }

    return snapshot.data[index].name;
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      body: query.isEmpty
          ? _buildSearchHistory()
          : FutureBuilder<List<SearchModel>>(
          future: _fetchSearchList(context, query), // a previously-obtained Future<String> or null
          builder: (BuildContext context,
              AsyncSnapshot<List<SearchModel>> snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.none:
              case ConnectionState.active:
              case ConnectionState.waiting:
                return Container();

              case ConnectionState.done:
                if (snapshot.hasError) {

                  if(snapshot.error is SocketException
                      || snapshot.error is HttpException) return OfflineMixin();

                  return ErrorLoadingMixin(errorMessage: S.of(context).error_loading_search);

                } else if (snapshot.hasData) {
                  return _simplifiedSuggestions(snapshot);
                }
            //return Text('Result: ${snapshot.data}');
            }
            return null; // unreachable
          }),
    );
  }

}
