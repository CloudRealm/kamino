import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:kamino/generated/i18n.dart';
import 'package:kamino/interface/intro/kamino_intro.dart';
import 'package:kamino/ui/elements.dart';
import 'package:kamino/ui/interface.dart';
import 'package:kamino/interface/settings/page.dart';
import 'package:device_info/device_info.dart';
import 'package:kamino/util/settings.dart';


class AdvancedSettingsPage extends SettingsPage {

  AdvancedSettingsPage(BuildContext context, {bool isPartial = false}) : super(
      title: S.of(context).advanced,
      pageState: AdvancedSettingsPageState(),
      isPartial: isPartial
  );

}

class AdvancedSettingsPageState extends SettingsPageState {

  bool _showDebugItems = false;

  final _serverURLController = TextEditingController();
  final _serverKeyController = TextEditingController();

  int _maxConcurrentRequests;
  int _requestTimeout;

  @override
  void initState() {
    assert((){
      _showDebugItems = true;
      return true;
    }());

    () async {
      _maxConcurrentRequests = await Settings.maxConcurrentRequests;
      _requestTimeout = await Settings.requestTimeout;

      _serverURLController.text = await Settings.serverURLOverride;
      _serverKeyController.text = await Settings.serverKeyOverride;

      setState(() {});
    }();

    super.initState();
  }

