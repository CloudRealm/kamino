import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kamino/external/ExternalService.dart';
import 'package:kamino/external/api/tmdb.dart';
import 'package:kamino/external/struct/content_database.dart';
import 'package:kamino/generated/i18n.dart';
import 'package:kamino/models/content/content.dart';
import 'package:kamino/models/content/movie.dart';
import 'package:kamino/models/content/tv_show.dart';
import 'package:kamino/models/person.dart';
import 'package:kamino/partials/content_poster.dart';
import 'package:kamino/ui/elements.dart';
import 'package:kamino/ui/interface.dart';
import 'package:transparent_image/transparent_image.dart';

class SearchPage extends StatefulWidget {

  @override
  State<StatefulWidget> createState() => SearchPageState();

}

class SearchPageState extends State<SearchPage> {

  TextEditingController inputController = new TextEditingController();
  SearchResults results = SearchResults.none();

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      body: ListView(children: <Widget>[
        // Search field
        SearchFieldWidget(
          controller: inputController,

          leading: ModalRoute.of(context).canPop ? IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            icon: Icon(Icons.arrow_back),
            onPressed: (){
              Navigator.of(context).pop();
            },
          ) : null,

          onUpdate: (String value) async {
            SearchResults newResults = await Service.get<TMDB>().search(context, value, isAutoComplete: true);
            setState(() {
              results = newResults;
            });
          },
          onSubmit: (String value){

          },

          /*child: (BuildContext context, String query){
            if(query.isEmpty) return null;

            return Column(children: <Widget>[
              Container(
                child: ListTile(
                  title: Text(query),
                ),
              )
            ]);
          }*/
        ),


        // BEGIN: Content
        Container(
          margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          child: Column(children: <Widget>[

            // People
            // TODO: Just prepare the lists before setting out tree.
            if(results.people.where((p) => p.profilePath != null).length > 0) ...[
              SubtitleText(S.of(context).people, padding: EdgeInsets.only(
                  top: 10,
                  bottom: 20,
                  left: 10,
                  right: 10
              )),
              Container(
                height: 90,
                child: NotificationListener<OverscrollIndicatorNotification>(
                  onNotification: (notification){
                    notification.disallowGlow();
                    return false;
                  },
                  child: ListView.builder(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemCount: results.people.length,
                      itemBuilder: (BuildContext context, int index){
                        PersonModel person = results.people[index];

                        if(person.profilePath == null) return Container();

                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: 10),
                          child: Column(children: <Widget>[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              clipBehavior: Clip.antiAlias,
                              child: FadeInImage.memoryNetwork(
                                placeholder: kTransparentImage,
                                image: TMDB.IMAGE_CDN + person.profilePath,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            ),

                            Container(
                              margin: EdgeInsets.only(top: 10),
                              child: Text(person.name, textAlign: TextAlign.center),
                            )
                          ]),
                        );
                      }
                  ),
                ),
              ),

              Container(margin: EdgeInsets.only(bottom: 40))
            ],


            // TV Shows
            if(results.shows.length > 0) ...[
              SubtitleText(S.of(context).tv_shows, padding: EdgeInsets.only(
                top: 10,
                left: 10,
                right: 10
              )),
              LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints){
                double idealWidth = 150;
                double spacing = 10.0;

                return GridView.builder(
                    padding: EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: (constraints.maxWidth / idealWidth).round(),
                      childAspectRatio: 0.67,
                      mainAxisSpacing: spacing,
                      crossAxisSpacing: spacing,
                    ),
                    itemCount: results.shows.length,
                    itemBuilder: (BuildContext context, int index){
                      TVShowContentModel show = results.shows[index];

                      return ContentPoster(
                        background: show.posterPath,
                        name: show.title,
                        releaseDate: show.releaseDate,
                        mediaType: getRawContentType(ContentType.TV_SHOW),
                        onTap: () => Interface.openOverview(context, show.id, ContentType.TV_SHOW),
                      );
                    }
                );
              }),

              Container(margin: EdgeInsets.only(bottom: 10))
            ],

            // Movies
            if(results.movies.length > 0) ...[
              SubtitleText(S.of(context).movies, padding: EdgeInsets.only(
                  top: 10,
                  left: 10,
                  right: 10
              )),
              LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints){
                double idealWidth = 150;
                double spacing = 10.0;

                return GridView.builder(
                    padding: EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: (constraints.maxWidth / idealWidth).round(),
                      childAspectRatio: 0.67,
                      mainAxisSpacing: spacing,
                      crossAxisSpacing: spacing,
                    ),
                    itemCount: results.movies.length,
                    itemBuilder: (BuildContext context, int index){
                      MovieContentModel movie = results.movies[index];

                      return ContentPoster(
                        background: movie.posterPath,
                        name: movie.title,
                        releaseDate: movie.releaseDate,
                        mediaType: getRawContentType(ContentType.MOVIE),
                        onTap: () => Interface.openOverview(context, movie.id, ContentType.MOVIE),
                      );
                    }
                );
              })
            ]


          ], crossAxisAlignment: CrossAxisAlignment.start),
        )
        // END: Content

      ])
    );

  }

}