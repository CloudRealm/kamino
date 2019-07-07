import 'dart:async';
import 'dart:io';
import 'package:async/async.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating/flutter_rating.dart';

import 'package:flutter/material.dart';
import 'package:kamino/animation/transition.dart';
import 'package:kamino/external/ExternalService.dart';
import 'package:kamino/external/api/tmdb.dart';
import 'package:kamino/external/api/trakt.dart';
import 'package:kamino/generated/i18n.dart';
import 'package:kamino/main.dart';
import 'package:kamino/models/content.dart';
import 'package:kamino/models/crew.dart';
import 'package:kamino/models/review.dart';

import 'package:kamino/partials/content_poster.dart';
import 'package:kamino/res/bottom_gradient.dart';
import 'package:kamino/ui/elements.dart';
import 'package:kamino/ui/interface.dart';
import 'package:kamino/interface/search/genre_search.dart';
import 'package:kamino/interface/content/movie_layout.dart';
import 'package:kamino/interface/content/tv_show_layout.dart';
import 'package:kamino/ui/loading.dart';

import 'package:kamino/util/database_helper.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/*  CONTENT OVERVIEW WIDGET  */
///
/// The ContentOverview widget allows you to show information about Movie or TV show.
///
class ContentOverview extends StatefulWidget {
  final int contentId;
  final ContentType contentType;

  ContentOverview(
      {Key key, @required this.contentId, @required this.contentType})
      : super(key: key);

  @override
  _ContentOverviewState createState() => new _ContentOverviewState();
}

///
/// _ContentOverviewState is completely independent of the content type.
/// In the widget build section, you can add a reference to the body layout for your content type.
/// _data will be a ContentModel. You should look at an example model to cast this to your content type.
///
class _ContentOverviewState extends State<ContentOverview> {

  final AsyncMemoizer _memoizer = new AsyncMemoizer();

  String rawContentType;
  bool isFavorite = false;

  TextSpan titleSpan = TextSpan();
  bool hasLongTitle = false;

  String _trailer;
  List<CrewMemberModel> crew;
  List<CastMemberModel> cast;

  @override
  void initState() {
    rawContentType = getRawContentType(widget.contentType);
    super.initState();
  }

  // Load the data from the source.
  Future<ContentModel> fetchOverviewData() async {
    isFavorite = await DatabaseHelper.isFavorite(widget.contentId);

    ContentModel contentInfo = await Service.get<TMDB>().getContentInfo(
        context,
        widget.contentType,
        widget.contentId,
        appendToResponse: "credits,videos,recommendations,reviews"
    );

    // Load trailer
    List<dynamic> videos = contentInfo.videos;
    if(videos != null && videos.isNotEmpty && videos.where((video) => video['type'] == 'Trailer').length > 0) {
      var video = videos.firstWhere((video) => video['type'] == 'Trailer');
      _trailer = video != null ? video['key'] : null;
    }

    // Load cast & crew
    cast = contentInfo.cast != null ? contentInfo.cast : [];
    crew = contentInfo.crew != null ? contentInfo.crew : [];

    return contentInfo;
  }

  // TODO: Rewrite logic for the favorites button
  _favButtonLogic(BuildContext context, ContentModel content) async {

    if (isFavorite) {

      //remove the show from the database
      DatabaseHelper.removeFavoriteById(widget.contentId);

      if(await Service.get<Trakt>().isAuthenticated()) Service.get<Trakt>().removeFavoriteFromTrakt(
        context,
        id: widget.contentId,
        type: widget.contentType,
      );

      Interface.showSnackbar(S.of(context).removed_from_favorites, context: context, backgroundColor: Colors.red);

      //set fav to false to reflect change
      setState(() {
        isFavorite = false;
      });

    } else if (isFavorite == false){

      //add the show to the database
      DatabaseHelper.saveFavorite(content);

      if(await Service.get<Trakt>().isAuthenticated()) Service.get<Trakt>().sendFavoriteToTrakt(
        context,
        id: widget.contentId,
        type: widget.contentType,
        title: content.title,
        year: content.releaseDate != null ? content.releaseDate.substring(0,4) : null,
      );

      //show notification snackbar
      Interface.showSnackbar(S.of(context).added_to_favorites, context: context);

      //set fav to true to reflect change
      setState(() {
        isFavorite = true;
      });
    }
  }

