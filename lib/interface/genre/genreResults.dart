import 'package:flutter/material.dart';
import 'package:kamino/generated/i18n.dart';
import 'dart:async';
import 'package:kamino/models/content.dart';
import 'package:kamino/interface/content/overview.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kamino/api/tmdb.dart';
import 'package:kamino/util/databaseHelper.dart' as databaseHelper;
import 'package:kamino/util/genre_names.dart' as genre;
import 'package:kamino/partials/content_poster.dart';
import 'package:kamino/partials/result_card.dart';
import 'package:kamino/ui/ui_utils.dart';
import 'package:kamino/util/settings.dart';


class GenreView extends StatefulWidget{
  final String contentType, genreName;
  final int genreID;

  GenreView(
      {Key key, @required this.contentType, @required this.genreID,
        @required this.genreName}) : super(key: key);

  @override
  _GenreViewState createState() => new _GenreViewState();
}

class _GenreViewState extends State<GenreView>{

  int _currentPages = 1;
  ScrollController controller;

  List<DiscoverModel> _results = [];
  List<int> _favIDs = [];
  bool _expandedSearchPref = false;

  String _selectedParam = "popularity.desc";
  int total_pages = 1;

  @override
  void initState() {

    (Settings.detailedContentInfoEnabled as Future).then((data) => setState(() => _expandedSearchPref = data));

    controller = new ScrollController()..addListener(_scrollListener);

    String _contentType = widget.contentType;
    String _genreName = widget.genreName;
    String _genreID = widget.genreID.toString();

    databaseHelper.getAllFavIDs().then((data){

      _favIDs = data;
    });

    _getContent(_contentType, _genreID).then((data){

      setState(() {
        _results = data;
      });

    });

    super.initState();
  }

  //get data from the api
  Future<List<DiscoverModel>> _getContent(_contentType, _genreID) async {

    List<DiscoverModel> _data = [];
    Map _temp;

    String url = "${TMDB.ROOT_URL}/discover/$_contentType"
        "${TMDB.defaultArguments}&"
        "sort_by=$_selectedParam&include_adult=false"
        "&include_video=false&"
        "page=${_currentPages.toString()}&with_genres=$_genreID";

    http.Response _res = await http.get(url);
    _temp = jsonDecode(_res.body);

    if (_temp["results"] != null) {
      total_pages = _temp["total_pages"];
      int resultsCount = _temp["results"].length;

      for(int x = 0; x < resultsCount; x++) {
        _data.add(DiscoverModel.fromJSON(
            _temp["results"][x], total_pages, _contentType));
      }
    }

    return _data;
  }

  _openContentScreen(BuildContext context, int index) {
    //print("id is ${snapshot.data[index].showID}");

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

  _applyNewParam(String choice) {

    if (choice != _selectedParam){

      _selectedParam = choice;

      _getContent(widget.contentType, widget.genreID.toString()).then((data){
        setState(() {

          //clear grid-view and replenish with new data
          _results.clear();
          _results = data;

          //scroll to the top of the results
          controller.jumpTo(controller.position.minScrollExtent);
        });
        _currentPages = 1;
      });
    }
    Navigator.of(context).pop;
  }

  @override
  Widget build(BuildContext context) {

    TextStyle _glacialFont = TextStyle(
        fontFamily: "GlacialIndifference");

    return Scrollbar(
        child: Scaffold(
          appBar: new AppBar(
            title: Text(widget.genreName, style: _glacialFont,),
            centerTitle: true,
            backgroundColor: Theme.of(context).backgroundColor,
            elevation: 5.0,
            actions: <Widget>[

              generateSearchIcon(context),

              //Add sorting functionality
              IconButton(
                  icon: Icon(Icons.sort), onPressed: (){
                showDialog(
                  context: context,
                  barrierDismissible: true,
                  builder: (_){
                    return GenreSortDialog(
                      onValueChange: _applyNewParam,
                      selectedParam: _selectedParam,
                    );
                  }
                );
              }),
          ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {

              await Future.delayed(Duration(seconds: 2));
              databaseHelper.getAllFavIDs().then((data){

                setState(() {
                  _favIDs = data;
                });
              });
            },
            child: Scrollbar(
              child: _expandedSearchPref == false ? _gridResults() : _listResult(),
            ),
          ),
        ),
    );
  }

  Widget _gridResults(){
    return GridView.builder(
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
    );
  }

  Widget _listResult(){
    return ListView.builder(
      itemCount: _results.length,
      controller: controller,

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
    print(controller.position.extentAfter);

    if (controller.offset >= controller.position.maxScrollExtent) {

      //check that you haven't already loaded the last page
      if (_currentPages < total_pages){

        //load the next page
        _currentPages = _currentPages + 1;

        _getContent(widget.contentType, widget.genreID).then((data){

          setState(() {
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
    setState(() {
      _orderValue = value;
    });
  }

  void _onSortChange(String value){
    setState(() {
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