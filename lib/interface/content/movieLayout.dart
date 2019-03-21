import 'package:flutter/material.dart';
import 'package:kamino/generated/i18n.dart';
import 'package:kamino/main.dart';
import 'package:kamino/models/content.dart';
import 'package:kamino/models/movie.dart';
import 'package:kamino/partials/content_poster.dart';
import 'package:kamino/ui/ui_elements.dart';
import 'package:kamino/ui/ui_constants.dart';
import 'package:kamino/api/tmdb.dart';
import 'package:kamino/interface/content/overview.dart';

class MovieLayout {

  static Widget generate(BuildContext context, MovieContentModel _data, List<int> _favsArray){
    return new WillPopScope(
      onWillPop: () {
        KaminoAppState appState = context.ancestorStateOfType(const TypeMatcher<KaminoAppState>());
        appState.getVendorConfigs()[0].cancel();

        return new Future(() => true);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 30.0),
          child: Column(
            children: <Widget>[
              /* Similar Movies */
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ListTile(
                      title: TitleText(
                          S.of(context).similar_movies,
                          fontSize: 22.0,
                          textColor: Theme.of(context).primaryTextTheme.body1.color
                      )
                  ),

                  SizedBox(
                    height: 200.0,
                    child: _generateSimilarMovieCards(_data, _favsArray)
                  )
                ],
              )
              /* ./Similar Movies */


            ]
          ),
        )
      )
    );
  }

  ///
  /// applyTransformations() -
  /// Allows this layout to apply transformations to the overview scaffold.
  /// This should be used to add a play FAB, for example.
  ///
  static Widget getFloatingActionButton(BuildContext context, MovieContentModel model){
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.0),
        child: new Row(
            children: <Widget>[
              Expanded(
                  child: new FloatingActionButton.extended(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0)
                    ),
                    onPressed: (){
                      KaminoAppState appState = context.ancestorStateOfType(const TypeMatcher<KaminoAppState>());
                      appState.getVendorConfigs()[0].playMovie(
                          model.title,
                          model.releaseDate,
                          context
                      );
                    },
                    icon: Container(),
                    label: Text(
                      S.of(context).play_movie,
                      style: TextStyle(
                        letterSpacing: 0.0,
                        fontFamily: 'GlacialIndifference',
                        fontSize: 18.0,
                        color: Theme.of(context).accentTextTheme.body1.color
                      ),
                    ),
                    backgroundColor: Theme.of(context).primaryColor,
                    elevation: 30
                  )
              )
            ]
        )
    );
  }

  /* PRIVATE SUBCLASS-SPECIFIC METHODS */

  static Widget _generateSimilarMovieCards(MovieContentModel _data, List<int> _favsArray){

    return _data.recommendations == null ? Container() : ListView.builder(
      shrinkWrap: true,
      scrollDirection: Axis.horizontal,
      itemCount: _data.recommendations.length,
      itemBuilder: (BuildContext context, int index) {
        return Padding(
          padding: index == 0
              ? const EdgeInsets.only(left: 18.0)
              : const EdgeInsets.only(left: 5.0),
          child: InkWell(
            onTap: () {
                KaminoAppState appState = context.ancestorStateOfType(const TypeMatcher<KaminoAppState>());
                appState.getVendorConfigs()[0].cancel();

                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ContentOverview(
                          contentId: _data.recommendations[index]["id"],
                          contentType: ContentType.MOVIE
                        ),
                    )
                );
            },
            onLongPress: (){
              addFavoritePrompt(
                  context, _data.recommendations[index]["title"], _data.recommendations[index]["id"],
                  TMDB.IMAGE_CDN + _data.recommendations[index]["poster_path"],
                  _data.recommendations[index]["release_date"], "movie");
            },
            splashColor: Colors.white,
            child: SizedBox(
              width: 152,
              child:  ContentPoster(
                name: _data.recommendations[index]["title"],
                background: _data.recommendations[index]["poster_path"],
                mediaType: 'movie',
                releaseDate: _data.recommendations[index]["release_date"],
                isFav: _favsArray.contains(_data.recommendations[index]["id"]),
              ),
            ),
          ),
        );
    });
  }

}