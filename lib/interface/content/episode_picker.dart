import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:kamino/external/ExternalService.dart';
import 'package:kamino/external/api/tmdb.dart';
import 'package:kamino/generated/i18n.dart';
import 'package:kamino/main.dart';
import 'package:kamino/models/content/tv_show.dart';
import 'package:kamino/ui/elements.dart';
import 'package:kamino/ui/loading.dart';

class EpisodePicker extends StatefulWidget {
  final int contentId;
  final int seasonIndex;
  final TVShowContentModel show;

  EpisodePicker({
    Key key,
    @required this.contentId,
    @required this.seasonIndex,
    @required this.show
  }) : super(key: key);

  @override
  _EpisodePickerState createState() => new _EpisodePickerState();
}

class _EpisodePickerState extends State<EpisodePicker> {

  ScrollController _controller;
  SeasonModel _season;

  @override
  void initState() {
    // When the widget is initialized, download the overview data.
    loadDataAsync().then((data) {
      // When complete, update the state which will allow us to
      // draw the UI.
      if(mounted) setState(() {
        _season = data;
      });
    });

    super.initState();
    _controller = new ScrollController();
  }

  // Load the data from the source.
  Future<SeasonModel> loadDataAsync() async {
    String url = "${TMDB.ROOT_URL}/tv/${widget.contentId}/season/"
        "${widget.seasonIndex}${Service.get<TMDB>().getDefaultArguments(context)}";

    http.Response response  = await http.get(url);

    var _json = jsonDecode(response.body);
    return new SeasonModel(_json["season_number"],
        _json["id"], _json["name"], _json["episodes"], _json["air_date"]);
  }

  /* THE FOLLOWING CODE IS JUST LAYOUT CODE. */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).backgroundColor,
          title: TitleText(
              _season != null ? "${widget.show.title} - ${_season.name}" : S.of(context).loading,
              textColor: Theme.of(context).primaryTextTheme.title.color
          ),
          centerTitle: true,

          actions: <Widget>[
            Container(
              margin: EdgeInsets.symmetric(horizontal: 10),
              child: CastButton(),
            )
          ],
        ),
        body: _season == null ?

        // Shown whilst loading...
        Center(
            child: ApolloLoadingSpinner()
        ) :

        // Shown once loading is complete.
        ListView.builder(
            controller: _controller,
            itemCount: _season.episodes.length,
            itemBuilder: (BuildContext listContext, int index){
              var episode = _season.episodes[index];
              var airDate = S.of(context).unknown;

              if(episode["air_date"] != null) {
                airDate = new DateFormat.yMMMMd("en_US").format(
                    DateTime.parse(episode["air_date"])
                );
              }

              var card = new Card(
                color: Theme.of(context).cardColor,
                clipBehavior: Clip.antiAlias,
                elevation: 5.0, // Boost shadow...
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)
                ),

                child: new Column(
                  children: <Widget>[
                    _generateEpisodeImage(episode, _controller),

                    Padding(
                        padding: EdgeInsets.only(top: 20.0, bottom: 5.0, left: 5.0, right: 5.0),
                        child: TitleText(episode["name"], fontSize: 28, allowOverflow: true, textAlign: TextAlign.center)
                    ),

                    Padding(
                        padding: EdgeInsets.only(bottom: 5.0, left: 5.0, right: 5.0),
                        child: TitleText(
                            'S${episode["season_number"].toString().padLeft(2, '0')} E${episode["episode_number"].toString().padLeft(2, '0')} \u2022 $airDate',

                            fontSize: 18,
                            allowOverflow: true,
                            textAlign: TextAlign.center
                        )
                    ),

                    Padding(
                        padding: EdgeInsets.only(top: 10.0, bottom: 10.0, left: 20.0, right: 20.0),
                        child: ConcealableText(
                            episode["overview"],
                            revealLabel: S.of(context).show_more,
                            concealLabel: S.of(context).show_less,
                            maxLines: 4
                        )
                    ),

                    new Align(
                        alignment: FractionalOffset.bottomCenter,
                        child: new SizedBox(
                          width: double.infinity,
                          child: new Padding(
                              padding: EdgeInsets.only(top: 15.0, bottom: 20, left: 15.0, right: 15.0),
                              child: new SizedBox(
                                height: 40,
                                child: new RaisedButton(
                                    shape: new RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5.0)
                                    ),
                                    onPressed: () async {
                                      int seasonNumber = episode["season_number"];
                                      int episodeNumber = episode["episode_number"];

                                      KaminoAppState application = context.ancestorStateOfType(const TypeMatcher<KaminoAppState>());
                                      (await application.getPrimaryVendorService()).playTVShow(
                                          widget.show,
                                          seasonNumber,
                                          episodeNumber,
                                          context
                                      );
                                    },
                                    child: new Text(
                                      S.of(context).play_episode,
                                      style: TextStyle(
                                          color: Theme.of(context).accentTextTheme.body1.color,
                                          fontSize: 16,
                                          fontFamily: 'GlacialIndifference'
                                      ),
                                    ),
                                    color: Theme.of(context).primaryColor,

                                    elevation: 1
                                ),
                              )
                          ),
                        )
                    )
                  ],
                ),
              );

              const padding = 15.0;

              return Padding(
                  padding: EdgeInsets.only(
                    // Cancel the effects of the status bar.
                      top: MediaQuery.of(context).padding.top + padding,
                      bottom: padding,
                      left: padding,
                      right: padding
                  ),
                  child: card
              );
            }
        )
    );
  }

  Widget _generateEpisodeImage(Map episode, ScrollController _controller){
    if (episode["still_path"] == null) {
      return Container();
    }

    return LayoutBuilder(builder: (BuildContext context, BoxConstraints size){
      return Center(
        child: Image.network(
          "${TMDB.IMAGE_CDN_LOWRES}${episode["still_path"]}",
          height: 200,
          width: size.maxWidth,
          fit: BoxFit.cover
        )
      );
    });
  }

}

class SeasonModel {
  final int seasonNumber, id;
  final List episodes;
  final String airDate, name;

  SeasonModel(this.seasonNumber, this.id, this.name, this.episodes, this.airDate);

  SeasonModel.fromJson(Map json):
        id = json["id"],
        name = json["name"],
        seasonNumber = json["season_number"],
        airDate = json["air_date"],
        episodes = json["episodes"];
}