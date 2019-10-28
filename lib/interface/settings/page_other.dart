import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kamino/database/collections/search_history.dart';
import 'package:kamino/generated/i18n.dart';
import 'package:kamino/ui/elements.dart';
import 'package:kamino/ui/interface.dart';
import 'package:kamino/interface/settings/page.dart';

import 'package:kamino/util/settings.dart';
import 'package:transparent_image/transparent_image.dart';

class OtherSettingsPage extends SettingsPage {

  OtherSettingsPage(BuildContext context, {bool isPartial = false}) : super(
      title: S.of(context).other_,
      pageState: OtherSettingsPageState(),
      isPartial: isPartial
  );

}

class OtherSettingsPageState extends SettingsPageState {

  int _releaseVersionTrack = 0;
  bool _autoplaySourcesEnabled = false;
  bool _hideUnreleasedPartialContent = false;

  static const List<String> releaseVersionTracks = [
    "Stable",
    "Beta",
    "Development"
  ];

  @override
  void initState(){
    // This is done for legacy reasons.
    // We would upgrade the setting but we do intent to switch back
    // to having autoplay enabled by default.
    /*(Settings.manuallySelectSourcesEnabled as Future).then((data){
      setState(() {
        _autoplaySourcesEnabled = !data;
      });
    });*/

    (Settings.hideUnreleasedPartialContent as Future).then((data){
      setState(() {
        _hideUnreleasedPartialContent = data;
      });
    });

    (Settings.releaseVersionTrack as Future).then((data){
      setState(() {
        _releaseVersionTrack = data;
      });
    });

    super.initState();
  }

