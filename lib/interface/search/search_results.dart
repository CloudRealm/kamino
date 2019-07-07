import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:kamino/animation/transition.dart';
import 'package:kamino/external/ExternalService.dart';
import 'package:kamino/external/api/tmdb.dart';
import 'package:kamino/partials/content_card.dart';
import 'package:kamino/ui/elements.dart';
import 'package:kamino/ui/loading.dart';
import 'package:kamino/util/genre.dart' as genre;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kamino/models/content.dart';
import 'package:kamino/partials/content_poster.dart';
import 'package:kamino/util/database_helper.dart';
import 'package:kamino/interface/content/overview.dart';
import 'package:kamino/util/settings.dart';

class SearchResultView extends StatefulWidget {

  final String query;

  SearchResultView({Key key, @required this.query}) : super(key: key);

  @override
  _SearchResultViewState createState() => new _SearchResultViewState();

}

class _SearchResultViewState extends State<SearchResultView> {

  ScrollController controller;
  ScrollController controllerList;

  Widget _override;
  final _pageController = PageController(initialPage: 1);

  int _currentPages = 1;
  int total_pages = 1;

  bool _expandedSearchPref = false;
  bool _hideUnreleasedPartialContent = false;

  List<SearchModel> _results = [];
  List<int> _favIDs = [];

  Future<List<SearchModel>> _getContent(String query, int pageNumber) async {
    hasLoaded = false;

    List<SearchModel> _data = [];
    Map _temp;

    String url = "${TMDB.ROOT_URL}/search/"
        "multi${Service.get<TMDB>().getDefaultArguments(context)}&"
        "query=${query.replaceAll(" ", "+")}&page=$pageNumber&include_adult=false";

    http.Response _res = await http.get(url);
    _temp = jsonDecode(_res.body);

    if (_temp["results"] != null) {
      total_pages = _temp["total_pages"];
      int resultsCount = _temp["results"].length;

      for(int x = 0; x < resultsCount; x++) {
        _data.add(SearchModel.fromJSON(
            _temp["results"][x], total_pages));
      }
    }

    hasLoaded = true;
    return _data;
  }

  _openContentScreen(BuildContext context, int contentId, String mediaType) {
    if (mediaType == "tv") {
      Navigator.push(
          context,
          ApolloTransitionRoute(
              builder: (context) =>
                  ContentOverview(
                      contentId: contentId,
                      contentType: ContentType.TV_SHOW )
          )
      );
    } else {
      Navigator.push(
          context,
          ApolloTransitionRoute(
              builder: (context) =>
                  ContentOverview(
                      contentId: contentId,
                      contentType: ContentType.MOVIE )
          )
      );
    }
  }

  bool hasLoaded;

