import 'package:cached_network_image/cached_network_image.dart';
import 'package:kamino/external/ExternalService.dart';
import 'package:kamino/external/api/tmdb.dart';
import 'package:kamino/external/api/trakt.dart';
import 'package:kamino/models/content.dart';
import 'package:flutter/material.dart';
import 'package:kamino/generated/i18n.dart';
import 'package:kamino/ui/elements.dart';
import 'package:kamino/util/database_helper.dart';

class ContentCard extends StatefulWidget {

  final int id;
  final String backdrop;
  final String name;
  final double elevation;
  final List<String> genre;
  final String mediaType;
  final String year;
  final int ratings;
  final String overview;
  final bool isFavorite;
  final GestureTapCallback onTap;
  final GestureLongPressCallback onLongPress;

  @override
  State<StatefulWidget> createState() => ContentCardState(
    isFavorite: isFavorite
  );

  ContentCard({
    @required this.id,
    @required this.backdrop,
    @required this.name,
    @required this.genre,
    @required this.year,
    @required this.mediaType,
    @required this.ratings,
    @required this.overview,
    @required this.elevation,
    @required this.isFavorite,
    @required this.onTap,
    @required this.onLongPress
  });

}

class ContentCardState extends State<ContentCard> {

  bool isFavorite;

  ContentCardState({
    this.isFavorite
  });

  /*
  ContentPoster(
    background: widget.background,
  ),
   */

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(5),
          clipBehavior: Clip.antiAlias,
          color: Theme.of(context).cardColor,
          child: InkWell(
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    Expanded(
                      child: Stack(
                        fit: StackFit.passthrough,
                        children: <Widget>[
                          widget.backdrop != null ? Container(
                            color: Colors.black,
                            height: 150,
                            child: Opacity(
                              opacity: 0.6,
                              child: CachedNetworkImage(
                                imageUrl: TMDB.IMAGE_CDN + widget.backdrop,
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                              ),
                            )
                          ) : Container(
                            height: 150,
                            color: const Color(0x9A000000),
                            child: Center(
                              child: Text(
                                  "No Poster",
                                  style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16
                                  )
                              ),
                            ),
                          ),

                          Positioned(
                            bottom: 10,
                            right: 15,
                            child: Row(
                              children: <Widget>[
                                Icon(
                                    widget.mediaType == 'tv'
                                        ? Icons.live_tv
                                        : Icons.local_movies
                                )
                              ],
                            )
                          )
                        ],
                      ),
                    )
                  ],
                ),

                Row(
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 15
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Padding(
                              child: TitleText(
                                widget.name,
                                fontSize: 24,
                                allowOverflow: true,
                                textAlign: TextAlign.start,
                                maxLines: 2,
                              ),
                              padding: EdgeInsets.only(bottom: 5),
                            ),
                            ConcealableText(
                              widget.overview,
                              revealLabel: S.of(context).show_more,
                              concealLabel: S.of(context).show_less,
                              maxLines: 2,
                              color: Colors.grey,
                            )
                          ],
                        ),
                      ),
                    ),

                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 5
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Material(
                            color: Theme.of(context).cardColor,
                            clipBehavior: Clip.antiAlias,
                            shape: CircleBorder(),
                            child: IconButton(
                              padding: EdgeInsets.all(3),
                              onPressed: () => _toggleFavorite(context),
                              highlightColor: Colors.transparent,
                              icon: isFavorite ? Icon(Icons.favorite) : Icon(Icons.favorite_border),
                              color: isFavorite ? Colors.red : Colors.white,
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                )
              ],
            ),
          )
      ),
    );
  }

  _toggleFavorite(BuildContext context) async {
    if (widget.isFavorite) {
      DatabaseHelper.removeFavoriteById(widget.id);

      if(await Service.get<Trakt>().isAuthenticated()) Service.get<Trakt>().removeFavoriteFromTrakt(
        context,
        type: widget.mediaType == 'tv' ? ContentType.TV_SHOW : ContentType.MOVIE,
        id: widget.id
      );
    } else {
      DatabaseHelper.saveFavoriteById(context, widget.mediaType == 'tv' ? ContentType.TV_SHOW : ContentType.MOVIE, widget.id);

      if(await Service.get<Trakt>().isAuthenticated()) Service.get<Trakt>().sendFavoriteToTrakt(
          context,
          id: widget.id,
          type: widget.mediaType == 'tv' ? ContentType.TV_SHOW : ContentType.MOVIE,
          title: widget.name,
          year: widget.year != null ? widget.year.substring(0,4) : null,
      );
    }

    setState(() {
      isFavorite = !isFavorite;
    });
  }

}