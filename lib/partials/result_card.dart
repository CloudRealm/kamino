import 'package:flutter/material.dart';
import 'package:flutter_rating/flutter_rating.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kamino/external/api/tmdb.dart';

class ResultCard extends StatefulWidget {

  final String background;
  final String name;
  final double elevation;
  final List<String> genre;
  final String mediaType;
  final int ratings;
  final String overview;
  final bool isFav;

  ResultCard({
    @required this.background,
    @required this.name,
    @required this.genre,
    @required this.mediaType,
    @required this.ratings,
    @required this.overview,
    @required this.isFav,
    @required this.elevation
  });

  @override
  _ResultCardState createState() => _ResultCardState();

}

class _ResultCardState extends State<ResultCard> {

  Color _favoriteIndicator() {

    if (widget.isFav == true) {
      return Colors.yellow;
    }

    return Theme.of(context).accentTextTheme.body1.color;
  }

  String _genre(){
    String genreOverview = "";

    if (widget.genre.length == 1){
      return widget.genre[0];

    } else {

      widget.genre.forEach((String element){
        if (widget.genre.indexOf(element) == 0){
          genreOverview = element;
        }
        genreOverview = genreOverview + ", "+element;

      });
    }

    return genreOverview;
  }

  @override
  Widget build(BuildContext context) {

    Widget imageWidget = Container();

    double _imageHeight = 170.0;
    double _imageWidth = 105.0;

    if(widget.background != null) {

      imageWidget = CachedNetworkImage(
        imageUrl: TMDB.IMAGE_CDN_POSTER + widget.background,
        fit: BoxFit.cover,
        placeholder: (BuildContext context, String url) => Image(
          image: AssetImage("assets/images/no_image_detail.jpg"),
          fit: BoxFit.cover,
          height: _imageHeight,
          width: _imageWidth,
        ),
        height: _imageHeight,
        width: _imageWidth,
        errorWidget: (BuildContext context, String url, error) => Icon(Icons.error, size: 20.0)
      );

    }else{
      imageWidget = new Image(
          image: AssetImage("assets/images/no_image_detail.jpg"),
          fit: BoxFit.cover,
          height: _imageHeight,
          width: _imageWidth,
      );
    }

    //const _containerWidth = 221.0;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      height: 170.0,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)
        ),
        elevation: 5,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
              ),
              child: imageWidget,
            ),

            Flexible(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[

                      //Title of the poster
                      Container(
                        padding: EdgeInsets.only(top: 4.0),
                        child: Text(
                          widget.name,
                          style: TextStyle(
                            fontFamily: "GlacialIndifference",
                            color: _favoriteIndicator(),
                            fontSize: 22.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),

                      //The list of genres for the content being displayed
                      /*
                      Container(
                        padding: EdgeInsets.only(top: 6.0),
                        child: _genre() != null ? Text(_genre(),
                          style: TextStyle(
                        //fontFamily: "GlacialIndifference",
                        color: _favoriteIndicator(),),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ) : Container(),
                      ),
                      */

                      Container(
                        padding: EdgeInsets.only(bottom: 4.0),
                        child: StarRating(
                          rating: widget.ratings / 2, // Ratings are out of 10 from our source.
                          color: Theme.of(context).primaryColor,
                          borderColor: Theme.of(context).primaryColor,
                          size: 19.0,
                          starCount: 5,
                        ),
                      ),

                      //Over summary
                      widget.overview != null ? Container(
                        padding: EdgeInsets.only(top: 4.0, bottom: 5.5),
                        child: Text(
                          widget.overview,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            //fontFamily: "GlacialIndifference",
                            fontSize: 15.0,
                            color: _favoriteIndicator(),
                          ),
                          maxLines: 5,
                          overflow: TextOverflow.fade,
                        ),
                      ) : Container(),

                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

}
