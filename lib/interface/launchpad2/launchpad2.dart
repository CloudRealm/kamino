import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:kamino/animation/transition.dart';
import 'package:kamino/external/ExternalService.dart';
import 'package:kamino/external/api/tmdb.dart';
import 'package:kamino/external/api/trakt.dart';
import 'package:kamino/generated/i18n.dart';
import 'package:kamino/interface/content/overview.dart';
import 'package:kamino/interface/search/curated_search.dart';
import 'package:kamino/main.dart';
import 'package:kamino/models/content/content.dart';
import 'package:kamino/models/list.dart';
import 'package:kamino/partials/carousel_card.dart';
import 'package:kamino/partials/content_poster.dart';
import 'package:kamino/ui/elements.dart';
import 'package:kamino/ui/interface.dart';
import 'package:kamino/ui/loading.dart';
import 'package:kamino/util/database_helper.dart';
import 'package:kamino/util/settings.dart';
import 'package:shimmer/shimmer.dart';
import 'package:simple_moment/simple_moment.dart';
import 'package:carousel_slider/carousel_slider.dart';

class Launchpad2 extends KaminoAppPage {

  @override
  State<StatefulWidget> createState() => Launchpad2State();

}

class Launchpad2State extends State<Launchpad2> {

  AsyncMemoizer _launchpadMemoizer = new AsyncMemoizer();
  AsyncMemoizer _traktMemoizer = new AsyncMemoizer();

  EditorsChoice _editorsChoice;
  List<ContentModel> _topPicksList;
  List<ContentModel> _continueWatchingList;

  bool _watchlistsLoaded;
  List<ContentListModel> _watchlists;

  Future<void> load() async {
    return Future.any([
      Service.get<TMDB>().getList(context, 105604, loadFully: false, useCache: true).then((list){
        if(mounted) setState(() => _topPicksList = list.content);
      }),

      // Load editor's choice without preventing homepage from being displayed.
      DatabaseHelper.refreshEditorsChoice(context).then((_) {
        if (mounted) DatabaseHelper.selectRandomEditorsChoice().then(
                (EditorsChoice editorsChoice){
              if(mounted) setState(() =>
              _editorsChoice = editorsChoice
              );
            }
        );
      })
    ]);
  }

  @override
  void didChangeDependencies() {
    _loadTrakt();
    _loadWatchLists();

    super.didChangeDependencies();
  }

  @override
  void initState() {
    _watchlistsLoaded = false;

    _loadTrakt();
    _loadWatchLists();

    super.initState();
  }


  Future<void> _loadTrakt() async {
    if(await Service.get<Trakt>().isAuthenticated()) {
      await _traktMemoizer.runOnce(() => Service.get<Trakt>().getWatchHistory(context)).then((continueWatchingList){
        if(_continueWatchingList == null){
          _continueWatchingList = continueWatchingList;
          if(mounted) setState((){});
        }
      });
    }
  }