  @override
  void initState() {
    hasLoaded = false;

    (() async {

      _expandedSearchPref = await (Settings.detailedContentInfoEnabled as Future);
      _hideUnreleasedPartialContent = await (Settings.hideUnreleasedPartialContent as Future);

    })().then((_){
      DatabaseHelper.getAllFavoriteIds().then((data){
        _favIDs = data;
      });

      controller = new ScrollController()..addListener(_scrollListener);
      controllerList = new ScrollController()..addListener(_scrollListenerList);

      _getContent(widget.query, _currentPages).then((data) {
        setState(() {
          _results = data;
        });
      }).catchError((ex){
        if(ex is SocketException
            || ex is HttpException) {
          _override = OfflineMixin();
          return;
        }

        _override = ErrorLoadingMixin(errorMessage: "Well this is awkward... An error occurred whilst loading search results.");
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      body: Builder(builder: (BuildContext context){
        if(_override != null) return _override;

        if(_results.length < 1){
          if(widget.query == null || widget.query.isEmpty) return Container();

          if(!hasLoaded) return Center(
              child: ApolloLoadingSpinner()
          );

          return Container(
            child: Center(
              child: Text("No results found!", style: TextStyle(
                  fontSize: 20
              )),
            ),
          );
        }

        return Scrollbar(
          child: _expandedSearchPref == false ? _gridPage() : _listPage(),
        );
      })
    );
  }

  ///
  /// This method determines whether a result item should be ignored,
  /// i.e. because it lacks required metadata.
  ///
  bool detectShouldYield(SearchModel resultItem){

    if(!_hideUnreleasedPartialContent) return false;

    // Yield if data is missing.
    if([
      resultItem.year,
      resultItem.backdrop_path,
      resultItem.poster_path
    ].contains(null)) return true;

    // Yield if released in the future.
    try {
      return (DateTime.parse(resultItem.year).compareTo(DateTime.now()) > 0);
    }catch(ex){
      // Invalid date format
      return false;
    }
  }

  Widget _listPage(){
    List<SearchModel> resultsList = _results.where(
            (SearchModel model) => !detectShouldYield(model)
    ).toList(growable: false);

    return Padding(
      padding: const EdgeInsets.only(top:5.0),
      child: ListView.builder(
        itemCount: resultsList.length,
        controller: controllerList,
        itemBuilder: (BuildContext context, int index){
          return ContentCard(
            id: resultsList[index].id,
            backdrop: resultsList[index].backdrop_path,
            year: resultsList[index].year,
            name: resultsList[index].name,
            genre: genre.resolveGenreNames(resultsList[index].genre_ids, resultsList[index].mediaType),
            mediaType: resultsList[index].mediaType,
            ratings: resultsList[index].vote_average,
            overview: resultsList[index].overview,
            elevation: 5.0,
            onTap: () => _openContentScreen(context, resultsList[index].id, resultsList[index].mediaType),
            isFavorite: _favIDs.contains(resultsList[index].id),
          );
        },
      ),
    );
  }

  Widget _gridPage(){
    List<SearchModel> resultsList = _results.where(
            (SearchModel model) => !detectShouldYield(model)
    ).toList(growable: false);

    return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints){
      double idealWidth = 150;
      double spacing = 10.0;

      return GridView.builder(
          padding: EdgeInsets.symmetric(vertical: 20, horizontal: 15),
          controller: controller,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: (constraints.maxWidth / idealWidth).round(),
            childAspectRatio: 0.67,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
          ),
          itemCount: resultsList.length,
          itemBuilder: (BuildContext context, int index){
            return ContentPoster(
              background: resultsList[index].poster_path,
              name: resultsList[index].name,
              releaseDate: resultsList[index].year,
              mediaType: resultsList[index].mediaType,
              onTap: () => _openContentScreen(context, resultsList[index].id, resultsList[index].mediaType),
            );
          }
      );
    });
  }

  void _scrollListener(){

    if (controller.offset >= controller.position.extentAfter) {

      //check that you haven't already loaded the last page
      if (_currentPages < total_pages){

        //load the next page
        _currentPages = _currentPages + 1;

        _getContent(widget.query, _currentPages).then((data){

          setState(() {
            _results = _results + data;
          });

        });
      }
    }
  }
  void _scrollListenerList(){
    if (controllerList.offset >= controllerList.position.extentAfter) {

      //check that you haven't already loaded the last page
      if (_currentPages < total_pages){

        //load the next page
        _currentPages = _currentPages + 1;

        _getContent(widget.query, _currentPages).then((data){

          setState(() {
            _results = _results + data;
          });

        });
      }
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    controller.removeListener(_scrollListener);
    controllerList.removeListener(_scrollListenerList);
    super.dispose();
  }


}

class SearchModel {

  final String name, poster_path, backdrop_path, year, mediaType, overview;
  final int id, vote_count, page;
  final List genre_ids;
  final int vote_average;

  SearchModel.fromJSON(Map json, int pageCount)
      : name = json["name"] == null ? json["title"] : json["name"],
        poster_path = json["poster_path"],
        backdrop_path = json["backdrop_path"],
        id = json["id"],
        vote_average = json["vote_average"] != null ? (json["vote_average"]).round() : 0,
        overview = json["overview"],
        genre_ids = json["genre_ids"],
        mediaType = json["media_type"],
        page = pageCount,
        year = json["first_air_date"] == null ?
        json["release_date"] : json["first_air_date"],
        vote_count = json["vote_count"];
}