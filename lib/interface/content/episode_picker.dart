import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kamino/animation/transition.dart';

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

  double _elevation;
  ScrollController _controller;
  SeasonModel _season;

  @override
  void initState() {
    _elevation = 0;

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
  void switchSeason(BuildContext context){
    showDialog(
      context: context,
      builder: (BuildContext context){
        return SimpleDialog(
          titlePadding: EdgeInsets.symmetric(vertical: 24, horizontal: 32),
          contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 0).copyWith(bottom: 12),
          title: TitleText(widget.show.title),
          children: List.generate(widget.show.seasons.length, (int index){
            SeasonModel season = SeasonModel.fromJSON(widget.show.seasons[index]);
            int episodeCount = widget.show.seasons[index]['episode_count'];
            
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: InkWell(
                borderRadius: BorderRadius.circular(5),
                onTap: (){
                  Navigator.of(context).pop();
                  Navigator.of(context).pushReplacement(
                      ApolloTransitionRoute(builder: (context) => EpisodePicker(
                          contentId: widget.show.id,
                          show: widget.show,
                          seasonIndex: index
                      ))
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Expanded(child: Container(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            TitleText(season.name, textAlign: TextAlign.start),
                            Text(S.of(context).n_episodes(
                                episodeCount.toString()
                            ) + " \u2022 " + (season.airDate != null ? new DateFormat.yMMMMd(Locale.cachedLocaleString).format(
                                DateTime.parse(season.airDate)
                            ) : "Ongoing"))
                          ],
                        ),
                      )),

                      if(index == widget.seasonIndex) Container(
                        child: Icon(Icons.check),
                        margin: EdgeInsets.only(left: 24),
                      )
                      else Container(width: 24)
                    ],
                  )
                ),
              )
            );
          }),
        );
      }
    );
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
            title: InkWell(
              borderRadius: BorderRadius.circular(5),
              onTap: (){
                switchSeason(context);
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    TitleText(
                        widget.show.title,
                        textColor: Theme.of(context).primaryTextTheme.title.color
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                            _season != null ? _season.name : S.of(context).loading,
                            style: Theme.of(context).textTheme.caption
                        ),
                        Icon(Icons.arrow_drop_down, size: 12)
                      ],
                    )
                  ],
                ),
              ),
            ),
            centerTitle: true,

            actions: <Widget>[
              // Greater than 1 because swapping the order of one episode is also
              // useless.
              if(_season?.episodes != null && _season.episodes.length > 1) Container(
                child: IconButton(
                  tooltip: "Reverse Order",
                  icon: Icon(Icons.import_export),
                  onPressed: (){
                    setState(() {
                      _season.episodes = _season.episodes.reversed.toList();
                    });
                  },
                ),
              ),
              Container(
                margin: EdgeInsets.only(right: 10),
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

                  return Padding(
                      padding: EdgeInsets.all(20)
                          .copyWith(top: index == 0 ? 10 : 0),
                      child: EpisodeCard(episode, show: widget.show)
                  );
                }
            )
      )
    );
  }

}

class SeasonModel {
  final int seasonNumber, id;
  final String airDate, name;
  List episodes;

  SeasonModel(this.seasonNumber, this.id, this.name, this.episodes, this.airDate);

  SeasonModel.fromJSON(Map json):
        id = json["id"],
        name = json["name"],
        seasonNumber = json["season_number"],
        airDate = json["air_date"],
        episodes = json["episodes"];
}

class EpisodeCard extends StatefulWidget {

  final TVShowContentModel show;
  final Map episode;
  EpisodeCard(this.episode, {
    @required this.show
  });

  @override
  State<StatefulWidget> createState() => EpisodeCardState();

}

class EpisodeCardState extends State<EpisodeCard> {

  @override
  Widget build(BuildContext context) {
    var episode = widget.episode;
    var airDate = S.of(context).unknown;

    if(episode["air_date"] != null) {
      airDate = new DateFormat.yMMMMd("en_US").format(
          DateTime.parse(episode["air_date"])
      );
    }

    return Card(
      color: Theme.of(context).cardColor,
      clipBehavior: Clip.antiAlias,
      elevation: 5.0, // Boost shadow...
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)
      ),

      child: new Column(
        children: <Widget>[
          _generateEpisodeImage(episode),

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
  }

  Widget _generateEpisodeImage(Map episode){
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