  Future<void> _loadWatchLists() async {
    List<String> watchlists = (jsonDecode((await Settings.homepageCategories)) as Map).keys.toList();

    if(!_watchlistsLoaded ||
        !ListEquality().equals(_watchlists
            .where((ContentListModel list) => list != null)
            .map((ContentListModel list) => list.id.toString())
            .toList(), watchlists)
    ){
      (() async {
        List<ContentListModel> _loadedWatchlists = new List();
        for(String watchlist in watchlists){
          if(!mounted) break;
          try {
            _loadedWatchlists.add(await Service.get<TMDB>().getList(
                context, int.parse(watchlist), loadFully: false,
                useCache: true));
          }catch(ex){}
        }

        if(mounted) setState(() {
          _watchlists = _loadedWatchlists;
          _watchlistsLoaded = true;
        });
      })();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _launchpadMemoizer.runOnce(load),
      builder: (BuildContext context, AsyncSnapshot snapshot){
        if(snapshot.connectionState == ConnectionState.none || snapshot.hasError){
          if(snapshot.error is SocketException
            || snapshot.error is HttpException) return OfflineMixin(
            reloadAction: () async {
              _launchpadMemoizer = new AsyncMemoizer();
              await _launchpadMemoizer.runOnce(load).catchError((error){});
              if(mounted) setState(() {});
            },
          );

          print(snapshot.error);
          if(snapshot is Error) print((snapshot.error as Error).stackTrace);
          return ErrorLoadingMixin(
            errorMessage: S.of(context).error_loading_launchpad,
            action: () async {
              _launchpadMemoizer = new AsyncMemoizer();
              await _launchpadMemoizer.runOnce(load).catchError((error){});
              if(mounted) setState(() {});
            },
          );
        }

        switch(snapshot.connectionState){
          case ConnectionState.done:
          return ListView(
            children: <Widget>[
              Container(
                margin: EdgeInsets.symmetric(vertical: 10),
                color: Theme.of(context).backgroundColor,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[

                  // ApolloTV Top Picks
                  Container(
                    margin: EdgeInsets.only(bottom: 20),
                    height: 200,
                    child: Container(
                      child: ScrollConfiguration(
                          behavior: EmptyScrollBehaviour(),
                          child: CarouselSlider(
                              autoPlay: true,
                              autoPlayInterval: Duration(seconds: 20),
                              autoPlayAnimationDuration: Duration(milliseconds: 1400),
                              pauseAutoPlayOnTouch: Duration(seconds: 1),
                              enlargeCenterPage: true,
                              height: 200,
                              items: _topPicksList != null ? List.generate(_topPicksList.length, (int index){
                                return Builder(builder: (BuildContext context){
                                  var content = _topPicksList[index];

                                  return Container(
                                    child: CarouselCard(content),
                                    margin: EdgeInsets.symmetric(horizontal: 5),
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                  );
                                });
                              }) : List.generate(3, (int index){
                                return Container(
                                  child: Material(
                                    type: MaterialType.card,
                                    elevation: 2,
                                    clipBehavior: Clip.antiAlias,
                                    borderRadius: BorderRadius.circular(8),
                                    child: Shimmer.fromColors(
                                      baseColor: const Color(0x8F000000),
                                      highlightColor: const Color(0x4F000000),
                                      child: Container(color: const Color(0x8F000000)),
                                    ),
                                  ),
                                  margin: EdgeInsets.symmetric(horizontal: 5),
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                );
                              })
                          )
                      ),
                    ),
                  ),

                  _continueWatchingList != null ? Container(
                    padding: EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SubtitleText(S.of(context).continue_watching),

                        Container(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: ListView.builder(
                              physics: NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              scrollDirection: Axis.vertical,
                              itemCount: _continueWatchingList.length,
                              itemBuilder: (BuildContext context, int index){
                                return GestureDetector(
                                  onTap: (){
                                    Navigator.push(
                                        context,
                                        ApolloTransitionRoute(
                                            builder: (context) => ContentOverview(
                                                contentId: _continueWatchingList[index].id,
                                                contentType: _continueWatchingList[index].contentType
                                            )
                                        )
                                    );
                                  },
                                  child: Card(
                                    clipBehavior: Clip.antiAlias,
                                    color: Theme.of(context).cardColor,
                                    child: Column(
                                      children: <Widget>[
                                        ListTile(
                                          leading: CachedNetworkImage(
                                            imageUrl: TMDB.IMAGE_CDN + _continueWatchingList[index].posterPath,
                                            height: 92,
                                            width: 46,
                                          ),
                                          title: TitleText(_continueWatchingList[index].title),
                                          subtitle: Text("${(_continueWatchingList[index].progress * 100).round()}% watched \u2022 ${DateTime.parse(_continueWatchingList[index].lastWatched).isAfter(DateTime.now()) ? "watching now" : Moment.now().from(DateTime.parse(_continueWatchingList[index].lastWatched))}"),
                                        ),

                                        SizedBox(
                                          height: 4,
                                          width: double.infinity,
                                          child: LinearProgressIndicator(
                                              value: _continueWatchingList[index].progress,
                                              backgroundColor: const Color(0x22000000),
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                  Theme.of(context).primaryColor
                                              )
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              }
                          ),
                        )
                      ],
                    ),
                  ) : Container(),

                  _editorsChoice == null
                      ? Container()
                      : SubtitleText(S.of(context).editors_choice, padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10).copyWith(bottom: 0)),
                  _editorsChoice == null ? Container() : Container(
                      height: 200,
                      padding: EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                      child: Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          GestureDetector(
                            onTap: () => Interface.openOverview(context, _editorsChoice.id, _editorsChoice.type),
                            child: Container(
                              margin: EdgeInsets.symmetric(vertical: 10),
                              child: Card(
                                child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints){
                                  return Container(
                                    margin: EdgeInsets.only(left: 107),
                                    padding: EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        TitleText(
                                            _editorsChoice.title,
                                            fontSize: 24
                                        ),
                                        LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints){
                                          return Container(
                                            margin: EdgeInsets.only(top: 10, right: 5),
                                            child: AutoSizeText(
                                              _editorsChoice.comment,
                                              overflow: TextOverflow.fade,
                                              maxLines: 5,
                                              maxFontSize: 12,
                                            ),
                                          );
                                        })
                                      ],
                                    ),
                                  );
                                })
                              ),
                            ),
                          ),

                          Positioned(
                            top: 0,
                            left: 0,
                            bottom: 0,
                            width: 107,
                            child: ContentPoster(
                              elevation: 4,
                              onTap: () => Interface.openOverview(context, _editorsChoice.id, _editorsChoice.type),
                              background: _editorsChoice.poster,
                              showGradient: false,
                            ),
                          )
                        ],
                      )
                  ),

                  !_watchlistsLoaded ? Container(
                    margin: EdgeInsets.symmetric(vertical: 30),
                    child: Center(
                      child: ApolloLoadingSpinner()
                    )
                  ) : ListView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: _watchlists.length,
                    itemBuilder: (BuildContext context, int index){
                      ContentListModel watchlist = _watchlists[index];

                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 25),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                SubtitleText(watchlist.name),
                                MaterialButton(
                                    highlightColor: Theme.of(context).accentTextTheme.body1.color.withOpacity(0.3),
                                    minWidth: 0,
                                    padding: EdgeInsets.symmetric(vertical: 0, horizontal: 15),
                                    child: Text(S.of(context).see_all, style: TextStyle(color: Theme.of(context).primaryTextTheme.body1.color)),
                                    onPressed: () => Navigator.of(context).push(
                                        ApolloTransitionRoute(builder: (BuildContext context) => CuratedSearch(
                                          listName: watchlist.name,
                                          listID: watchlist.id,
                                          contentType: getRawContentType(watchlist.content[0].contentType)
                                        ))
                                    )
                                )
                              ],
                            ),

