import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kamino/generated/i18n.dart';
import 'package:kamino/interface/settings/page.dart';
import 'package:kamino/ui/elements.dart';
import 'package:kamino/ui/loading.dart';
import 'package:kamino/util/settings.dart';
import 'package:package_info/package_info.dart';

class PlaybackSettingsPage extends SettingsPage {

  static const String BUILT_IN_PLAYER_NAME = "CPlayer";

  PlaybackSettingsPage(BuildContext context) : super(
    title: S.of(context).playback,
    pageState: PlaybackSettingsPageState(),
  );

  static showPlayerSelectDialog(BuildContext context, { Function onSelect }) async {
    PackageInfo packageInfo;

    Future<dynamic> _loadPlayerData = Future(() async {
      packageInfo = await PackageInfo.fromPlatform();
      return jsonDecode(await platform.invokeMethod('list'));
    });

    showDialog(
        context: context,
        builder: (_) {
          return SimpleDialog(
              title: TitleText(S.of(context).select_player),
              children: <Widget>[
                Container(
                    height: 250,
                    width: 300,
                    child: FutureBuilder(future: _loadPlayerData, builder: (_, AsyncSnapshot<dynamic> snapshot) {
                      if(snapshot.connectionState != ConnectionState.done) {
                        return Container(
                          child: ApolloLoadingSpinner(),
                        );
                      }

                      return Scrollbar(
                        child: ListView.builder(itemBuilder: (BuildContext context, int index) {
                          // Add entry for built in player
                          if(index == 0){
                            return ListTile(
                              isThreeLine: true,
                              title: TitleText('CPlayer (Default)'),
                              subtitle: Text(S.of(context).apollotv_builtin_player + "\n" + S.of(context).version_x(packageInfo.version)),
                              leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(48),
                                  child: Image(
                                    image: AssetImage("assets/images/logo.png"),
                                    fit: BoxFit.cover,
                                    alignment: Alignment.center,
                                    width: 48,
                                    height: 48,
                                  )
                              ),
                              enabled: true,
                              onTap: () async {
                                await Settings.setPlayerInfo(PlayerSettings.defaultPlayer());
                                if(onSelect != null) await onSelect();
                                Navigator.of(context).pop();
                              },
                            );
                          }

                          index--;
                          return ListTile(
                            isThreeLine: true,
                            title: TitleText(snapshot.data[index]['name']),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(snapshot.data[index]['description']),
                                Text(S.of(context).version_x(snapshot.data[index]['version']))
                              ],
                            ),
                            leading: Image(
                              image: MemoryImage(
                                  Base64Decoder().convert(snapshot.data[index]['icon'].replaceAll('\n', ''))
                              ),
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                              width: 48,
                              height: 48,
                            ),
                            enabled: true,
                            onTap: () async {
                              await Settings.setPlayerInfo(new PlayerSettings([
                                snapshot.data[index]['activity'],
                                snapshot.data[index]['package'],
                                snapshot.data[index]['name']
                              ]));
                              if(onSelect != null) await onSelect();
                              Navigator.of(context).pop();
                            },
                          );
                        }, itemCount: snapshot.data.length + 1, shrinkWrap: true),
                      );
                    })
                )
              ]
          );
        }
    );
  }

}

const platform = const MethodChannel('xyz.apollotv.kamino/playThirdParty');

class PlaybackSettingsPageState extends SettingsPageState {

  PlayerSettings playerSettings = PlayerSettings.defaultPlayer();

  @override
  void initState(){
    (() async {
      playerSettings = await Settings.playerInfo;
      setState((){});
    })();
    super.initState();
  }

  @override
  Widget buildPage(BuildContext context){
    return ListView(
      physics: widget.isPartial ? NeverScrollableScrollPhysics() : null,
      shrinkWrap: widget.isPartial ? true : false,
      children: <Widget>[
        (Platform.isAndroid) ? Material(
          color: widget.isPartial ? Theme.of(context).cardColor : Theme.of(context).backgroundColor,
          child: ListTile(
            leading: Icon(Icons.play_circle_filled),
            title: TitleText(S.of(context).change_player),
            subtitle: Text(
              playerSettings.isValid() ? playerSettings.name : "${PlaybackSettingsPage.BUILT_IN_PLAYER_NAME} (${S.of(context).default_})"
            ),
            onTap: () => PlaybackSettingsPage.showPlayerSelectDialog(context, onSelect: () async {
              playerSettings = await Settings.playerInfo;
              setState(() {});
            }),
          ),
        ) : Container(),

        Material(
          color: widget.isPartial ? Theme.of(context).cardColor : Theme.of(context).backgroundColor,
          child: ListTile(
            leading: Icon(Icons.cast),
            title: TitleText(S.of(context).cast_settings),
            subtitle: Text(S.of(context).coming_soon),
            onTap: (){
              showDialog(context: context, builder: (BuildContext context){
                return AlertDialog(
                  title: TitleText(S.of(context).not_yet_implemented),
                  content: Text(S.of(context).this_feature_has_not_yet_been_implemented),
                  actions: <Widget>[
                    FlatButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(S.of(context).okay),
                      textColor: Theme.of(context).primaryColor,
                    )
                  ],
                );
              });
            },
          ),
        ),
      ]
    );
  }

}