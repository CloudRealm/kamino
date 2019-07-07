import 'dart:convert';

import 'package:async/async.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart';
import 'package:kamino/animation/transition.dart';
import 'package:kamino/external/ExternalService.dart';
import 'package:kamino/external/api/tmdb.dart';
import 'package:kamino/generated/i18n.dart';
import 'package:kamino/interface/search/genre_search.dart';
import 'package:kamino/main.dart';
import 'package:kamino/models/content.dart';
import 'package:kamino/models/list.dart';
import 'package:kamino/ui/elements.dart';
import 'package:kamino/util/genre.dart';
import 'package:shimmer/shimmer.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:kamino/interface/search/curated_search.dart';

class BrowsePageState extends State<StatefulWidget> {

  Map<int, AsyncMemoizer> _curatedMemoizers = new Map();

  final List genreList;
  final ContentType type;

  BrowsePageState({
    @required this.genreList,
    @required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      child: ListView(
        children: <Widget>[
          SubtitleText(S.of(context).curated.toUpperCase(), padding: EdgeInsets.symmetric(horizontal: 15).copyWith(top: 20)),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints){
              double idealWidth = 200;
              double spacing = 10.0;

              return GridView.builder(
                padding: EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: (constraints.maxWidth / idealWidth).round(),
                  childAspectRatio: 2,
                  mainAxisSpacing: spacing,
                  crossAxisSpacing: spacing,
                ),
                itemCount: TMDB.curatedTMDBLists[type].length,
                itemBuilder: (BuildContext context, int index){
                  int listID = int.parse(TMDB.curatedTMDBLists[type][index]);
                  if(_curatedMemoizers[listID] == null)
                    _curatedMemoizers[listID] = new AsyncMemoizer();

                  return FutureBuilder(
                    future: _curatedMemoizers[listID].runOnce(() => Service.get<TMDB>().getList(context, listID)),
                    builder: (BuildContext context, AsyncSnapshot snapshot){
                      ContentListModel list = snapshot.data;

                      return Material(
                          type: MaterialType.card,
                          borderRadius: BorderRadius.circular(5),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            fit: StackFit.expand,
                            alignment: Alignment.center,
                            children: <Widget>[
                              !snapshot.hasData && !snapshot.hasError ? Shimmer.fromColors(
                                baseColor: const Color(0x8F000000),
                                highlightColor: const Color(0x4F000000),
                                child: Container(color: const Color(0x8F000000)),
                              ) : Container(),

                              snapshot.hasData ? CachedNetworkImage(
                                imageUrl: TMDB.IMAGE_CDN_LOWRES + list.backdrop,
                                fit: BoxFit.cover
                              ) : Container(),

                              snapshot.hasData || snapshot.hasError ? Container(
                                color: const Color(0x8F000000),
                                child: Center(child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 30
                                    ),
                                    child: snapshot.hasError
                                      ? Icon(Icons.error)
                                      : AutoSizeText(
                                          list.name,
                                          // We don't want to softWrap list names
                                          // with only one word.
                                          softWrap: list.name.contains(" "),
                                          maxLines: 2,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 18, color: Colors.white, fontFamily: 'GlacialIndifference'),
                                          maxFontSize: 18,
                                        )
                                )),
                              ) : Container(),

                              snapshot.hasData ? Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => Navigator.of(context).push(
                                      ApolloTransitionRoute(builder: (BuildContext context) => CuratedSearch(
                                          listName: list.name,
                                          listID: list.id,
                                          contentType: getRawContentType(list.content[0].contentType)
                                      ))
                                  ),
                                ),
                              ) : Container()
                            ],
                          )
                      );
                    }
                  );
                },
              );
            },
          ),

          // ALL GENRES
          SubtitleText(S.of(context).all_genres.toUpperCase(), padding: EdgeInsets.symmetric(horizontal: 15).copyWith(top: 20)),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints){
              double idealWidth = 200;
              double spacing = 10.0;

              return GridView.builder(
                padding: EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: (constraints.maxWidth / idealWidth).round(),
                  childAspectRatio: 2,
                  mainAxisSpacing: spacing,
                  crossAxisSpacing: spacing,
                ),
                itemCount: genreList.length,
                itemBuilder: (BuildContext context, int index){
                  final int genreId = genreList[index]['id'];
                  final String genreBanner = genreList[index]['banner'];
                  final String genreLabel = Genre.getFontImagePath(
                      type,
                      genreId
                  );

                  return Material(
                    type: MaterialType.card,
                    borderRadius: BorderRadius.circular(5),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      alignment: Alignment.center,
                      children: <Widget>[
                        CachedNetworkImage(
                          imageUrl: TMDB.IMAGE_CDN_LOWRES + genreBanner,
                          fit: BoxFit.cover,
                        ),

                        Container(
                          color: const Color(0x8F000000),
                          child: Center(child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 30
                              ),
                              height: 30,
                              child: SvgPicture.asset(genreLabel)
                          )),
                        ),

                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.of(context).push(
                                ApolloTransitionRoute(
                                    builder: (BuildContext context) => GenreSearch(
                                      genreID: genreId,
                                      genreName: Genre.resolveGenreName(
                                          getRawContentType(type),
                                          genreId
                                      ),
                                      contentType: getRawContentType(type),
                                    )
                                )
                            ),
                          ),
                        )
                      ],
                    )
                  );
                },
              );
            },
          )
        ],
      ),
    );
  }

  Future<List> fetchGenreData(int genreId) async {
    String url = "${TMDB.ROOT_URL}/discover/${getRawContentType(type)}"
        "${Service.get<TMDB>().getDefaultArguments(context)}&"
        "sort_by=popularity.desc&include_adult=false"
        "&include_video=false&"
        "page=1&with_genres=$genreId";

    var response = jsonDecode((await get(url)).body);
    // Status code 25 -> rate limit
    if(response['status_code'] != null && response['status_code'] == 25){
      await Future.delayed(Duration(seconds: 4));
      return await fetchGenreData(genreId);
    }

    return response['results'];
  }

}

class BrowseTVShowsPage extends KaminoAppPage {

  static const List genreList = Genre.tv;
  static const ContentType type = ContentType.TV_SHOW;

  @override
  State<StatefulWidget> createState() => BrowsePageState(
    genreList: genreList,
    type: type
  );

  @override
  Widget buildHeader(BuildContext context){
    return TitleText(S.of(context).tv_shows, fontSize: 26);
  }

}

class BrowseMoviesPage extends KaminoAppPage {

  static const List genreList = Genre.movie;
  static const ContentType type = ContentType.MOVIE;

  @override
  State<StatefulWidget> createState() => BrowsePageState(
      genreList: genreList,
      type: type
  );

  @override
  Widget buildHeader(BuildContext context){
    return TitleText(S.of(context).movies, fontSize: 26);
  }

}