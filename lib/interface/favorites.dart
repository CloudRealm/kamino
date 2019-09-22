import 'package:flutter/material.dart';
import 'package:kamino/generated/i18n.dart';
import 'package:kamino/main.dart';
import 'package:kamino/models/content/content.dart';
import 'package:kamino/ui/elements.dart';
import 'package:kamino/ui/loading.dart';
import 'package:kamino/util/database_helper.dart';
import 'package:kamino/util/settings.dart';

class FavoritesPage extends KaminoAppPage {

  @override
  FavoritesPageState createState() => new FavoritesPageState();

  @override
  Widget buildHeader(BuildContext context){
    return TitleText(S.of(context).favorites, fontSize: 26);
  }

}

class FavoritesPageState extends State<FavoritesPage>
    with SingleTickerProviderStateMixin {

  Map<String, List<FavoriteDocument>> favorites;
  bool tvExpanded;
  bool movieExpanded;

  String sortMethod;
  bool sortReversed;

  _getFavorites() async {
    favorites = await DatabaseHelper.getAllFavorites();
    favorites.values.forEach((favoritesList) => favoritesList.removeWhere(
        (FavoriteDocument favorite) => favorite.name == null || favorite.tmdbId == null
    ));
    if(mounted) setState(() {});
  }

  @override
  void initState() {
    tvExpanded = true;
    movieExpanded = true;

    sortMethod = 'name';
    sortReversed = false;

    (Settings.favoritesSortSettings as Future).then((sortingSettings){
      setState(() {
        if(sortingSettings.length != 2) return;
        this.sortMethod = sortingSettings[0];
        this.sortReversed = sortingSettings[1] == "true";
      });

      _getFavorites();
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if(favorites == null){
      return Center(
        child: ApolloLoadingSpinner(),
      );
    }

    // If every sublist in favorites is empty, the user has no favorites.
    bool favoritesEmpty = favorites.values.every((List subList) => subList.isEmpty);
    return Scaffold(
      floatingActionButton: favoritesEmpty ? null : FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        onPressed: () async {
          var sortSettings = await showDialog(
            context: context,
            builder: (BuildContext context) => FavoritesSortingDialog(
              sortingMethod: sortMethod,
              sortReversed: sortReversed,
            )
          );

          if(sortSettings == null || sortSettings.length != 2) return;
          setState(() {
            this.sortMethod = sortSettings[0];
            this.sortReversed = sortSettings[1];
          });
        },
        child: Icon(Icons.sort),
      ),
      backgroundColor: Theme.of(context).backgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(Duration(milliseconds: 500));
          _getFavorites();
        },
        child: Builder(builder: (BuildContext context){
          if(favoritesEmpty){
            return noFavoritesWidget();
          }

          return Container(
              color: Theme.of(context).backgroundColor,
              child: ListView(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(top: 20, bottom: 10),
                    child: Column(children: <Widget>[
                      (favorites['tv'].length > 0) ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          GestureDetector(child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            color: Colors.transparent,
                            child: Row(children: <Widget>[
                              SubtitleText(S.of(context).tv_shows),
                              Icon(tvExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down)
                            ], mainAxisAlignment: MainAxisAlignment.spaceBetween),
                          ), onTap: () => setState(() => tvExpanded = !tvExpanded)),
                          tvExpanded ? _buildSection(ContentType.TV_SHOW, sortMethod, sortReversed) : Container(),

                          Container(margin: EdgeInsets.symmetric(vertical: 10)),
                        ],
                      ) : Container(),

                      (favorites['movie'].length > 0) ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          GestureDetector(child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            color: Colors.transparent,
                            child: Row(children: <Widget>[
                              SubtitleText(S.of(context).movies),
                              Icon(movieExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down)
                            ], mainAxisAlignment: MainAxisAlignment.spaceBetween),
                          ), onTap: () => setState(() => movieExpanded = !movieExpanded)),
                          movieExpanded ? _buildSection(ContentType.MOVIE, sortMethod, sortReversed) : Container(),

                          Container(margin: EdgeInsets.symmetric(vertical: 10)),
                        ],
                      ) : Container(),
                    ], crossAxisAlignment: CrossAxisAlignment.start),
                  ),
                ],
              )
          );
        })
      )
    );
  }

  Widget _buildSection(ContentType type, String sortMethod, bool sortReversed) {
    List<FavoriteDocument> sectionList = favorites[getRawContentType(type)];
    switch(sortMethod){
      case 'name':
        sectionList.sort((FavoriteDocument left, FavoriteDocument right){
          return left.name.compareTo(right.name);
        });
        break;

      case 'date':
      default:
        sectionList.sort((FavoriteDocument left, FavoriteDocument right){
          return left.savedOn.compareTo(right.savedOn);
        });
    }
    if(sortReversed) sectionList = sectionList.reversed.toList();

    List<ContentModel> content = sectionList.map((FavoriteDocument document) => document.toContentModel()).toList();
    return ResponsiveContentGrid(
      idealItemWidth: 150,
      spacing: 10.0,
      margin: 10.0,
      content: content,
    );
  }

  Widget noFavoritesWidget() {
    return LayoutBuilder(builder: (BuildContext context, BoxConstraints viewportConstraints){
      return ListView(
        children: <Widget>[
          SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: viewportConstraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.favorite_border, size: 64),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: TitleText(
                          S.of(context).no_favorites_header,
                          fontSize: 28,
                        ),
                      ),
                      Text(
                          S.of(context).no_favorites_description,
                          textAlign: TextAlign.center
                      )
                    ],
                  )
                ),
              ),
            ),
          )
        ],
      );
    });
  }
  
  @override
  void dispose() {
    super.dispose();
  }
}