  @override
  Widget buildPage(BuildContext context) {
    return ListView(
      physics: widget.isPartial ? NeverScrollableScrollPhysics() : null,
      shrinkWrap: widget.isPartial ? true : false,
      children: <Widget>[

        SubtitleText("CORE", padding: EdgeInsets.symmetric(vertical: 30, horizontal: 15).copyWith(bottom: 5)),

        Material(
          color: widget.isPartial ? Theme.of(context).cardColor : Theme.of(context).backgroundColor,
          child: ListTile(
            leading: Icon(Icons.dns),
            title: TitleText(S.of(context).change_default_server),
            subtitle: Text(S.of(context).manually_override_the_default_content_server),
            enabled: true,
            onTap: (){
              showDialog(context: context, builder: (BuildContext context){
                return AlertDialog(
                  title: TitleText(S.of(context).change_default_server),

                  content: SizedBox(
                    width: 500,
                    height: 200,
                    child: ListView(
                      children: <Widget>[
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 10),
                          child: Text("Be careful! This option could break the app if you don't know what you're doing."),
                        ),

                        Container(
                          margin: EdgeInsets.symmetric(vertical: 10),
                          child: TextField(
                            controller: _serverURLController,
                            keyboardType: TextInputType.url,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.public),
                              labelText: "Server URL"
                            ),
                          ),
                        ),

                        Container(
                          margin: EdgeInsets.only(top: 10),
                          child: TextField(
                            controller: _serverKeyController,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.vpn_key),
                              labelText: "Server Key"
                            ),
                          ),
                        )
                      ],
                    ),
                  ),

                  actions: <Widget>[
                    FlatButton(
                      child: Text(S.of(context).default_),
                      onPressed: () async {
                        await Future.wait(<Future>[
                          SettingsManager.deleteKey("serverURLOverride"),
                          SettingsManager.deleteKey("serverKeyOverride")
                        ]);

                        Navigator.of(context).pop();

                        _serverURLController.text = "";
                        _serverKeyController.text = "";

                        setState((){});
                      },
                    ),

                    FlatButton(
                      child: Text(S.of(context).cancel),
                      onPressed: () => Navigator.of(context).pop(),
                    ),

                    FlatButton(
                      child: Text(S.of(context).okay),
                      onPressed: () async {
                        Settings.serverURLOverride = _serverURLController.text;
                        Settings.serverKeyOverride = _serverKeyController.text;

                        setState((){});
                        Navigator.of(context).pop();
                      },
                    )
                  ],
                );
              });
            },
          ),
        ),

        Material(
          color: widget.isPartial ? Theme.of(context).cardColor : Theme.of(context).backgroundColor,
          child: ListTile(
            leading: Icon(Icons.phonelink_setup),
            title: TitleText("Run Initial Setup Procedure"),
            subtitle: Text("Begins the initial setup procedure that is displayed when the app is opened for the first time."),
            enabled: true,
            isThreeLine: true,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => KaminoIntro()
            )),
            onLongPress: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => KaminoIntro(skipAnimation: true)
            )),
          ),
        ),

        SubtitleText("NETWORKING", padding: EdgeInsets.symmetric(vertical: 30, horizontal: 15).copyWith(bottom: 5)),

        Material(
          color: widget.isPartial ? Theme.of(context).cardColor : Theme.of(context).backgroundColor,
          child: ListTile(
            isThreeLine: true,
            leading: Icon(Icons.network_check),
            title: TitleText("Maximum Concurrent Requests"),
            subtitle: Text("Limits the number of concurrent network requests that can be made by the app."),
            enabled: true,
            trailing: DropdownButton<int>(
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'GlacialIndifference',
                  fontSize: 16
                ),
                hint: Text(_maxConcurrentRequests.toString(), style: TextStyle(
                  color: Colors.white
                )),
                // Max value for 'Maximum concurrent requests' -> 5
                items: List<DropdownMenuItem<int>>.generate(5, (value){
                  value += 1;
                  return DropdownMenuItem<int>(
                    child: Text(value.toString()),
                    value: value
                  );
                }),
                onChanged: (value){
                  Settings.maxConcurrentRequests = value;
                  setState(() {
                    _maxConcurrentRequests = value;
                  });
                }
            ),
          ),
        ),

        Material(
          color: widget.isPartial ? Theme.of(context).cardColor : Theme.of(context).backgroundColor,
          child: ListTile(
            isThreeLine: true,
            leading: Icon(Icons.timer_off),
            title: TitleText("Request Timeout Duration"),
            subtitle: Text("The delay, in seconds, before which a network request will be timed out."),
            enabled: true,
            trailing: DropdownButton<int>(
                style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'GlacialIndifference',
                    fontSize: 16
                ),
                hint: Text(_requestTimeout.toString(), style: TextStyle(
                    color: Colors.white
                )),
                // Generate 5 items (in this case - interval of 10)
                items: List<DropdownMenuItem<int>>.generate(5, (value){
                  value = (value + 1) * 10;
                  return DropdownMenuItem<int>(
                      child: Text(value.toString()),
                      value: value
                  );
                }),
                onChanged: (value){
                  Settings.requestTimeout = value;
                  setState(() {
                    _requestTimeout = value;
                  });
                }
            ),
          ),
        ),

        Material(
          color: widget.isPartial ? Theme.of(context).cardColor : Theme.of(context).backgroundColor,
          child: ListTile(
            leading: Icon(Icons.settings_ethernet),
            title: TitleText(S.of(context).run_connectivity_test),
            subtitle: Text(S.of(context).checks_whether_sources_can_be_reached),
            enabled: true,
            onTap: (){
              showDialog(context: context, builder: (BuildContext context){
                return AlertDialog(
                  title: TitleText("Not yet implemented..."),
                  content: Text("This feature has not yet been implemented."),
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

        SubtitleText("DIAGNOSTICS", padding: EdgeInsets.symmetric(vertical: 30, horizontal: 15).copyWith(bottom: 5)),

        Material(
          color: widget.isPartial ? Theme.of(context).cardColor : Theme.of(context).backgroundColor,
          child: ListTile(
            leading: Icon(Icons.perm_device_information),
            title: TitleText(S.of(context).get_device_information),
            subtitle: Text(S.of(context).gathers_useful_information_for_debugging),
            enabled: true,
            onTap: () async {
              var deviceInfoPlugin = DeviceInfoPlugin();

              if(Platform.isAndroid){
                AndroidDeviceInfo deviceInfo = await deviceInfoPlugin.androidInfo;

                String info = "";
                info += ("${deviceInfo.manufacturer} ${deviceInfo.model} (${deviceInfo.product})") + "\n";
                info += ("\n");
                info += ("Hardware: ${deviceInfo.hardware} (Bootloader: ${deviceInfo.bootloader})") + "\n";
                info += ("\t\t--> Supports: ${deviceInfo.supportedAbis.join(',')}") + "\n";
                info += ("\t\t--> IPD: ${deviceInfo.isPhysicalDevice}") + "\n";
                info += ("\n");
                info += ("Software: Android ${deviceInfo.version.release}, SDK ${deviceInfo.version.sdkInt} (${deviceInfo.version.codename})") + "\n";
                info += ("\t\t--> Build ${deviceInfo.display} (${deviceInfo.tags})");

                try {
                  var response = await http.post("https://hastebin.com/documents", body: info);
                  String key = jsonDecode(response.body)["key"];

                  await Clipboard.setData(new ClipboardData(text: "https://hastebin.com/$key.apollodebug"));
                  Interface.showSnackbar(S.of(context).link_copied_to_clipboard, context: context);
                }catch(ex){
                  if(ex is SocketException || ex is HttpException)
                    Interface.showSnackbar(S.of(context).youre_offline, context: context, backgroundColor: Colors.red);
                  Interface.showSnackbar(S.of(context).an_error_occurred, context: context, backgroundColor: Colors.red);
                }

                return;
              }

              /*if(Platform.isIOS){
                print(await deviceInfo.iosInfo);
                return;
              }*/
            },
          ),
        ),

        _showDebugItems ? Material(
          color: widget.isPartial ? Theme.of(context).cardColor : Theme.of(context).backgroundColor,
          child: ListTile(
            leading: Icon(Icons.sd_storage),
            title: TitleText("Dump Preferences"),
            subtitle: Text("(Debug only) Logs the application preferences in the console."),
            enabled: true,
            onTap: () => SettingsManager.dumpFromStorage(),
          ),
        ) : Container(),
      ],
    );
  }

}
