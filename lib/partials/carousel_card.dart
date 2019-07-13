import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_parallax/flutter_parallax.dart';
import 'package:intl/intl.dart';
import 'package:kamino/animation/transition.dart';
import 'package:kamino/external/api/tmdb.dart';
import 'package:kamino/interface/content/overview.dart';
import 'package:kamino/models/content/content.dart';
import 'package:kamino/models/content/movie.dart';

class CarouselCard extends StatefulWidget {

  final ContentModel model;
  final double width;
  final double height;

  CarouselCard(this.model, {
    this.width,
    this.height,
  });

  @override
  State<StatefulWidget> createState() => CarouselCardState();

}

class CarouselCardState extends State<CarouselCard> {

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(8),

      child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints){
        var height = widget.height != null ? widget.height : constraints.heightConstraints().maxHeight;
        var width = widget.width != null ? widget.width : constraints.widthConstraints().maxWidth;

        return Stack(
          fit: StackFit.expand,

          children: <Widget>[
            Parallax.inside(
                direction: AxisDirection.right,
                mainAxisExtent: height,
                child: CachedNetworkImage(
                  imageUrl: widget.model.backdropPath != null ? TMDB.IMAGE_CDN + widget.model.backdropPath : "",
                  fit: BoxFit.cover,
                  placeholder: (BuildContext context, String url) => Container(color: Colors.black, width: width, height: height),
                  height: height,
                  width: width + 100,
                  errorWidget: (BuildContext context, String url, error) => Center(child: Icon(Icons.error, size: 30.0))
                )
              // height: 220.0,
              // fit: BoxFit.cover,
            ),

            Container(color: const Color(0x66000000)),

            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: AutoSizeText(widget.model.title, style: TextStyle(fontSize: 25.0, color: Colors.white), maxFontSize: 25.0, minFontSize: 18.0, maxLines: 1, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis)
                ),
                Text(DateFormat.y("en_US").format(DateTime.parse(widget.model.releaseDate)), style: TextStyle(fontSize: 16, color: Colors.white))
              ],
            ),

            Positioned(
              right: 20,
              bottom: 20,
              child: new Icon(
                (widget.model is MovieContentModel) ? Icons.local_movies : Icons.live_tv,
                color: Colors.white,
              ),
            ),

            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: (){
                  Navigator.push(context, ApolloTransitionRoute(
                      builder: (context) => ContentOverview(
                        contentId: widget.model.id,
                        contentType: (widget.model is MovieContentModel) ? ContentType.MOVIE : ContentType.TV_SHOW,
                      )
                  ));
                },
              ),
            )
          ],
        );
      }),
    );
  }

}