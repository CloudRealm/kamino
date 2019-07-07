import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kamino/external/api/tmdb.dart';
import 'package:kamino/res/bottom_gradient.dart';
import 'package:kamino/ui/elements.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:kamino/ui/loading.dart';

class ContentPoster extends StatefulWidget {

  final String background;
  final String name;
  final String releaseYear;
  final String releaseDate;
  final String mediaType;
  final double height, width;
  final BoxFit imageFit;
  final bool hideIcon;
  final bool showGradient;
  final double elevation;
  final GestureTapCallback onTap;
  final GestureLongPressCallback onLongPress;

  ContentPoster({
    @required this.background,
    this.name,
    this.releaseYear,
    this.releaseDate,
    this.mediaType,
    this.width = 500,
    this.height = 750,
    this.imageFit = BoxFit.cover,
    this.hideIcon = false,
    this.showGradient = true,
    this.elevation = 0,
    this.onTap,
    this.onLongPress
  });

  @override
  State<StatefulWidget> createState() => ContentPosterState();

}

class ContentPosterState extends State<ContentPoster> {

  @override
  Widget build(BuildContext context) {
    var releaseYear = "";
    if(widget.releaseYear != null) releaseYear = widget.releaseYear;
    if(widget.releaseDate != null){
      try {
        releaseYear = new DateFormat.y("en_US").format(
            DateTime.parse(widget.releaseDate)
        );
      }catch(ex){
        releaseYear = "Unknown";
      }
    }

    Widget imageWidget = Container();
    if(widget.background != null) {
      imageWidget = new CachedNetworkImage(
        errorWidget: (BuildContext context, String url, error) => new Icon(Icons.error),
        imageUrl: "${TMDB.IMAGE_CDN_POSTER}/${widget.background}",
        fit: widget.imageFit,
        placeholder: (BuildContext context, String url) => Center(
            child: ApolloLoadingSpinner(),
        ),
        height: widget.height,
        width: widget.width,
      );
    }else{
      imageWidget = Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Container(
            color: Colors.black,
            height: widget.height,
            width: widget.width,
          ),

          Center(child: TitleText("No Image", textColor: const Color(0xBFFFFFFF)))
        ],
      );
    }

    return Material(
      elevation: widget.elevation,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(5),
      child: Stack(
        fit: StackFit.expand,

        children: <Widget>[
          imageWidget,
          widget.showGradient ? Positioned.fill(
            top: -1,
            left: -1,
            right: -1,
            bottom: -1,
            child: BottomGradient(finalStop: 0.025),
          ) : Container(),
          Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  new Padding(
                      padding: EdgeInsets.only(bottom: 2, left: 10, right: 10),
                      child: widget.name != null ? TitleText(
                        widget.name,
                        fontSize: 16,
                      ) : Container()
                  ),

                  Padding(
                      padding: EdgeInsets.only(
                          top: 0,
                          bottom: 10,
                          left: 10,
                          right: 10
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          releaseYear != null ? Text(
                              releaseYear,
                              style: TextStyle(
                                fontSize: 12,
                              )
                          ) : Container(),

                          widget.hideIcon == false && widget.mediaType != null ? Icon(
                            widget.mediaType == 'tv' ? Icons.tv : Icons.local_movies,
                            size: 16,
                          ) : Container()
                        ],
                      )
                  )
                ],
              )
          ),

          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              onLongPress: widget.onLongPress,
              child: Container()
            ),
          )
        ],
      ),
    );
  }



}