  /* THE FOLLOWING CODE IS JUST LAYOUT CODE. */

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _memoizer.runOnce(() => fetchOverviewData()),
      builder: (BuildContext context, AsyncSnapshot snapshot){
        if(snapshot.connectionState == ConnectionState.none || snapshot.hasError){
          // If the user is offline show the appropriate message.
          if(snapshot.error is SocketException || snapshot.error is HttpException) {
            return OfflineMixin();
          }

          // Otherwise an error must have occurred.
          print(snapshot.error);
          return ErrorLoadingMixin(errorMessage: "Well this is awkward... An error occurred whilst loading this ${getPrettyContentType(widget.contentType)}.");
        }

        switch(snapshot.connectionState){
          case ConnectionState.none:
          case ConnectionState.waiting:
          case ConnectionState.active:
            return Scaffold(
                backgroundColor: Theme.of(context).backgroundColor,
                body: Center(
                    child: ApolloLoadingSpinner()
                )
            );
          case ConnectionState.done:
            ContentModel content = snapshot.data;

            /* BEGIN: Render title */
            titleSpan = new TextSpan(
                text: content.title,
                style: TextStyle(
                    fontFamily: 'GlacialIndifference',
                    fontSize: 19,
                    color: Theme.of(context).primaryTextTheme.title.color
                )
            );

            var titlePainter = new TextPainter(
                text: titleSpan,
                maxLines: 1,
                textAlign: TextAlign.start,
                textDirection: Directionality.of(context)
            );

            titlePainter.layout(maxWidth: MediaQuery.of(context).size.width - 160);
            hasLongTitle = titlePainter.didExceedMaxLines;
            /* END: Render title */

            return new Scaffold(
                backgroundColor: Theme.of(context).backgroundColor,
                body: Stack(
                  children: <Widget>[
                    NestedScrollView(
                        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                          return <Widget>[
                            SliverAppBar(
                              backgroundColor: Theme.of(context).backgroundColor,
                              actions: <Widget>[
                                CastButton(),

                                IconButton(
                                  icon: Icon(
                                    isFavorite ? Icons.favorite : Icons.favorite_border,
                                    color: isFavorite ? Colors.red : Theme.of(context).primaryTextTheme.body1.color,
                                  ),
                                  onPressed: (){
                                    _favButtonLogic(context, content);
                                  },
                                ),
                              ],
                              expandedHeight: 200.0,
                              floating: false,
                              pinned: true,
                              flexibleSpace: FlexibleSpaceBar(
                                centerTitle: true,
                                title: LayoutBuilder(builder: (context, size){
                                  var titleTextWidget = new RichText(
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    text: titleSpan,
                                  );

                                  if(hasLongTitle) return Container();

                                  return ConstrainedBox(
                                      constraints: BoxConstraints(
                                          maxWidth: size.maxWidth - 160
                                      ),
                                      child: titleTextWidget
                                  );
                                }),
                                background: _generateBackdropImage(context, content),
                                collapseMode: CollapseMode.pin,
                              ),
                            )
                          ];
                        },
                        body: Container(
                            child: NotificationListener<OverscrollIndicatorNotification>(
                              onNotification: (notification){
                                if(notification.leading){
                                  notification.disallowGlow();
                                }
                              },
                              child: ListView(

                                  children: <Widget>[
                                    // This is the summary line, just below the title.
                                    _generateOverviewWidget(context, content),

                                    // Content Widgets
                                    Padding(
                                        padding: EdgeInsets.symmetric(vertical: 20.0).copyWith(top: 5),
                                        child: Column(
                                          children: <Widget>[
                                            /*
                                            * If you're building a row widget, it should have a horizontal
                                            * padding of 24 (narrow) or 16 (wide).
                                            *
                                            * If your row is relevant to the last, use a vertical padding
                                            * of 5, otherwise use a vertical padding of 5 - 10.
                                            *
                                            * Relevant means visually and by context.
                                            */
                                            Padding(
                                              padding: EdgeInsets.only(
                                                bottom: 20
                                              ),
                                              child: _generateGenreChipsRow(context, content),
                                            ),
                                            _generateSynopsisSection(content),
                                            _generateButtonSection(content),
                                            _generateEditorsChoice(),
                                            _generateCastAndCrewInfo(),

                                            // Context-specific layout
                                            _generateLayout(widget.contentType, content),

                                            _generateRecommendedContentCards(context, content),
                                            _generateReviewsSection(context, content)
                                          ],
                                        )
                                    )
                                  ]
                              ),
                            )
                        )
                    ),

                    Positioned(
                      left: -7.5,
                      right: -7.5,
                      bottom: 30,
                      child: Container(
                          child: _getFloatingActionButton(
                              widget.contentType,
                              context,
                              content
                          )
                      ),
                    )
                  ],
                ),
                floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling
            );
        }
      }
    );
  }

  ///
  /// OverviewWidget -
  /// This is the summary line just below the title.
  ///
  Widget _generateOverviewWidget(BuildContext context, ContentModel content){
    return new Padding(
      padding: EdgeInsets.only(bottom: 5.0, left: 30, right: 30),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            hasLongTitle ? Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: TitleText(
                content.title,
                allowOverflow: true,
                textAlign: TextAlign.center,
                fontSize: 23,
              ),
            ) : Container(),

            Text(
                content.releaseDate != "" && content.releaseDate != null ?
                  "${S.of(context).released}: ${DateTime.parse(content.releaseDate).year.toString()}" :
                  S.of(context).unknown_x(S.of(context).year),
                style: TextStyle(
                    fontFamily: 'GlacialIndifference',
                    fontSize: 16.0
                )
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                StarRating(
                  rating: content.rating / 2, // Ratings are out of 10 from our source.
                  color: Theme.of(context).primaryColor,
                  borderColor: Theme.of(context).primaryColor,
                  size: 16.0,
                  starCount: 5,
                ),
                Text(
                  "  \u2022  ${S.of(context).n_ratings(content.voteCount.toString())}",
                  style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold
                  )
                )
              ],
            )
          ]
      ),
    );
  }

  ///
  /// BackdropImage (Subwidget) -
  /// This controls the background image and stacks the gradient on top
  /// of the image.
  ///
  Widget _generateBackdropImage(BuildContext context, ContentModel content){
    double contextWidth = MediaQuery.of(context).size.width;

    return Container(
      height: 220,
      child: Stack(
        fit: StackFit.expand,
        alignment: AlignmentDirectional.bottomCenter,
        children: <Widget>[
          Container(
              child: content.backdropPath != null ?
                CachedNetworkImage(
                  imageUrl: TMDB.IMAGE_CDN + content.backdropPath,
                  fit: BoxFit.cover,
                  placeholder: (BuildContext context, String url) => Container(),
                  height: 220.0,
                  width: contextWidth,
                  errorWidget: (BuildContext context, String url, error) => new Icon(Icons.error, size: 30.0)
                ) :
              new Icon(Icons.error, size: 30.0)
          ),

          !hasLongTitle ?
          BottomGradient(color: Theme.of(context).backgroundColor)
              : BottomGradient(offset: 1, finalStop: 0, color: Theme.of(context).backgroundColor),
        ],
      ),
    );
  }

  ///
  /// GenreChipsRowWidget -
  /// This is the row of purple genre chips.
  showGenrePage(String mediaType, int id, String genreName) {
    if (mediaType == "tv"){
      Navigator.push(
          context,
          ApolloTransitionRoute(
              builder: (context) =>
                  GenreSearch(
                      contentType: "tv",
                      genreID: id,
                      genreName: genreName )
          )
      );
    } else if (mediaType == "movie"){
      Navigator.push(
          context,
          ApolloTransitionRoute(
              builder: (context) =>
                  GenreSearch(
                      contentType: "movie",
                      genreID: id,
                      genreName: genreName )
          )
      );
    }
  }

  Widget _generateGenreChipsRow(BuildContext context, ContentModel content){
    return content.genres == null ? Container() : SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 40.0,
      child: Container(
        child: Center(
          // We want the chips to overflow.
          // This can't seem to be done with a ListView.
          child: Builder(builder: (BuildContext context){
            var chips = <Widget>[];

            for(int index = 0; index < content.genres.length; index++){
              chips.add(
                  Container(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(100),
                      onTap: (){
                        showGenrePage(rawContentType,
                            content.genres[index]["id"], content.genres[index]["name"]);
                      },
                      child: Padding(
                        padding: index != 0
                            ? EdgeInsets.only(left: 6.0, right: 6.0)
                            : EdgeInsets.only(left: 6.0, right: 6.0),
                        child: new Chip(
                          label: Text(
                            content.genres[index]["name"],
                            style: TextStyle(color: Theme.of(context).accentTextTheme.body1.color, fontSize: 15.0),
                          ),
                          backgroundColor: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  )
              );
            }

            return Wrap(
              alignment: WrapAlignment.center,
              children: chips,
            );
          }),

        )
      )
    );
  }

  Widget _generateButtonSection(ContentModel model){

    Function _generateButtonsList = ({bool shouldExpand = false}){
      return <Widget>[
        (widget.contentType == ContentType.MOVIE) ? Flexible(child: Container(
          padding: EdgeInsets.symmetric(horizontal: 5),
          child: FlatButton.icon(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5)
            ),
            color: Theme.of(context).primaryColor,
            icon: Icon(Icons.play_arrow),
            label: Text(S.of(context).play_movie),
            onPressed: () async {
              KaminoAppState application = context.ancestorStateOfType(const TypeMatcher<KaminoAppState>());
              (await application.getPrimaryVendorService()).playMovie(
                  model,
                  context
              );
            },
          ),
        ), fit: shouldExpand ? FlexFit.tight : FlexFit.loose) : Container(),

        Flexible(child: Container(
          padding: EdgeInsets.symmetric(horizontal: 5),
          child: FlatButton.icon(
            highlightColor: Theme.of(context).primaryColor.withOpacity(0.2),
            padding: EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
                side: widget.contentType == ContentType.MOVIE ? BorderSide(color: Theme.of(context).primaryColor, width: 2) : BorderSide(),
                borderRadius: BorderRadius.circular(5)
            ),
            color: widget.contentType == ContentType.MOVIE ? null : Theme.of(context).primaryColor,
            icon: Icon(Icons.video_library, size: 18),
            label: Text(S.of(context).play_trailer),
            onPressed: (){
              Interface.launchURL("https://www.youtube.com/watch?v=$_trailer");
            },
          ),
        ), fit: shouldExpand ? FlexFit.tight : FlexFit.loose)
      ];
    };

    return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints){
      if(constraints.maxWidth < 400) return Container(
        width: constraints.maxWidth,
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20).copyWith(top: 25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _generateButtonsList(),
        ),
      );

      return Container(
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20).copyWith(top: 25),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _generateButtonsList(shouldExpand: true),
        ),
      );
    });
  }

  ///
  /// This function generates the Synopsis Card.
  ///
  Widget _generateSynopsisSection(ContentModel content){
    return Padding(
      padding: EdgeInsets.only(top: 0, left: 16.0, right: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          /*SubtitleText(
            S.of(context).synopsis,
          ),*/
          Container(
            padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5),
            child: ConcealableText(
              content.overview != "" ?
                content.overview :
                // e.g: 'This TV Show has no synopsis available.'
                S.of(context).this_x_has_no_synopsis_available(getPrettyContentType(widget.contentType)),

              maxLines: 5,
              revealLabel: S.of(context).show_more,
              concealLabel: S.of(context).show_less,
              color: const Color(0xFFBCBCBC)
            )
          )
        ],
      ),
    );
  }
  
  ///
  /// This function generates the cast and crew cards.
  /// 
  Widget _generateCastAndCrewInfo({bool emptyOnFail = true}){
    if(emptyOnFail && (cast == null || crew == null || cast.isEmpty || crew.isEmpty))
      return Container();

    List<PersonModel> castAndCrew = List.from(crew.length > 3 ? crew.sublist(0, 3) : crew, growable: true);
    castAndCrew.addAll(cast);

    // Remove any with an invalid name, job/character, profile
    castAndCrew.removeWhere((entry) => entry.name == null);
    castAndCrew.removeWhere((entry) => entry.role == null);
    castAndCrew.removeWhere((entry) => entry.profilePath == null);

    // Remove duplicates, leaving just the crew entry.
    // (Duplicates will happen when cast is also crew.)
    //
    // The justification for leaving the crew over the cast is that when a crew
    // member is also a cast member, it's usually because they are an important
    // crew member.
    // Crew job names can be shorter than character names which looks better.
    castAndCrew.removeWhere((entry) => castAndCrew.firstWhere((_e) => _e.name == entry.name) != entry);

    return Container(
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16).copyWith(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SubtitleText(S.of(context).cast_and_crew),

          Container(
            height: 100,
            child: NotificationListener<OverscrollIndicatorNotification>(
              onNotification: (notification){
                notification.disallowGlow();
                return false;
              },
              child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: castAndCrew.length,
                  itemBuilder: (BuildContext context, int index){
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          // Profile Image
                          Expanded(
                              child: Container(
                                margin: EdgeInsets.symmetric(vertical: 10),
                                child: ClipRRect(
                                    borderRadius: BorderRadius.circular(100),
                                    child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
                                      return CachedNetworkImage(
                                        height: constraints.maxHeight,
                                        width: constraints.maxHeight,
                                        placeholder: (BuildContext context, String url) => Image.memory(kTransparentImage),
                                        imageUrl: TMDB.IMAGE_CDN +
                                            castAndCrew[index].profilePath,
                                        fit: BoxFit.cover,
                                      );
                                    })
                                ),
                              )
                          ),

                          // Name
                          Text(castAndCrew[index].name, style: TextStyle(
                              fontFamily: 'GlacialIndifference',
                              fontSize: 16
                          )),

                          // Character or job
                          Text(
                            castAndCrew[index].role.contains(" / ") ? castAndCrew[index].role.split(" / ")[0] : castAndCrew[index].role,
                            style: TextStyle(
                                color: Colors.white54
                            ),
                          ),
                        ],
                      ),
                    );
                  }
              )
            )
          )
        ],
      ),
    );
  }

  Widget _generateEditorsChoice(){
    return FutureBuilder(
      future: DatabaseHelper.selectEditorsChoice(widget.contentId),
      builder: (BuildContext context, AsyncSnapshot snapshot){
        if(snapshot.hasError || !snapshot.hasData || snapshot.data == null)
          return Container();

        EditorsChoice editorsChoice = snapshot.data;
        return Container(
          margin: EdgeInsets.all(20).copyWith(bottom: 0),
          child: Card(
            elevation: 5,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 5, horizontal: 15).copyWith(bottom: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(bottom: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        Icon(Icons.stars, size: 14, color: Theme.of(context).primaryTextTheme.display3.color),
                        SubtitleText(S.of(context).editors_choice)
                      ],
                    ),
                  ),
                  Text(editorsChoice.comment)
                ]
              ),
            ),
          )
        );
      },
    );
  }

  static Widget _generateRecommendedContentCards(BuildContext context, ContentModel model){
    if(model.recommendations == null || model.recommendations.length < 1)
      return Container();

    return Padding(
        padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 0),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 30.0),
          child: Column(
              children: <Widget>[

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                        title: SubtitleText(
                          model.contentType == ContentType.TV_SHOW
                            ? S.of(context).recommended_tv_shows
                            : S.of(context).recommended_movies
                        )
                    ),

                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        itemCount: model.recommendations.length,
                        itemBuilder: (BuildContext context, int index) {
                          return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 5)
                                  .copyWith(left: index == 0 ? 25 : 5, top: 0),
                              child: AspectRatio(
                                aspectRatio: 2 / 3,
                                child: ContentPoster(
                                    onTap: () => Navigator.push(
                                        context,
                                        ApolloTransitionRoute(
                                          builder: (context) => ContentOverview(
                                              contentId: model.recommendations[index].id,
                                              contentType: model.contentType
                                          ),
                                        )
                                    ),
                                    mediaType: getRawContentType(model.contentType),
                                    name: model.recommendations[index].title,
                                    background: model.recommendations[index].posterPath,
                                    releaseDate: model.recommendations[index].releaseDate
                                ),
                              )
                          );
                        }
                      )
                    )
                  ],
                )

              ]
          ),
        )
    );
  }

  Widget _generateReviewsSection(BuildContext context, ContentModel model){
    if(model.reviews == null || model.reviews.length < 1) return Container();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 10),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SubtitleText(S.of(context).reviews),

            Column(children: List.generate(3, (int index){
              if(model.reviews.length <= index) return Container();

              ReviewModel review = model.reviews[index];
              return Container(
                margin: EdgeInsets.only(bottom: 20),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 5),
                  title: TitleText("${review.author} \u2022 TMDB"),
                  subtitle: Container(
                    padding: EdgeInsets.only(top: 5),
                    child: ConcealableMarkdownText(
                      MarkdownBody(
                        styleSheet: MarkdownStyleSheet(
                          p: Theme.of(context).textTheme.caption,
                          strong: Theme.of(context).textTheme.caption.copyWith(fontWeight: FontWeight.bold),
                          em: Theme.of(context).textTheme.caption.copyWith(fontStyle: FontStyle.italic),
                        ),
                        data: review.content.replaceAll("\n", "  \n\n"),
                        onTapLink: (String link) => {}
                      ),
                      revealLabel: S.of(context).show_more,
                      concealLabel: S.of(context).show_less,
                      maxLines: 5,
                    ),
                  ),
                ),
              );
            }))
          ]
      )
    );
  }

  ///
  /// generateLayout -
  /// This generates the remaining layout for the specific content type.
  /// It is a good idea to reference another class to keep this clean.
  ///
  Widget _generateLayout(ContentType contentType, ContentModel content) {
    switch(contentType){
      case ContentType.TV_SHOW:
        // Generate TV show information
        return TVShowLayout.generate(context, content);
      case ContentType.MOVIE:
        // Generate movie information
        return MovieLayout.generate(context, content);
      default:
        return Container();
    }
  }

  ///
  /// getFloatingActionButton -
  /// This works like the generateLayout method above.
  /// This is used to add a floating action button to the layout.
  /// Just return null if your layout doesn't need a floating action button.
  ///
  Widget _getFloatingActionButton(ContentType contentType, BuildContext context, ContentModel model){
    switch(contentType){
      case ContentType.MOVIE:
        return MovieLayout.getFloatingActionButton(context, model);
      default:
        return null;
    }
  }
}
