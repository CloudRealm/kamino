import 'package:flutter/material.dart';
import 'package:kamino/animation/transition.dart';
import 'package:kamino/external/ExternalService.dart';
import 'package:kamino/external/api/tmdb.dart';
import 'package:kamino/generated/i18n.dart';
import 'dart:async';
import 'package:kamino/models/content.dart';
import 'package:kamino/interface/content/overview.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kamino/partials/content_card.dart';
import 'package:kamino/util/database_helper.dart';
import 'package:kamino/util/genre.dart' as genre;
import 'package:kamino/partials/content_poster.dart';
import 'package:kamino/ui/interface.dart';
import 'package:kamino/util/settings.dart';

class CuratedSearch extends StatefulWidget{

  final String contentType, listName;
  final int listID;

  CuratedSearch(
      {Key key, @required this.contentType, @required this.listID,
        @required this.listName}) : super(key: key);

  @override
  _CuratedSearchState createState() => new _CuratedSearchState();
}

class _CuratedSearchState extends State<CuratedSearch>{

  int _currentPages = 1;
  ScrollController controller;

  List<DiscoverModel> _results = [];
  List<int> _favIDs = [];
  bool _expandedSearchPref = false;
  int totalPages = 1;

  @override
  void initState() {

    (Settings.detailedContentInfoEnabled as Future).then((data){ if(mounted) setState(() => _expandedSearchPref = data); });

    controller = new ScrollController()..addListener(_scrollListener);

    String _contentType = widget.contentType;
    String _genreID = widget.listID.toString();

    DatabaseHelper.getAllFavoriteIds().then((data){
      _favIDs = data;
    });

    _getContent(_contentType, _genreID).then((data){
      _results = data;
      if(mounted) setState(() {});
    });

    super.initState();
  }

  //get data from the api
  Future<List<DiscoverModel>> _getContent(contentType, listID) async {

    List<DiscoverModel> _data = [];
    Map _temp;

    String url = "https://api.themoviedb.org/4/list/$listID${Service.get<TMDB>().getDefaultArguments(context)}&"
        /*"sort_by=popularity.desc"*/ "&include_adult=false"
        "&include_video=false&page=${_currentPages.toString()}";

    http.Response _res = await http.get(url);
    _temp = jsonDecode(_res.body);

    if (_temp["results"] != null) {
      totalPages = _temp["total_pages"];
      int resultsCount = _temp["results"].length;

      for(int x = 0; x < resultsCount; x++) {
        _data.add(DiscoverModel.fromJSON(
            _temp["results"][x], totalPages, contentType));
      }
    }

    return _data;
  }

  _openContentScreen(BuildContext context, int index) {

    if (_results[index].mediaType == "tv") {
      Navigator.push(
          context,
          ApolloTransitionRoute(
              builder: (context) =>
                  ContentOverview(
                      contentId: _results[index].id,
                      contentType: ContentType.TV_SHOW )
          )
      );
    } else {
      Navigator.push(
          context,
          ApolloTransitionRoute(
              builder: (context) =>
                  ContentOverview(
                      contentId: _results[index].id,
                      contentType: ContentType.MOVIE )
          )
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    TextStyle _glacialFont = TextStyle(
        fontFamily: "GlacialIndifference");

    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: new AppBar(
        title: Text(widget.listName, style: _glacialFont,),
        centerTitle: true,
        backgroundColor: Theme.of(context).backgroundColor,
        elevation: 5.0,
        actions: <Widget>[
          Interface.generateSearchIcon(context),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {

          await Future.delayed(Duration(seconds: 2));
          DatabaseHelper.getAllFavoriteIds().then((data){
            if(mounted) setState(() {
              _favIDs = data;
            });
          });
        },
        child: Scrollbar(
          child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints)
              => _expandedSearchPref == false ? _gridResults(context, constraints) : _listResult()
          ),
        ),
      ),
    );
  }

  Widget _gridResults(BuildContext context, BoxConstraints constraints){
    double idealWidth = 150;
    double spacing = 10.0;

    return GridView.builder(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        controller: controller,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: (constraints.maxWidth / idealWidth).round(),
          childAspectRatio: 0.67,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
        ),

        itemCount: _results.length,

        itemBuilder: (BuildContext context, int index){
          return ContentPoster(
            background: _results[index].poster_path,
            name: _results[index].name,
            releaseDate: _results[index].year,
            mediaType: _results[index].mediaType,
            onTap: () => _openContentScreen(context, index),
          );
        }
    );
  }

  Widget _listResult(){
    return ListView.builder(
      itemCount: _results.length,
      controller: controller,

      itemBuilder: (BuildContext context, int index){
        return ContentCard(
          id: _results[index].id,
          onTap: () => _openContentScreen(context, index),
          backdrop: _results[index].backdrop_path,
          year: _results[index].year,
          name: _results[index].name,
          genre: genre.resolveGenreNames(_results[index].genre_ids,_results[index].mediaType),
          mediaType: _results[index].mediaType,
          ratings: _results[index].vote_average,
          overview: _results[index].overview,
          elevation: 5.0,
          isFavorite: _favIDs.contains(_results[index].id),
        );
      },
    );
  }

  Widget _nothingFoundScreen() {
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

  void _scrollListener() {

    if (controller.offset >= controller.position.maxScrollExtent) {

      //check that you haven't already loaded the last page
      if (_currentPages < totalPages){

        //load the next page
        _currentPages = _currentPages + 1;

        _getContent(widget.contentType, widget.listID).then((data){

          if(mounted) setState(() {
            _results = _results + data;
          });

        });
      }
    }
  }

  @override
  void dispose() {
    controller.removeListener(_scrollListener);
    super.dispose();
  }
}

