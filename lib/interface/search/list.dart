import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kamino/external/api/tmdb.dart';
import 'package:kamino/models/content/content.dart';
import 'package:kamino/models/list.dart';
import 'package:kamino/ui/elements.dart';
import 'package:kamino/ui/loading.dart';

class ContentListPage extends StatefulWidget {

  final ContentListModel list;

  ContentListPage({
    @required this.list
  });

  @override
  State<StatefulWidget> createState() => ContentListPageState();

}

class ContentListPageState extends State<ContentListPage> {

  ContentListModel list;

  @override
  void initState() {
    this.list = widget.list;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled){
          return [
            SliverPersistentHeader(
              pinned: true,
              floating: false,
              delegate: _ListPageBarDelegate(list),
            )
          ];
        },

        body: ResponsiveContentGrid(
          idealItemWidth: 150,
          spacing: 10.0,
          margin: 10.0,
          content: list.content,
          withLazyLoad: true,
          loadNextPage: (){
            if(list.canLoadNextPage) return () async {
              await list.loadNextPage();
              return list.content;
            };

            return null;
          },
        ),
      ),
    );
  }

}

class _ListPageBarDelegate extends SliverPersistentHeaderDelegate {

  ContentListModel list;

  _ListPageBarDelegate(ContentListModel list){
    this.list = list;
  }

  double scrollProgress(double shrinkOffset) {
    double maxScrollAllowed = maxExtent - minExtent;
    return (
        (maxScrollAllowed - shrinkOffset) / maxScrollAllowed
    ).clamp(0, 1).toDouble();
  }

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double visibleMainHeight = max(maxExtent - shrinkOffset, minExtent);
    final double animationVal = scrollProgress(shrinkOffset);

    return Material(elevation: 4, child: Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      height: visibleMainHeight,
      width: MediaQuery.of(context).size.width,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned(
            top: 30,
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    if(Navigator.of(context).canPop()) BackButton(),

                    Container(
                      margin: EdgeInsets.only(right: 10),
                      height: (48 * animationVal),
                      width: (48 * animationVal),
                      child: Opacity(
                        opacity: animationVal,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(52),
                          child: CachedNetworkImage(
                            errorWidget: (BuildContext context, String url, error) => new Icon(Icons.error),
                            imageUrl: "${TMDB.IMAGE_CDN_POSTER}/${list.backdrop}",
                            fit: BoxFit.cover,
                            placeholder: (BuildContext context, String url) => Center(
                              child: ApolloLoadingSpinner(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        TitleText(list.name, fontSize: 24),
                        Text("by ${list.creatorName}")
                      ],
                    ),

                    Spacer(),
                    Container(
                      margin: EdgeInsets.only(right: 20),
                      child: Icon(list.public ? Icons.public : Icons.lock),
                    )
                  ]
              ),
            ),
          ),

          Positioned(
            bottom: 10,
            child: Opacity(
              opacity: animationVal,
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        child: Icon(Icons.schedule, size: 18),
                        margin: EdgeInsets.only(right: 5),
                      ),
                      Text(getRuntime()),

                      Spacer(),

                      Container(
                        child: Icon(getListTypeIcon(), size: 18),
                        margin: EdgeInsets.only(right: 5),
                      ),
                      Text(list.items.toString()),

                      Spacer(),

                      Container(
                        child: Icon(Icons.star, size: 18),
                        margin: EdgeInsets.only(right: 5),
                      ),
                      Text(list.averageRating.toStringAsFixed(2) + " / 10")
                    ],
                  ),
                ),
              ),
            ),
          )
        ]
      ),
    ));
  }

  String getRuntime(){
    Duration runTime = Duration(minutes: list.runtime);
    return "${runTime.inHours.remainder(60).toString().padLeft(2, '0')}h ${runTime.inMinutes.remainder(60).toString().padLeft(2, '0')}m";
  }

  IconData getListTypeIcon(){
    if(list.content.length < 1) return Icons.help_outline;

    if(list.content.every((ContentModel model) => model.contentType == ContentType.TV_SHOW)) return Icons.live_tv;
    if(list.content.every((ContentModel model) => model.contentType == ContentType.MOVIE)) return Icons.local_movies;

    return Icons.playlist_play;
  }

  @override
  double get maxExtent => 150;

  @override
  double get minExtent => 110;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }

}