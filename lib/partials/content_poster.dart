import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kamino/external/api/tmdb.dart';
import 'package:kamino/models/content/content.dart';
import 'package:shimmer/shimmer.dart';

class ContentPoster extends StatefulWidget {

  final ContentModel content;
  final double height;

  final EdgeInsetsGeometry padding;
  final double elevation;
  final GestureTapCallback onTap;
  final GestureLongPressCallback onLongPress;

  final bool showLabel;
  final bool showGradient;

  ContentPoster({
    @required this.content,
    @required this.height,

    this.padding = EdgeInsets.zero,
    this.elevation = 0,
    this.onTap,
    this.onLongPress,

    this.showLabel = true,
    this.showGradient = true
  });

  @override
  State<StatefulWidget> createState() => ContentPosterState();

}

class ContentPosterState extends State<ContentPoster> {

  @override
  Widget build(BuildContext context) {

    return buildBase(Material(
        elevation: widget.elevation,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(5),
        child: Stack(fit: StackFit.expand, children: <Widget>[

          // Poster
          CachedNetworkImage(
            errorWidget: (BuildContext context, String url, error) => new Icon(Icons.error),
            imageUrl: "${TMDB.IMAGE_CDN_POSTER}/${widget.content.posterPath}",
            fit: BoxFit.cover,
            placeholder: (BuildContext context, String url) => Center(
              child: Shimmer.fromColors(
                baseColor: const Color(0x8F000000),
                highlightColor: const Color(0x4F000000),
                child: Container(color: const Color(0x8F000000)),
              ),
            ),
          ),

          // Gradient
          /*if(widget.showGradient) Positioned.fill(
            top: -1,
            left: -1,
            right: -1,
            bottom: -1,
            child: BottomGradient(finalStop: 0.025),
          ),*/

          // Tap Handler
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              onLongPress: widget.onLongPress,
              child: Container()
            ),
          )

        ])
      ),
      widget.showLabel
          ? Container(
            child: Text(
              widget.content.title ?? "Unknown",
              textAlign: TextAlign.start,
              maxLines: 2,
              softWrap: true,
            ),
            margin: EdgeInsets.only(top: 5),
          ) : Container()
    );

  }

  Widget buildBase(Widget child, Widget footer){

    return Padding(
      padding: widget.padding,
      child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints){
        if(!widget.showLabel) return child;
        const double aspectRatio = 2 / 3;

        return Container(
          child: Column(
            children: <Widget>[
              Container(
                height: widget.height,
                child: AspectRatio(
                  aspectRatio: aspectRatio,
                  child: child,
                ),
              ),

              Container(
                width: aspectRatio
                    * widget.height,
                child: footer,
              )
            ]
          )
          /*child: Stack(children: <Widget>[
            Positioned(
              top: 0,
              height: height,
              child:
            ),

            Positioned(
              child: Container(
                width: width,
                child: footer
              ),
              top: height,
              bottom: 0,
            )
          ]),*/
        );
      })
    );

  }

}