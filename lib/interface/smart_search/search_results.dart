import 'dart:async';
import 'dart:convert';
import 'package:kamino/generated/i18n.dart';
import 'package:kamino/util/genre_names.dart' as genre;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kamino/api/tmdb.dart';
import 'package:kamino/models/content.dart';
import 'package:kamino/ui/ui_constants.dart';
import 'package:kamino/partials/result_card.dart';
import 'package:kamino/partials/content_poster.dart';
import 'package:kamino/util/databaseHelper.dart' as databaseHelper;
import 'package:kamino/interface/content/overview.dart';
import 'package:kamino/util/settings.dart';

class SearchResult extends StatefulWidget{
  final String query;

  SearchResult({Key key, @required this.query}) : super(key: key);

  @override
  _SearchResultState createState() => new _SearchResultState();

}

class _SearchResultState extends State<SearchResult> {

  ScrollController controller;
  ScrollController controllerList;

  final _pageController = PageController(initialPage: 1);

  int _currentPages = 1;
  int total_pages = 1;
  bool _expandedSearchPref = false;

  List<SearchModel> _results = [];
  List<int> _favIDs = [];

  Future<List<SearchModel>> _getContent(String query, int pageNumber) async {

    List<SearchModel> _data = [];
    Map _temp;

    String url = "${TMDB.ROOT_URL}/search/"
        "multi${TMDB.defaultArguments}&"
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

    return _data;
  }

  _openContentScreen(BuildContext context, int index) {
    if (_results[index].mediaType == "tv") {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  ContentOverview(
                      contentId: _results[index].id,
                      contentType: ContentType.TV_SHOW )
          )
      );
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  ContentOverview(
                      contentId: _results[index].id,
                      contentType: ContentType.MOVIE )
          )
      );
    }
  }

  @override
  void initState() {
    (Settings.detailedContentInfoEnabled as Future).then((data) => setState(() => _expandedSearchPref = data));

    controller = new ScrollController()..addListener(_scrollListener);
    controllerList = new ScrollController()..addListener(_scrollListenerList);

    databaseHelper.getAllFavIDs().then((data){

      _favIDs = data;
    });

    _getContent(widget.query, _currentPages).then((data){

      setState(() {
        _results = data;
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if(_results.length < 1) return Container(
      child: Center(
        child: Text("No results found!", style: TextStyle(
          fontSize: 20
        )),
      ),
    );

    return Scrollbar(
      child: _expandedSearchPref == false ? _gridPage() : _listPage(),
    );
  }

  Widget _listPage(){
    return Padding(
      padding: const EdgeInsets.only(top:5.0),
      child: ListView.builder(
        itemCount: _results.length,
        controller: controllerList,
        itemBuilder: (BuildContext context, int index){
          return InkWell(
            onTap: () => _openContentScreen(context, index),
            onLongPress: (){
              addFavoritePrompt(
                  context, _results[index].name, _results[index].id,
                  TMDB.IMAGE_CDN + _results[index].poster_path,
                  _results[index].year, _results[index].mediaType);
            },
            splashColor: Colors.white,
            child: ResultCard(
              background: _results[index].poster_path,
              name: _results[index].name,
              genre: genre.getGenreNames(_results[index].genre_ids,_results[index].mediaType),
              mediaType: _results[index].mediaType,
              ratings: _results[index].vote_average,
              overview: _results[index].overview,
              isFav: _favIDs.contains(_results[index].id),
              elevation: 5.0,
            ),
          );
        },
      ),
    );
  }

  Widget _gridPage(){
    return Padding(
      padding: const EdgeInsets.only(top: 5.0),
      child: GridView.builder(
          controller: controller,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.76
          ),

          itemCount: _results.length,

          itemBuilder: (BuildContext context, int index){
            return InkWell(
              onTap: () => _openContentScreen(context, index),
              onLongPress: (){
                addFavoritePrompt(
                    context, _results[index].name, _results[index].id,
                    TMDB.IMAGE_CDN + _results[index].poster_path,
                    _results[index].year, _results[index].mediaType);
              },
              splashColor: Colors.white,
              child: ContentPoster(
                background: _results[index].poster_path,
                name: _results[index].name,
                releaseDate: _results[index].year,
                mediaType: _results[index].mediaType,
                isFav: _favIDs.contains(_results[index].id),
              ),
            );
          }
      ),
    );
  }

  void _scrollListener(){

    print("current page is $_currentPages");

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

Widget _nothingFoundScreen(BuildContext context) {
  const _paddingWeight = 18.0;

  return Center(
    child: Padding(
      padding:
      const EdgeInsets.only(left: _paddingWeight, right: _paddingWeight),
      child: Text(
        S.of(context).no_results_found,
        maxLines: 3,
        style: TextStyle(
            fontSize: 22.0,
            fontFamily: 'GlacialIndifference',
            color: Theme.of(context).primaryTextTheme.body1.color),
      ),
    ),
  );
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