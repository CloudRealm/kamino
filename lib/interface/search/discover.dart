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

        body: ListView(
          children: <Widget>[
            FutureBuilder(future: loadGenre(widget.type, widget.genreId), builder: (BuildContext context, AsyncSnapshot snapshot){
              if(!snapshot.hasData && !snapshot.hasError) return Container(
                margin: EdgeInsets.only(top: 30),
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
                content: snapshot.data,
              );
            }),

            Container(height: 20)
          ],
        ),
      ),
    );
  }

  Future<List<ContentModel>> loadGenre(ContentType type, int genreId) async {
    String url = "${TMDB.ROOT_URL}/discover/${getRawContentType(type)}"
        "${Service.get<TMDB>().getDefaultArguments(context)}&"
        "sort_by=popularity.desc&include_adult=false"
        "&include_video=false&with_genres=$genreId";

    List results = (Convert.jsonDecode((await get(url)).body))['results'];
    return results.map((result){
      if(type == ContentType.TV_SHOW){
        return TVShowContentModel.fromJSON(result);
      }

      if(type == ContentType.MOVIE){
        return MovieContentModel.fromJSON(result);
      }

      return null;
    }).toList();
  }

}