class GenreSortDialog extends StatefulWidget {
  final String selectedParam;
  final void Function(String) onValueChange;

  GenreSortDialog(
      {Key key, @required this.selectedParam, this.onValueChange}) :
        super(key: key);

  @override
  _GenreSortDialogState createState() => new _GenreSortDialogState();
}

class _GenreSortDialogState extends State<GenreSortDialog> {

  String _sortByValue;
  String _orderValue;

  @override
  void initState() {
    super.initState();
    var temp = widget.selectedParam.split(".");
    _sortByValue = temp[0];
    _orderValue = "."+temp[1];
  }


  TextStyle _glacialStyle = TextStyle(
    fontFamily: "GlacialIndifference",
    //fontSize: 19.0,
  );

  TextStyle _glacialStyle1 = TextStyle(
    fontFamily: "GlacialIndifference",
    fontSize: 17.0,
  );

  Widget build(BuildContext context){
    return new SimpleDialog(
      title: Text("Sort by",
        style: _glacialStyle,
      ),
      children: <Widget>[
        //Title(title: "Sort by", color: Colors.white,),
        Padding(
          padding: const EdgeInsets.only(left: 12.0, right: 12.0),
          child: Divider( color: Colors.white,),
        ),
        RadioListTile(
          value: "popularity",
          title: Text(S.of(context).popularity, style: _glacialStyle1,),
          groupValue: _sortByValue,
          onChanged: _onSortChange,
        ),
        RadioListTile(
          value: "first_air_date",
          title: Text(S.of(context).air_date, style: _glacialStyle1,),
          groupValue: _sortByValue,
          onChanged: _onSortChange,
        ),
        RadioListTile(
          value: "vote_average",
          title: Text(S.of(context).vote_average, style: _glacialStyle1,),
          groupValue: _sortByValue,
          onChanged: _onSortChange,
        ),

        Row(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(
                  top: 7.0, bottom: 7.0, left: 32.0),
              child: Text(S.of(context).order, style:_glacialStyle1),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, right:11.0),
              child: Divider(color: Colors.white,),
            ),
          ],
        ),

        RadioListTile(
          value: ".asc",
          title: Text(S.of(context).ascending, style: _glacialStyle1,),
          groupValue: _orderValue,
          onChanged: _onOrderChange,
        ),
        RadioListTile(
          value: ".desc",
          title: Text(S.of(context).descending, style: _glacialStyle1,),
          groupValue: _orderValue,
          onChanged: _onOrderChange,
        ),

        Padding(
          padding: const EdgeInsets.only(left: 55.0),
          child: Row(
            children: <Widget>[
              FlatButton(
                onPressed: (){
                  Navigator.pop(context);
                },
                child: Text(S.of(context).cancel,
                  style: _glacialStyle1,
                ),
              ),
              FlatButton(
                onPressed: (){
                  widget.onValueChange(_sortByValue+_orderValue);
                  Navigator.pop(context);
                },
                child: Text(S.of(context).sort, style: _glacialStyle1,),
              ),
            ],),
        )
      ],
    );
  }

  void _onOrderChange(String value) {
    if(mounted) setState(() {
      _orderValue = value;
    });
  }

  void _onSortChange(String value){
    if(mounted) setState(() {
      _sortByValue = value;
    });
  }

}

class DiscoverModel {

  final String name, poster_path, backdrop_path, year, mediaType, overview;
  final int id, vote_count, page;
  final List genre_ids;
  final int vote_average;

  DiscoverModel.fromJSON(Map json, int pageCount, String contentType)
      : name = json["name"] == null ? json["title"] : json["name"],
        poster_path = json["poster_path"],
        backdrop_path = json["backdrop_path"],
        id = json["id"],
        vote_average = json["vote_average"] != null ? (json["vote_average"]).round() : 0,
        overview = json["overview"],
        genre_ids = json["genre_ids"],
        mediaType = contentType,
        page = pageCount,
        year = json["first_air_date"] == null ?
        json["release_date"] : json["first_air_date"],
        vote_count = json["vote_count"];
}