class FavoritesSortingDialog extends StatefulWidget {

  final String sortingMethod;
  final bool sortReversed;

  FavoritesSortingDialog({
    @required this.sortingMethod,
    @required this.sortReversed
  });

  @override
  State<StatefulWidget> createState() => FavoritesSortingDialogState();

}

class FavoritesSortingDialogState extends State<FavoritesSortingDialog> {

  String sortingMethod;
  bool sortReversed;

  @override
  void initState() {
    sortingMethod = widget.sortingMethod;
    sortReversed = widget.sortReversed;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 10).copyWith(top: 20),
      title: TitleText(S.of(context).sort_by),
      children: <Widget>[

        Column(
            children: [Column(
              children: <Widget>[
                RadioListTile(
                  secondary: (MediaQuery.of(context).size.width >= 300) ? Icon(Icons.sort_by_alpha) : null,
                  title: Text(S.of(context).name),
                  subtitle: Text(S.of(context).sorts_alphabetically_by_name),
                  value: 'name',
                  groupValue: sortingMethod,
                  onChanged: (value){
                    setState(() {
                      sortingMethod = value;
                    });
                  },
                  activeColor: Theme.of(context).primaryColor,
                  controlAffinity: ListTileControlAffinity.trailing,
                ),
                RadioListTile(
                  secondary: (MediaQuery.of(context).size.width >= 300) ? Icon(Icons.calendar_today) : null,
                  title: Text(S.of(context).date_added),
                  subtitle: Text(S.of(context).sorts_by_date_added),
                  value: 'date',
                  groupValue: sortingMethod,
                  onChanged: (value){
                    setState(() {
                      sortingMethod = value;
                    });
                  },
                  activeColor: Theme.of(context).primaryColor,
                  controlAffinity: ListTileControlAffinity.trailing,
                )
              ],
            )
            ]),

        Builder(builder: (BuildContext context){
          var _orderButtons = <Widget>[
            FlatButton.icon(
                color: !sortReversed ? Theme.of(context).primaryColor : null,
                onPressed: () async {
                  sortReversed = false;
                  setState(() {});
                },
                icon: Icon(Icons.keyboard_arrow_up),
                label: TitleText(S.of(context).ascending)
            ),
            FlatButton.icon(
                color: sortReversed ? Theme.of(context).primaryColor : null,
                onPressed: () async {
                  sortReversed = true;
                  setState(() {});
                },
                icon: Icon(Icons.keyboard_arrow_down),
                label: TitleText(S.of(context).descending)
            )
          ];

          if(MediaQuery.of(context).size.width < 300){
            return Container(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: ListView(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  children: _orderButtons
              ),
            );
          }else{
            return Container(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _orderButtons
              ),
            );
          }
        }),

        Container(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              new FlatButton(
                padding: EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onPressed: (){
                  Navigator.of(context).pop();
                },
                child: Text(S.of(context).cancel),
                textColor: Theme.of(context).primaryColor,
              ),

              new FlatButton(
                padding: EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onPressed: (){
                  (() async {
                    List sortingSettings = [sortingMethod, sortReversed.toString()];
                    await (Settings.favoritesSortSettings = sortingSettings);
                    setState(() {});
                  })();
                  Navigator.of(context).pop([sortingMethod, sortReversed]);
                },
                child: Text(S.of(context).done),
                textColor: Theme.of(context).primaryColor,
              )
            ],
          ),
        )
      ],
    );
  }

}