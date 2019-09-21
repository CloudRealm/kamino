import 'dart:convert' as Convert;

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:kamino/external/ExternalService.dart';
import 'package:kamino/external/api/tmdb.dart';
import 'package:kamino/models/content/content.dart';
import 'package:kamino/models/content/movie.dart';
import 'package:kamino/models/content/tv_show.dart';
import 'package:kamino/ui/elements.dart';
import 'package:kamino/ui/loading.dart';

class DiscoverPage extends StatefulWidget {

  final String title;
  final ContentType type;
  final int genreId;

  DiscoverPage({
    @required this.genreId,
    @required this.type,
    this.title
  });

  @override
  State<StatefulWidget> createState() => DiscoverPageState();

}

class DiscoverPageState extends State<DiscoverPage> {

  double _elevation;

  @override
  void initState() {
    _elevation = 0;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener(
      onNotification: (notification){
        if(notification is OverscrollIndicatorNotification){
          if(notification.leading) notification.disallowGlow();
          return true;
        }

        if(notification is ScrollNotification){
          double elevation = _elevation;

          if(notification.metrics.pixels > 0) elevation = 12;
          else elevation = 0;

          if(_elevation != elevation) setState(() {
            _elevation = elevation;
          });
        }

        return false;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        appBar: AppBar(
          elevation: _elevation,
          backgroundColor: Theme.of(context).backgroundColor,
          title: TitleText(widget.title),
          centerTitle: true,
        ),

        body: FutureBuilder<DiscoverResultsModel>(
          future: loadGenre(widget.type, widget.genreId),
          builder: (BuildContext context, AsyncSnapshot<DiscoverResultsModel> snapshot){
            if(!snapshot.hasData && !snapshot.hasError) return Container(
              child: Center(child: ApolloLoadingSpinner()),
            );

            if(snapshot.hasError) {
              print(snapshot.error);

              return Container(
                  margin: EdgeInsets.only(top: 30),
                  child: ErrorLoadingMixin(
                    partialForm: true,
                  )
              );
            }

            return ResponsiveContentGrid(
              idealItemWidth: 150,
              spacing: 10.0,
              margin: 10.0,
              content: snapshot.data.content,
              withLazyLoad: true,
              loadNextPage: (){
                if(snapshot.data.canLoadNextPage) return () async {
                  await snapshot.data.loadNextPage();
                  return snapshot.data.content;
                };

                return null;
              },
            );
          }
        )
      ),
    );
  }

  Future<DiscoverResultsModel> loadGenre(ContentType type, int genreId, { int page = 1 }) async {
    String url = "${TMDB.ROOT_URL}/discover/${getRawContentType(type)}"
        "${Service.get<TMDB>().getDefaultArguments(context)}&"
        "sort_by=popularity.desc&include_adult=false"
        "&include_video=false&with_genres=$genreId&page=$page";

    Map response = Convert.jsonDecode((await get(url)).body);
    List results = response['results'].map((result){
      if(type == ContentType.TV_SHOW){
        return TVShowContentModel.fromJSON(result);
      }

      if(type == ContentType.MOVIE){
        return MovieContentModel.fromJSON(result);
      }

      return null;
    }).toList().cast<ContentModel>();

    return new DiscoverResultsModel(
      content: results,
      loadedUntil: 1,
      totalPages: response['total_pages'],
      fullyLoaded: response['total_pages'] == 1,
      loadNextPage: (DiscoverResultsModel results, int _page) async {
        results.content.addAll((await loadGenre(type, genreId, page: _page)).content);
      }
    );
  }

}

class DiscoverResultsModel {

  List<ContentModel> content;
  int loadedUntil;
  int totalPages;
  bool fullyLoaded;

  Function(DiscoverResultsModel, int page) _loadNextPage;
  bool get canLoadNextPage => _loadNextPage != null && !fullyLoaded;

  Future<void> loadNextPage () async {
    this.loadedUntil++;

    if(_loadNextPage != null) await _loadNextPage(this, loadedUntil);
    this.fullyLoaded = loadedUntil >= totalPages;
  }

  DiscoverResultsModel({
    @required this.content,
    @required this.loadedUntil,
    @required this.totalPages,
    @required this.fullyLoaded,
    Function(DiscoverResultsModel, int page) loadNextPage
  }) : this._loadNextPage = loadNextPage;

}