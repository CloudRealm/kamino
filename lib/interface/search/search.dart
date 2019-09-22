import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kamino/animation/transition.dart';
import 'package:kamino/external/ExternalService.dart';
import 'package:kamino/external/api/tmdb.dart';
import 'package:kamino/external/struct/content_database.dart';
import 'package:kamino/generated/i18n.dart';
import 'package:kamino/interface/search/person.dart';
import 'package:kamino/models/person.dart';
import 'package:kamino/ui/elements.dart';
import 'package:transparent_image/transparent_image.dart';

class SearchPage extends StatefulWidget {

  @override
  State<StatefulWidget> createState() => SearchPageState();

}

class SearchPageState extends State<SearchPage> {

  TextEditingController inputController = new TextEditingController();
  SearchResults results = SearchResults.none();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      body: Stack(children: <Widget>[
        Positioned(
          top: 20,
          left: 0,
          right: 0,
          child: SearchFieldWidget(
            color: const Color(0xFF2F3136),
            controller: inputController,

            leading: ModalRoute.of(context).canPop ? IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              icon: Icon(Icons.arrow_back),
              onPressed: (){
                Navigator.of(context).pop();
              },
            ) : null,

            onClear: () {
              setState(() {
                results = SearchResults.none(query: "");
              });
            },

            onUpdate: (String value) async {
              setState(() {
                results = SearchResults.none(query: value);
              });

              SearchResults newResults = await Service.get<TMDB>().search(context, value, isAutoComplete: true);
              if(mounted) setState(() {
                results = newResults;
              });
            },

            onSubmit: (String value) async {
              if(results.query == value){
                return;
              }

              setState(() {
                results = SearchResults.none(query: value);
              });

              SearchResults newResults = await Service.get<TMDB>().search(context, value, isAutoComplete: false);
              setState(() {
                results = newResults;
              });
            },
          ),
        ),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 100),
          transitionBuilder: (Widget child, Animation<double> animation){
            return FadeTransition(child: child, opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut
            ));
          },
          child: _generateResultsView(
            key: ValueKey<SearchResults>(results)
          )
        )
      ].reversed.toList())
    );

  }

  Widget _generateResultsView({ Key key }){
    List people = results.people.where((p) => p.profilePath != null).toList();

    return ListView(key: key, children: <Widget>[

      Container(
        margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15).copyWith(right: 0),
        child: Column(children: <Widget>[

          Container(height: people.length > 0 ? 80 : 60),

          // People
          if(people.length > 0) ...[
            SubtitleText(S.of(context).people, padding: EdgeInsets.only(
                top: 10,
                bottom: 20,
                left: 10,
                right: 10
            )),
            Container(
              height: 110,
              child: NotificationListener<OverscrollIndicatorNotification>(
                onNotification: (notification){
                  notification.disallowGlow();
                  return false;
                },
                child: ListView.builder(
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    itemCount: people.length + 1,
                    itemBuilder: (BuildContext context, int index){
                      if(index == people.length){
                        return Container(width: 15);
                      }

                      PersonModel person = people[index];
                      if(person.profilePath == null) return Container();

                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: 10),
                        child: Column(children: <Widget>[
                          Container(
                            width: 60,
                            height: 60,
                            child: Stack(fit: StackFit.expand, children: <Widget>[
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

                              Material(
                                type: MaterialType.transparency,
                                borderRadius: BorderRadius.circular(60),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(60),
                                  onTap: (){
                                    Navigator.of(context).push(ApolloTransitionRoute(
                                        builder: (BuildContext context) => PersonPage(
                                          person: person
                                        )
                                    ));
                                  },
                                )
                              )
                            ]),
                          ),

                          Container(
                            margin: EdgeInsets.only(top: 10),
                            child: Text(person.name, textAlign: TextAlign.center),
                          ),

                          Container(
                            child: Text(
                              person.knownForDepartment,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.caption,
                            ),
                          )
                        ]),
                      );
                    }
                ),
              ),
            ),

            Container(margin: EdgeInsets.only(bottom: 20))
          ],

        ], crossAxisAlignment: CrossAxisAlignment.start),
      ),

      // TV Shows
      if(results.shows.length > 0) ...[
        SubtitleText(S.of(context).tv_shows, padding: EdgeInsets.only(
            top: 10,
            left: 20,
            right: 10
        )),
        ResponsiveContentGrid(content: results.shows),

        Container(margin: EdgeInsets.only(bottom: 10))
      ],

      // Movies
      if(results.movies.length > 0) ...[
        SubtitleText(S.of(context).movies, padding: EdgeInsets.only(
            top: 10,
            left: 20,
            right: 10
        )),
        ResponsiveContentGrid(
            content: results.movies,
            spacing: 10.0,
            margin: 10.0
        )
      ],

      Container(
        margin: EdgeInsets.only(bottom: 20)
      )
    ]);
  }

}