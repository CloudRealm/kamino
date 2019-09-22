import 'dart:async';

import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape_small.dart';
import 'package:intl/intl.dart';
import 'package:kamino/external/ExternalService.dart';
import 'package:kamino/external/api/tmdb.dart';
import 'package:kamino/generated/i18n.dart';
import 'package:kamino/models/content/content.dart';
import 'package:kamino/models/content/movie.dart';
import 'package:kamino/models/content/tv_show.dart';
import 'package:kamino/models/person.dart';
import 'package:kamino/ui/elements.dart';
import 'package:kamino/ui/loading.dart';
import 'package:transparent_image/transparent_image.dart';

class PersonPage extends StatefulWidget {

  final PersonModel person;

  PersonPage({
    @required this.person
  });

  @override
  State<StatefulWidget> createState() => PersonPageState();

}

class PersonPageState extends State<PersonPage> {

  PersonModel person;
  double _elevation;

  @override
  void initState() {
    _elevation = 0;
    loadFullProfile().then((PersonModel _person){
      setState(() {
        person = _person;
      });
    });

    super.initState();
  }

  Future<PersonModel> loadFullProfile() async {
    PersonModel fullProfile = await Service.get<TMDB>().getPerson(context, widget.person.id);
    setState(() {
      person = fullProfile;
    });
    return person;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener(
      onNotification: (notification){
        if(notification is OverscrollIndicatorNotification){
          if(notification.leading) notification.disallowGlow();
          return true;
        }

        if(notification is ScrollNotification){
          double elevation = _elevation;

          if(notification.metrics.pixels > 0) elevation = 12;
          else elevation = 0;

          if(_elevation != elevation) setState(() {
            _elevation = elevation;
          });
        }

        return false;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        appBar: AppBar(
          elevation: _elevation,
          backgroundColor: Theme.of(context).backgroundColor,
          title: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              TitleText(widget.person.name),
              if(person != null && person.alsoKnownAs.length > 0) PersonAlsoKnownAs(person.alsoKnownAs)
            ],
          ),
          centerTitle: true,
        ),
        body: Builder(builder: (BuildContext context){
          if(person == null) return Center(
            child: ApolloLoadingSpinner(),
          );

          String age = "-";
          if(person.birthday != null) age = (DateTime.now().difference(DateTime.parse(person.birthday)).inDays / 365.2422).round().toString();
          if(person.name == "Keanu Reeves") age = "\u221E";

          return ListView(
            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[

                  Container(
                    margin: EdgeInsetsDirectional.only(end: 25),
                    height: 96,
                    width: 96,
                    child: Material(
                      elevation: 4,
                      shape: CircleBorder(),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        clipBehavior: Clip.antiAlias,
                        child: FadeInImage.memoryNetwork(
                          placeholder: kTransparentImage,
                          image: TMDB.IMAGE_CDN + widget.person.profilePath,
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                  Expanded(child: Container(
                    height: 96,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[

                        if(person.knownForDepartment != null) ...[
                          Text("Known For", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(person.knownForDepartment),
                        ],

                        Container(margin: EdgeInsets.only(top: 10)),

                        if(person.birthday != null) ...[
                          Text("Born", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                              DateFormat("MMMM d, yyyy").format(DateTime.parse(person.birthday)) + " (Age: $age)"
                          ),
                          if(person.placeOfBirth != null) Text(person.placeOfBirth)
                        ]

                      ],
                    ),
                  ))

                ],
              ),

              if(person.biography != null) Container(
                margin: EdgeInsets.symmetric(vertical: 30),
                child: ConcealableText(
                  HtmlUnescape().convert(person.biography),
                  revealLabel: S.of(context).show_more,
                  concealLabel: S.of(context).show_less,
                  maxLines: 6,
                  color: Colors.grey,
                ),
              ),

              FutureBuilder(
                future: Future(() async {
                  return {
                    ContentType.TV_SHOW: await Service.get<TMDB>().loadCreditsFor(context, ContentType.TV_SHOW, person),
                    ContentType.MOVIE: await Service.get<TMDB>().loadCreditsFor(context, ContentType.MOVIE, person),
                  };
                }),
                builder: (BuildContext context, AsyncSnapshot snapshot){
                  if(!snapshot.hasData) return Center(
                    child: ApolloLoadingSpinner(),
                  );

                  return Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if(snapshot.data[ContentType.TV_SHOW].length > 0) ...[
                          SubtitleText(S.of(context).tv_shows),
                          ResponsiveContentGrid(
                            idealItemWidth: 150,
                            spacing: 10.0,
                            margin: 0,
                            content: snapshot.data[ContentType.TV_SHOW],
                          ),
                          Container(margin: EdgeInsets.only(top: 20))
                        ],

                        if(snapshot.data[ContentType.MOVIE].length > 0) ...[
                          SubtitleText(S.of(context).movies),
                          ResponsiveContentGrid(
                            idealItemWidth: 150,
                            spacing: 10.0,
                            margin: 0,
                            content: snapshot.data[ContentType.MOVIE],
                          ),
                        ]
                      ]
                  );
                },
              ),
            ],
          );
        }),
      )
    );
  }

}

class PersonAlsoKnownAs extends StatefulWidget {

  final List<String> aliases;
  PersonAlsoKnownAs(this.aliases);

  @override
  State<StatefulWidget> createState() => PersonAlsoKnownAsState();

}

class PersonAlsoKnownAsState extends State<PersonAlsoKnownAs> {

  Timer timer;
  int currentAlias = 0;

  @override
  void initState() {
    timer = new Timer.periodic(Duration(seconds: 3), (Timer timer){
      if(mounted) setState(() {
        if(currentAlias < widget.aliases.length - 1) currentAlias++;
        else currentAlias = 0;
      });
    });

    super.initState();
  }

  @override
  void deactivate() {
    timer.cancel();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      transitionBuilder: (Widget child, Animation<double> animation){
        return FadeTransition(child: child, opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut
        ));
      },
      child: Text(
        widget.aliases[currentAlias],
        key: ValueKey<String>(widget.aliases[currentAlias]),
        style: Theme.of(context).textTheme.caption
      )
    );
  }

}