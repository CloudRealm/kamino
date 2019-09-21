import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kamino/animation/transition.dart';
import 'package:kamino/external/api/tmdb.dart';
import 'package:kamino/generated/i18n.dart';
import 'package:kamino/models/content/tv_show.dart';
import 'package:kamino/ui/elements.dart';
import 'package:kamino/interface/content/episode_picker.dart';
import 'package:transparent_image/transparent_image.dart';

class TVShowLayout{

  static Widget generate(BuildContext context, TVShowContentModel _data){
    return Padding(
        padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        child: Column(
            children: <Widget>[

              /* Seasons Cards */
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SubtitleText(S.of(context).seasons_n(_data.seasons.length.toString())),

                  _generateSeasonsCards(context, _data)
                ],
              )
              /* ./Seasons Cards */


            ]
        )
    );
  }

  static Widget _generateSeasonsCards(BuildContext context, TVShowContentModel _data){
    if(_data.seasons.length > 0){
      return new Column(
        children: _data.seasons.map((season) {
          var seasonIndex = _data.seasons.indexOf(season);

          // Format 'air date'.
          var airDate = S.of(context).ongoing;

          if(season["air_date"] != null){
            airDate = new DateFormat.yMMMMd("en_US").format(
                DateTime.parse(season["air_date"])
            );
          }

          // Determine season image
          var image;
          if(season["poster_path"] != null){
            image = "${TMDB.IMAGE_CDN_POSTER}" + season["poster_path"];
          }

          // Create leading widget
          Widget leadingWidget = Icon(Icons.live_tv);
          if(image != null){
            leadingWidget = new FadeInImage(
              placeholder: MemoryImage(kTransparentImage),
              image: (
                  NetworkImage(image)
              ),
              height: 92,
              width: 46,
            );
          }

          // Return Card & GestureDetector
          return new GestureDetector(
              onTap: (){
                _openEpisodesView(context, _data, seasonIndex);
              },
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)
                ),
                elevation: 2,
                color: Theme.of(context).cardColor,
                child: new Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                      leading: Container(
                        child: leadingWidget,
                        height: 92,
                        width: 46,
                        alignment: Alignment.center,
                      ),
                      title: TitleText(season["name"]),
                      subtitle: Text(
                          (season["episode_count"] != 1 ?
                            S.of(context).n_episodes(season["episode_count"].toString()) :
                            S.of(context).one_episode)
                          + " \u2022 $airDate"
                      ),
                    )
                  ]
                )
              )
          );
        }).toList()
      );
    }

    return Container();
  }

  static void _openEpisodesView(
    BuildContext context,
    TVShowContentModel _data,
    int index
  ){
    Navigator.push(
        context,
        ApolloTransitionRoute(builder: (context) => EpisodePicker(
          contentId: _data.id,
          show: _data,
          seasonIndex: _data.seasons[index]["season_number"]
        ))
    );
  }

}