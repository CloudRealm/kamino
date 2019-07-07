import 'package:async/async.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:kamino/external/ExternalService.dart';
import 'package:kamino/external/api/realdebrid.dart';
import 'package:kamino/external/api/trakt.dart';
import 'package:kamino/generated/i18n.dart';
import 'package:kamino/ui/elements.dart';
import 'package:kamino/interface/settings/page.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kamino/ui/interface.dart';
import 'package:kamino/ui/loading.dart';
import 'package:transparent_image/transparent_image.dart';

class ExtensionsSettingsPage extends SettingsPage {
  ExtensionsSettingsPage(BuildContext context) : super(
      title: S.of(context).extensions,
      pageState: ExtensionsSettingsPageState()
  );
}

class ExtensionsSettingsPageState extends SettingsPageState {

  AsyncMemoizer<RealDebridUser> _realDebridUserInfoMemoizer = new AsyncMemoizer();

  bool traktAuthenticated = false;
  bool rdAuthenticated = false;

  @override
  void initState(){
    // Check if the services are authenticated.
    (() async {
      traktAuthenticated = await Service.get<Trakt>().isAuthenticated();
      rdAuthenticated = await Service.get<RealDebrid>().isAuthenticated();
      setState(() {});
    })();


    super.initState();
  }

  @override
  Widget buildPage(BuildContext context) {

    return ListView(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      children: <Widget>[

        SubtitleText(S.of(context).content_trackers),

        Card(
          margin: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
          elevation: 3,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                padding: EdgeInsets.only(top: 10),
                child: ListTile(
                  isThreeLine: true,
                  leading: SvgPicture.asset("assets/icons/trakt.svg", height: 36, width: 36, color: const Color(0xFFED1C24)),
                  title: Text("Trakt.tv", style: TextStyle(fontFamily: 'GlacialIndifference', fontSize: 18)),
                  subtitle: Container(
                      height: 30,
                      child: AutoSizeText(S.of(context).trakt_description, overflow: TextOverflow.visible)
                  ),
                ),
              ),
              ButtonTheme.bar( // make buttons use the appropriate styles for cards
                child: ButtonBar(
                  children: <Widget>[
                    FlatButton(
                      textColor: Theme.of(context).primaryTextTheme.body1.color,
                      child: TitleText(S.of(context).sync),
                      onPressed: (traktAuthenticated) ? () async {
                        //Interface.showLoadingDialog(context, title: S.of(context).syncing, canCancel: true);

                        Service.get<Trakt>().synchronize(context, silent: false);
                        //KaminoAppDelegateProxy state = context.ancestorStateOfType(const TypeMatcher<KaminoAppDelegateProxy>());
                        //Trakt.syncWatchHistory(state.context);

                        //Navigator.of(context).pop();
                      } : null,
                    ),
                    !traktAuthenticated ?
                      // Trakt account is not linked: show connect option
                      FlatButton(
                        textColor: Theme.of(context).primaryTextTheme.body1.color,
                        child: TitleText(S.of(context).connect),
                        onPressed: () async {
                          await Service.get<Trakt>().authenticate(context, shouldShowSnackbar: true);
                          traktAuthenticated = await Service.get<Trakt>().isAuthenticated();

                          if(traktAuthenticated) Service.get<Trakt>().synchronize(context, silent: false);
                          setState(() {});
                        },
                      ) :
                    // Trakt account is linked: show disconnect option
                    FlatButton(
                      textColor: Theme.of(context).primaryTextTheme.body1.color,
                      child: TitleText(S.of(context).disconnect),
                      onPressed: () async {
                        await Service.get<Trakt>().deauthenticate(context, shouldShowSnackbar: true);
                        this.traktAuthenticated = await Service.get<Trakt>().isAuthenticated();
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Card(
          margin: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
          elevation: 3,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                padding: EdgeInsets.only(top: 10),
                child: ListTile(
                  isThreeLine: true,
                  leading: SvgPicture.asset("assets/icons/simkl.svg", height: 36, width: 36, color: const Color(0xFFFFFFFF)),
                  title: Text("SIMKL", style: TextStyle(fontFamily: 'GlacialIndifference', fontSize: 18)),
                  subtitle: Container(
                      height: 30,
                      child: AutoSizeText(S.of(context).simkl_description, overflow: TextOverflow.visible)
                  ),
                ),
              ),
              ButtonTheme.bar( // make buttons use the appropriate styles for cards
                child: ButtonBar(
                  children: <Widget>[
                    FlatButton(
                      textColor: Theme.of(context).primaryTextTheme.body1.color,
                      child: TitleText(S.of(context).coming_soon)
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        SubtitleText(S.of(context).premium_hosts),

        FutureBuilder(future: _realDebridUserInfoMemoizer.runOnce(() async {
          return await Service.get<RealDebrid>().getUserInfo();
        }), builder: (BuildContext context, AsyncSnapshot<RealDebridUser> snapshot){
          return Card(
            margin: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
            elevation: 3,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.only(top: 10),
                  child: ListTile(
                    isThreeLine: true,
                    leading: SvgPicture.asset("assets/icons/realdebrid.svg", height: 36, width: 36, color: const Color(0xFF78BB6F)),
                    title: Text("Real-Debrid", style: TextStyle(fontFamily: 'GlacialIndifference', fontSize: 18)),
                    subtitle: Container(
                        height: 30,
                        child: AutoSizeText(S.of(context).rd_description, overflow: TextOverflow.visible)
                    ),
                  ),
                ),

                if(rdAuthenticated) Builder(builder: (BuildContext context){
                  if(snapshot.hasError) return Text("Unable to load Real-Debrid profile.");

                  if(snapshot.connectionState != ConnectionState.done
                      || snapshot.data == null) return ApolloLoadingSpinner();

                  return Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(48),
                      child: FadeInImage.memoryNetwork(
                        placeholder: kTransparentImage,
                        image: snapshot.data.avatar,
                        height: 48,
                        width: 48
                      )
                    ),
                    Container(margin: EdgeInsets.only(right: 20)),
                    Column(children: <Widget>[
                      Text("${snapshot.data.username} (${S.of(context).real_debrid_n_points(snapshot.data.points.toString())})"),
                      Text(((type) =>
                        "${type[0].toUpperCase()}${type?.substring(1)}" +
                            (snapshot.data.isPremium() ? " \u2022 " + S.of(context).expires_in_x_days(snapshot.data.premiumDaysRemaining.toString()) : ""))
                      (snapshot.data.type))
                    ])
                  ]);
                }),

                ButtonTheme.bar( // make buttons use the appropriate styles for cards
                  child: ButtonBar(
                    children: <Widget>[
                      // If the user has NOT linked RD, show these buttons:
                      if(!rdAuthenticated) ...[
                        FlatButton(
                          textColor: Theme.of(context).primaryTextTheme.body1.color,
                          child: TitleText(S.of(context).connect),
                          onPressed: () async {
                            await Service.get<RealDebrid>().authenticate(context, shouldShowSnackbar: true);
                            rdAuthenticated = await Service.get<RealDebrid>().isAuthenticated();
                            _realDebridUserInfoMemoizer = new AsyncMemoizer();
                            setState(() {});
                          }
                        )
                      ],

                      // If the user has linked RD, show these buttons:
                      if(rdAuthenticated) ...[
                        // If the user can convert points and isn't premium, suggest that they do so
                        /*if(snapshot.data.points < 1000 && !snapshot.data.isPremium()) FlatButton(
                            textColor: Theme.of(context).primaryTextTheme.body1.color,
                            child: TitleText(S.of(context).real_debrid_convert_points),
                            onPressed: () async {
                              Interface.showLoadingDialog(context, title: S.of(context).converting_realdebrid_fidelity_points);

                              await RealDebrid.convertFidelityPoints(context);

                              // Force refresh data and pop loading dialog.
                              _realDebridUserInfoMemoizer = new AsyncMemoizer();
                              Navigator.of(context).pop();
                              setState(() {});
                            }
                        ),*/
                        
                        if(snapshot.hasData && !snapshot.data.isPremium()) FlatButton(
                          textColor: Theme.of(context).primaryTextTheme.body1.color,
                          child: TitleText(S.of(context).real_debrid_purchase_premium),
                          onPressed: () async {
                            Interface.launchURL("https://real-debrid.com/premium");
                          }
                        ),
                        
                        FlatButton(
                          textColor: Theme.of(context).primaryTextTheme.body1.color,
                          child: TitleText(S.of(context).disconnect),
                          onPressed: () async {
                            await Service.get<RealDebrid>().deauthenticate(context, shouldShowSnackbar: true);
                            rdAuthenticated = await Service.get<RealDebrid>().isAuthenticated();
                            setState(() {});
                          }
                        )
                      ]
                    ],
                  ),
                ),
              ],
            ),
          );
        })
      ],
    );
  }

}