                            /* Widget content */
                            Padding(
                              padding: EdgeInsets.only(top: 5, bottom: 5),
                              child: Container(
                                  height: 150,
                                  child: ListView.builder(
                                      shrinkWrap: false,
                                      scrollDirection: Axis.horizontal,
                                      itemCount: watchlist.content.length,
                                      itemBuilder: (BuildContext context, int index) {
                                        ContentModel content = watchlist.content[index];

                                        return Container(
                                          margin: EdgeInsets.symmetric(horizontal: 5),
                                          child: InkWell(
                                            onTap: (){
                                              Navigator.push(
                                                  context,
                                                  ApolloTransitionRoute(
                                                      builder: (context) => ContentOverview(
                                                          contentId: content.id,
                                                          contentType: content.contentType
                                                      )
                                                  )
                                              );
                                            },
                                            onLongPress: (){},
                                            child: Container(
                                              width: 100.5,
                                              child: new ContentPoster(
                                                  name: content.title,
                                                  background: content.posterPath,
                                                  mediaType: getRawContentType(content.contentType),
                                                  releaseDate: content.releaseDate
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                  )
                              ),
                            )
                          ],
                        ),
                      );
                    }
                  )

                ]),
              )
            ],
          );

          case ConnectionState.none:
          case ConnectionState.active:
          case ConnectionState.waiting:
          default:
            return Center(
                child: ApolloLoadingSpinner()
            );
        }
      }
    );
  }

}