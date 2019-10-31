import 'dart:async';

import 'package:cplayer/cplayer.dart';
import 'package:dart_chromecast/casting/cast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kamino/animation/transition.dart';
import 'package:kamino/generated/i18n.dart';
import 'package:kamino/main.dart';
import 'package:kamino/models/content/content.dart';
import 'package:kamino/ui/interface.dart';
import 'package:kamino/util/settings.dart';
import 'package:kamino/vendor/struct/VendorService.dart';

class PlayerHelper {

  static Future<void> play(BuildContext context, {
    @required String title,
    @required String url,
    @required String mimeType,
    @required VendorService service,

    @required ContentModel content,
    @required int season,
    @required int episode
  }) async {

    KaminoAppState application = context.ancestorStateOfType(const TypeMatcher<KaminoAppState>());
    if(application.activeCastSender != null){
      
      runZoned((){
        // application.activeCastSender.launch(appCastID);

        application.activeCastSender.loadPlaylist([CastMedia(
            contentId: url,
            title: title,
            autoPlay: true
        )], append: false, forceNext: true);
      }, onError: (error, stacktrace){
        Interface.showSnackbar(S.of(context).an_error_occurred_whilst_casting, context: context, backgroundColor: Colors.red);
      });
      
      return;
    }

    PlayerSettings playerSettings = await Settings.playerInfo;

    if(!playerSettings.isValid()) {
      // Use CPlayer
      Navigator.push(
          context,
          ApolloTransitionRoute(builder: (context) =>
            CPlayer(
                title: title,
                url: url,
                mimeType: mimeType,
                vendorService: service,

                content: content,
                season: season,
                episode: episode
              )
          )
      );
    }else{
      // Launch external player
      MethodChannel playerChannel = const MethodChannel('xyz.apollotv.kamino/playThirdParty');
      await playerChannel.invokeMethod('play', <String, dynamic>{
        'activityPackage': playerSettings.package,
        'activityName': playerSettings.activity,
        'videoTitle': title,
        'videoURL': url,
        'mimeType': mimeType
      }).catchError((error){
        Interface.showSimpleErrorDialog(
            context,
            title: "Error loading player",
            reason: "ApolloTV was unable to load ${playerSettings.name}.",
            alternativeAction: FlatButton(
              onPressed: () => choosePlayer(
                context,
                title: title,
                url: url,
                mimeType: mimeType
              ),
              child: Text("Choose Player"),
              textColor: Theme.of(context).primaryColor,
            )
        );
      });
    }
  }

  static Future<void> choosePlayer(BuildContext context, {
    @required String title,
    @required String url,
    @required String mimeType
  }) async {
    // Show external player dialog
    MethodChannel playerChannel = const MethodChannel('xyz.apollotv.kamino/playThirdParty');
    await playerChannel.invokeMethod('selectAndPlay', <String, dynamic>{
      'copyToClipboardLabel': S.of(context).copy_to_clipboard,
      'chooseLabel': S.of(context).choose_player,
      'videoTitle': title,
      'videoURL': url,
      'mimeType': mimeType
    });
  }

}