  @override
  Widget buildPage(BuildContext context) {
    return ListView(
      physics: widget.isPartial ? NeverScrollableScrollPhysics() : null,
      shrinkWrap: widget.isPartial ? true : false,
      children: <Widget>[
        /*Material(
          color: widget.isPartial ? Theme.of(context).cardColor : Theme.of(context).backgroundColor,
          child: SwitchListTile(
            isThreeLine: true,
            activeColor: Theme.of(context).primaryColor,
            value: _autoplaySourcesEnabled,
            title: Row(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    color: Theme.of(context).primaryColor,
                  ),
                  margin: EdgeInsetsDirectional.only(end: 5),
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  child: Text("Experimental"),
                ),

                Flexible(child: TitleText(S.of(context).source_autoplay, allowOverflow: true))
              ]
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                S.of(context).source_autoplay_description,
                style: TextStyle(),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
            onChanged: (value) async {
              if (value != _autoplaySourcesEnabled){
                await (Settings.manuallySelectSourcesEnabled = !value); // ignore: await_only_futures
                (Settings.manuallySelectSourcesEnabled as Future).then((data) => setState(() => _autoplaySourcesEnabled = !data));
              }
            },
          ),
        ),*/

        SubtitleText(S.of(context).search, padding: EdgeInsets.symmetric(vertical: 30, horizontal: 15).copyWith(bottom: 5)),
        Material(
          color: widget.isPartial ? Theme.of(context).cardColor : Theme.of(context).backgroundColor,
          child: SwitchListTile(
            activeColor: Theme.of(context).primaryColor,
            isThreeLine: true,
            secondary: Icon(Icons.receipt),
            title: TitleText(S.of(context).hide_partial_unreleased_content),
            subtitle: Text(S.of(context).hide_partial_unreleased_content_description),
            value: _hideUnreleasedPartialContent,
            onChanged: (bool newValue) async {
              if (newValue != _hideUnreleasedPartialContent){
                await (Settings.hideUnreleasedPartialContent = newValue); // ignore: await_only_futures
                (Settings.hideUnreleasedPartialContent as Future).then(
                  (data) => setState(() => _hideUnreleasedPartialContent = data)
                );
              }
            },
          ),
        ),
        Material(
          color: widget.isPartial ? Theme.of(context).cardColor : Theme.of(context).backgroundColor,
          child: ListTile(
            leading: Icon(Icons.clear_all),
            title: TitleText(S.of(context).clear_search_history),
            subtitle: Text(S.of(context).clear_search_history_description),
            enabled: true,
            onTap: () async {
              await SearchHistoryCollection.clear();
              Interface.showSnackbar(S.of(context).search_history_cleared, context: context);
            },
          ),
        ),

        if(Platform.isAndroid)
          ...[
            SubtitleText(S.of(context).updates, padding: EdgeInsets.symmetric(vertical: 30, horizontal: 15).copyWith(bottom: 5)),
            Container(
              margin: EdgeInsets.only(bottom: 10),
              child: Material(
                color: widget.isPartial ? Theme.of(context).cardColor : Theme.of(context).backgroundColor,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    ListTile(
                      leading: Icon(Icons.swap_vert),
                      title: TitleText(S.of(context).version_track),
                      subtitle: Text(releaseVersionTracks[_releaseVersionTrack]),
                    ),

                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          Slider(
                              onChanged: (double value) async {
                                await (Settings.releaseVersionTrack = value.toInt());

                                (Settings.releaseVersionTrack as Future).then((data){
                                  setState(() {
                                    _releaseVersionTrack = data;
                                  });
                                });
                              },
                              value: _releaseVersionTrack.toDouble(),
                              min: 0,
                              max: 2,
                              divisions: 2,
                              label: releaseVersionTracks[_releaseVersionTrack],
                              activeColor: Theme.of(context).primaryColor,
                              inactiveColor: Theme.of(context).primaryColor.withOpacity(0.3),
                          ),

                          Container(
                            margin: EdgeInsets.only(top: 10, left: 5),
                            child: Column(
                              children: <Widget>[
                                RichText(
                                    text: TextSpan(
                                      style: TextStyle(fontFamily: 'Futura'),
                                      children: [
                                        TextSpan(
                                            text: "\u2022 ${S.of(context).stable}: ",
                                            style: TextStyle(fontWeight: FontWeight.bold)
                                        ),
                                        TextSpan(
                                            text: S.of(context).version_track_stable_description
                                        )
                                      ]
                                    ),
                                ),

                                Container(margin: EdgeInsets.only(top: 15)),

                                RichText(
                                    text: TextSpan(
                                      style: TextStyle(fontFamily: 'Futura'),
                                      children: [
                                        TextSpan(
                                            text: "\u2022 ${S.of(context).beta}: ",
                                            style: TextStyle(fontWeight: FontWeight.bold)
                                        ),
                                        TextSpan(
                                            text: S.of(context).version_track_beta_description
                                        )
                                      ]
                                    )
                                ),

                                Container(margin: EdgeInsets.only(top: 15)),

                                RichText(
                                    text: TextSpan(
                                      style: TextStyle(fontFamily: 'Futura'),
                                      children: [
                                        TextSpan(
                                            text: "\u2022 ${S.of(context).development}: ",
                                            style: TextStyle(fontWeight: FontWeight.bold)
                                        ),
                                        TextSpan(
                                            text: S.of(context).version_track_development_description
                                        )
                                      ]
                                    )
                                )
                              ],
                            ),
                          )
                        ]
                      )
                    )
                  ],
                ),
              ),
            )
          ],

        SubtitleText(S.of(context).localization, padding: EdgeInsets.symmetric(vertical: 45, horizontal: 15).copyWith(bottom: 5)),
        Material(
          color: widget.isPartial ? Theme.of(context).cardColor : Theme.of(context).backgroundColor,
          child: ListTile(
            leading: Icon(Icons.translate),
            trailing: Container(
              child: FadeInImage(
                fadeInDuration: Duration(milliseconds: 400),
                placeholder: MemoryImage(kTransparentImage),
                image: AssetImage(
                    "assets/flags/${Interface.getLocaleFlag(
                        Localizations.localeOf(context).languageCode,
                        Localizations.localeOf(context).countryCode
                    )}.png"
                ),
                fit: BoxFit.contain,
                alignment: Alignment.center,
                width: 48,
              )
            ),
            title: TitleText(S.of(context).language_settings),
            subtitle: Text(S.of(context).$_language_name),
            enabled: true,
            onTap: () => Interface.showLanguageSelectionDialog(context),
        )
      )
    ]);
  }

}