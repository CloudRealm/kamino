import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_parallax/flutter_parallax.dart';
import 'package:kamino/generated/i18n.dart';
import 'package:kamino/interface/settings/page_advanced.dart';
import 'package:kamino/interface/settings/page_credits.dart';
import 'package:kamino/interface/settings/page_extensions.dart';
import 'package:kamino/interface/settings/page_playback.dart';
import 'package:kamino/util/settings.dart';
import 'package:package_info/package_info.dart';

import 'package:kamino/main.dart';
import 'package:kamino/ui/elements.dart';
import 'package:kamino/animation/transition.dart';
import 'package:kamino/interface/settings/utils/ota.dart' as OTA;

import 'package:kamino/interface/settings/page_appearance.dart';
import 'package:kamino/interface/settings/page_other.dart';

class SettingsView extends StatefulWidget {

  @override
  _SettingsViewState createState() => _SettingsViewState();

}

class _SettingsViewState extends State<SettingsView> {

  PackageInfo _packageInfo = new PackageInfo(
      appName: 'Unknown',
      packageName: 'Unknown',
      version: 'Unknown',
      buildNumber: 'Unknown'
  );

  @override
  void initState() {
    (() async {
      PackageInfo info = await SettingsManager.getPackageInfo();

      assert((){
        info = new PackageInfo(
          appName: info.appName,
          packageName: info.packageName,
          version: info.version,
          buildNumber: info.buildNumber + "D"
        );
        return true;
      }());

      setState(() {
        _packageInfo = info;
      });
    })();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    KaminoAppState application = context.ancestorStateOfType(const TypeMatcher<KaminoAppState>());

    return Scaffold(
        appBar: AppBar(
          title: TitleText(S.of(context).settings),

          backgroundColor: Theme.of(context).backgroundColor,

          // Center title
          centerTitle: true,
        ),

        // The Builder is used to access the parent Scaffold.
        body: Builder(builder: (BuildContext context){
          return Container(
              color: Theme.of(context).backgroundColor,
              child: new ListView(

                  children: <Widget>[

                    Container(
                      width: MediaQuery.of(context).size.width,
                      height: 250,
                      child: Stack(
                          fit: StackFit.expand,
                          children: <Widget>[
                            Parallax.inside(
                                mainAxisExtent: 250.0,
                                child: new Image.asset(
                                  "assets/images/logo_background.png",
                                  fit: BoxFit.cover,
                                )
                            ),

                            Container(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[

                                    Container(
                                        padding: EdgeInsets.only(bottom: 5),
                                        child: Image.asset("assets/images/logo_foreground_lg.png", width: 64, height: 64)
                                    ),

                                    TitleText("$appName v${_packageInfo.version}", fontSize: 24, textColor: Colors.white),

                                    Container(
                                      padding: EdgeInsets.symmetric(vertical: 5),
                                      child: Text("${application.getPrimaryVendorConfig().getName()} ${_getBuildType()} Build \u2022 ${_packageInfo.buildNumber}", style: TextStyle(
                                          color: Colors.white
                                      )),
                                    ),

                                    Platform.isAndroid ? Container(padding: EdgeInsets.only(top: 10), child: RaisedButton(
                                      child: Text(S.of(context).check_for_updates),
                                      onPressed: () => OTA.updateApp(context, false)
                                    )) : Container()

                                  ]
                              ),
                            )
                          ]
                      ),
                    ),

                    Container(padding: EdgeInsets.symmetric(vertical: 10)),

                    Container(
                      margin: EdgeInsets.only(top: 5, bottom: 5, left: 15, right: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SubtitleText(
                            S.of(context).make_appname_yours(appName.toUpperCase()),
                            padding: EdgeInsets.zero,
                          )
                        ],
                      )
                    ),

                    Material(
                      color: Theme.of(context).backgroundColor,
                      child: ListTile(
                        title: TitleText(S.of(context).appearance),
                        subtitle: Text(S.of(context).customize_the_theme_and_primary_colors),
                        leading: new Icon(Icons.style),
                        onTap: (){
                          Navigator.push(context, ApolloTransitionRoute(
                              builder: (context) => AppearanceSettingsPage(context)
                          ));
                        },
                      ),
                    ),

                    Material(
                      color: Theme.of(context).backgroundColor,
                      child: ListTile(
                        title: TitleText(S.of(context).playback),
                        subtitle: Text(S.of(context).change_content_playback_settings),
                        leading: new Icon(Icons.play_circle_filled),
                        onTap: (){
                          Navigator.push(context, ApolloTransitionRoute(
                              builder: (context) => PlaybackSettingsPage(context)
                          ));
                        },
                      ),
                    ),

                    /*Material(
                      color: Theme.of(context).backgroundColor,
                      child: ListTile(
                        title: TitleText(S.of(context).launchpad),
                        subtitle: Text(S.of(context).customize_your_launchpad),
                        leading: new Icon(const IconData(0xe90F, fontFamily: 'apollotv-icons')),
                        onTap: (){
                          Navigator.push(context, FadeRoute(
                              builder: (context) => LaunchpadSettingsPage(context)
                          ));
                        },
                      ),
                    ),*/

                    Container(
                        margin: EdgeInsets.only(top: 35, bottom: 5, left: 15, right: 15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            SubtitleText(
                              S.of(context).boost_your_experience,
                              padding: EdgeInsets.zero,
                            )
                          ],
                        )
                    ),

                    Material(
                      color: Theme.of(context).backgroundColor,
                      child: ListTile(
                        title: TitleText("ApolloTV Houston"),
                        subtitle: Text("Manage services offered by ApolloTV."),
                        leading: Icon(IconData(0xE90F, fontFamily: "apollotv-icons")),
                        enabled: false
                      ),
                    ),

                    Material(
                      color: Theme.of(context).backgroundColor,
                      child: ListTile(
                        title: TitleText(S.of(context).extensions),
                        subtitle: Text(S.of(context).manage_third_party_integrations),
                        leading: new Icon(Icons.extension),
                        enabled: true,
                        onTap: (){
                          Navigator.push(context, ApolloTransitionRoute(
                              builder: (context) => ExtensionsSettingsPage(context)
                          ));
                        },
                      ),
                    ),

                    Container(
                        margin: EdgeInsets.only(top: 35, bottom: 5, left: 15, right: 15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            SubtitleText(
                              S.of(context).miscellaneous,
                              padding: EdgeInsets.zero,
                            )
                          ],
                        )
                    ),

                    Material(
                      color: Theme.of(context).backgroundColor,
                      child: ListTile(
                        title: TitleText(S.of(context).other_),
                        subtitle: Text(S.of(context).general_application_settings),
                        leading: new Icon(Icons.settings),
                        enabled: true,
                        onTap: (){
                          Navigator.push(context, ApolloTransitionRoute(
                              builder: (context) => OtherSettingsPage(context)
                          ));
                        },
                      ),
                    ),

                    Material(
                      color: Theme.of(context).backgroundColor,
                      child: ListTile(
                        title: TitleText(S.of(context).advanced),
                        subtitle: Text(S.of(context).power_user_settings_for_rocket_scientists),
                        leading: new Icon(Icons.developer_mode),
                        enabled: true,
                        onTap: (){
                          Navigator.push(context, ApolloTransitionRoute(
                              builder: (context) => AdvancedSettingsPage(context)
                          ));
                        },
                      ),
                    ),

                    // It's okay to remove this, but we'd appreciate it if you
                    // keep it. <3
                    Container(
                        margin: EdgeInsets.only(top: 35, bottom: 5, left: 15, right: 15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            SubtitleText(
                              S.of(context).information,
                              padding: EdgeInsets.zero,
                            )
                          ],
                        )
                    ),
                    
                    Material(
                      color: Theme.of(context).backgroundColor,
                      child: ListTile(
                        title: TitleText(S.of(context).credits),
                        subtitle: Text(S.of(context).credits_description),
                        leading: new Icon(Icons.people),
                        enabled: true,
                        isThreeLine: true,
                        onTap: (){
                          Navigator.push(context, ApolloTransitionRoute(
                              builder: (context) => CreditsSettingsPage(context)
                          ));
                        },
                      ),
                    )
                  ]
              )
          );
        })
    );
  }

  String _getBuildType(){
    int buildType = int.tryParse(_packageInfo.buildNumber.split('').last, radix: 16);

    List<String> buildTypes = new List(16)..setAll(0, SettingsManager.buildTypes);
    buildTypes[0xD] = "Debug";
    if(buildType != null) return buildTypes[buildType];
    return S.of(context).unknown;
  }

}
