import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:kamino/database/database.dart';
import 'package:kamino/external/ExternalService.dart';
import 'package:kamino/external/struct/paste.dart';
import 'package:kamino/generated/i18n.dart';
import 'package:kamino/interface/intro/kamino_intro.dart';
import 'package:kamino/main.dart';
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

  ScrollController _scrollView = new ScrollController();

  bool _disableSecurityMessages = false;
  bool _showDebugItems = false;

  final _serverURLController = TextEditingController();
  final _serverKeyController = TextEditingController();

  @override
  void initState() {
    assert((){
      _showDebugItems = true;
      return true;
    }());

    () async {
      _serverURLController.text = await Settings.serverURLOverride;
      _serverKeyController.text = await Settings.serverKeyOverride;
      _disableSecurityMessages = await Settings.disableSecurityMessages;

      setState(() {});
    }();

    super.initState();
  }

  @override
  Widget buildPage(BuildContext context) {
    return ListView(
      controller: _scrollView,
      physics: widget.isPartial ? NeverScrollableScrollPhysics() : null,
      shrinkWrap: widget.isPartial ? true : false,
      children: <Widget>[

        SubtitleText(S.of(context).core, padding: EdgeInsets.symmetric(vertical: 30, horizontal: 15).copyWith(bottom: 5)),

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
                  contentPadding: EdgeInsets.all(0),

                  content: Container(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 25),
                    child: SizedBox(
                      width: 500,
                      height: 230,
                      child: Form(
                        autovalidate: true,
                        child: ListView(
                          children: <Widget>[
                            Container(
                              margin: EdgeInsets.symmetric(vertical: 10),
                              child: Text(S.of(context).be_careful_this_option_could_break_the_app_if_you),
                            ),

                            !_disableSecurityMessages ? Container(
                              margin: EdgeInsets.symmetric(vertical: 10),
                              child: RichText(text: TextSpan(children: [
                                TextSpan(text: S.of(context).security_risk, style: TextStyle(fontFamily: 'Futura', fontWeight: FontWeight.bold)),
                                TextSpan(text: " "),
                                TextSpan(text: S.of(context).using_unofficial_servers_can_expose_your_ip_address)
                              ], style: TextStyle(
                                color: Colors.red,
                                fontFamily: 'Futura'
                              ))),
                            ) : Container(),

                            /** PRESETS **/
                            /*Container(
                              height: 35,
                              margin: EdgeInsets.symmetric(vertical: 10),
                              child: ListView(
                                shrinkWrap: true,
                                scrollDirection: Axis.horizontal,
                                children: <Widget>[
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    child: SubtitleText("Presets:", padding: EdgeInsets.all(0).copyWith(right: 20)),
                                  ),
                                  FlatButton(
                                    onPressed: (){
                                      setState(() {
                                        _serverURLController.text = "https://claws.ddivad.dev/";
                                        _serverKeyController.text = "W6C5AZPxDSWx58cPELhXrgLXtHTnNP9x";
                                      });
                                    },
                                    child: Text("ddivad"),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(100)
                                    ),
                                    color: Colors.white12,
                                  )
                                ],
                              ),
                            ),*/

                            Container(
                              margin: EdgeInsets.symmetric(vertical: 10),
                              child: TextFormField(
                                validator: (String arg){
                                  const String serverURLRegex = r"^(http|https):\/\/(([a-z0-9]|[a-z0-9][a-z0-9\-]*[a-z0-9])\.)*([a-z0-9]|[a-z0-9][a-z0-9\-]*[a-z0-9])(:[0-9]+)?\/$";
                                  bool isValid = new RegExp(serverURLRegex, caseSensitive: false).hasMatch(arg);
                                  if(!isValid && arg.length > 0) return S.of(context).the_url_must_be_valid_and_include_a_trailing_;
                                  return null;
                                },
                                controller: _serverURLController,
                                keyboardType: TextInputType.url,
                                decoration: InputDecoration(
                                    prefixIcon: Icon(Icons.public),
                                    labelText: S.of(context).server_url
                                ),
                              ),
                            ),

                            Container(
                              margin: EdgeInsets.only(top: 10),
                              child: TextFormField(
                                validator: (String arg){
                                  if(arg.length != 32 && arg.length > 0)
                                    return S.of(context).the_key_must_be_32_characters_in_length;
                                  return null;
                                },
                                maxLength: 32,
                                maxLengthEnforced: true,
                                controller: _serverKeyController,
                                decoration: InputDecoration(
                                    prefixIcon: Icon(Icons.vpn_key),
                                    labelText: S.of(context).server_key
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),

                  actions: <Widget>[
                    FlatButton(
                      child: Text(S.of(context).reset),
                      onPressed: () async {
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
                      child: Text(S.of(context).set),
                      onPressed: () async {
                        (_serverURLController.text != "") ? Settings.serverURLOverride = _serverURLController.text : SettingsManager.deleteKey("serverURLOverride");
                        (_serverKeyController.text != "") ? Settings.serverKeyOverride = _serverKeyController.text : SettingsManager.deleteKey("serverKeyOverride");

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
            title: TitleText(S.of(context).run_initial_setup_procedure),
            subtitle: Text(S.of(context).begins_the_initial_setup_procedure_that_is_displayed_when_the),
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

        SubtitleText(S.of(context).networking, padding: EdgeInsets.symmetric(vertical: 30, horizontal: 15).copyWith(bottom: 5)),

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

        SubtitleText(S.of(context).diagnostics, padding: EdgeInsets.symmetric(vertical: 30, horizontal: 15).copyWith(bottom: 5)),

        Material(
          color: widget.isPartial ? Theme.of(context).cardColor : Theme.of(context).backgroundColor,
          child: ListTile(
            leading: Icon(Icons.code),
            title: TitleText(S.of(context).run_command),
            enabled: true,
            onTap: () async {
              Interface.showSnackbar(S.of(context).waiting_for_input, context: context);
              
              try {
                KaminoAppState application = context.ancestorStateOfType(
                    const TypeMatcher<KaminoAppState>());
                application.getPrimaryVendorConfig().execCommand(
                    context,
                    'init_debug'
                );
              }catch(_){}
            }
          )
        ),

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
                info += ("device: ${deviceInfo.manufacturer} ${deviceInfo.model} (${deviceInfo.product})\n");
                info += ("\n");
                info += ("hardware:") + "\n";
                info += ("    model: ${deviceInfo.hardware}\n");
                info += ("    bootloader: ${deviceInfo.bootloader})\n");
                info += ("    supports: ${deviceInfo.supportedAbis.join(',')}\n");
                info += ("    is_physical_device: ${deviceInfo.isPhysicalDevice}\n");
                info += ("\n");
                info += ("software:") + "\n";
                info += ("    release: Android ${deviceInfo.version.release}\n");
                info += ("    sdk: ${deviceInfo.version.sdkInt}\n");
                info += ("    codename: ${deviceInfo.version.codename}\n");
                info += ("    build:\n");
                info += ("        number: ${deviceInfo.display}\n");
                info += ("        tags: ${deviceInfo.tags}\n");

                try {
                  String link = await Service.primaryOfType<PasteService>(ServiceType.PASTE).paste(
                      info,
                      title: "Device Information | $appName",
                      fileFormat: "yaml"
                  );

                  await Clipboard.setData(new ClipboardData(text: link));
                  Interface.showSnackbar(S.of(context).link_copied_to_clipboard, context: context);
                }catch(ex){
                  if(ex is SocketException || ex is HttpException)
                    Interface.showSnackbar(S.of(context).youre_offline, context: context, backgroundColor: Colors.red);

                  print(ex);
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

        Material(
          color: widget.isPartial ? Theme.of(context).cardColor : Theme.of(context).backgroundColor,
          child: ListTile(
            leading: Icon(Icons.delete_forever),
            title: TitleText(S.of(context).wipe_database),
            subtitle: Text(S.of(context).clears_the_application_database),
            enabled: true,
            onTap: () async {
              Interface.showLoadingDialog(context, title: S.of(context).wiping_database);
              await Database.wipe();
              Navigator.of(context).pop();
            },
          ),
        ),

        Material(
          color: widget.isPartial ? Theme.of(context).cardColor : Theme.of(context).backgroundColor,
          child: ListTile(
            leading: Icon(Icons.layers_clear),
            title: TitleText(S.of(context).wipe_settings),
            subtitle: Text(S.of(context).clears_all_application_settings),
            enabled: true,
            onTap: () async {
              Interface.showLoadingDialog(context, title: S.of(context).clearing_settings);
              await SettingsManager.eraseAllSettings();
              Navigator.of(context).pop();
            },
          ),
        ),

        Material(
          color: widget.isPartial ? Theme.of(context).cardColor : Theme.of(context).backgroundColor,
          child: ListTile(
            isThreeLine: true,
            leading: Icon(Icons.error),
            title: TitleText(S.of(context).throw_error),
            subtitle: Text(S.of(context).intentionally_throws_an_error_to_test_error_handling + "\n" + S.of(context).does_nothing_in_release_mode),
            enabled: true,
            onTap: () async {
              throw new Exception(S.of(context).well_dont_say_you_didnt_ask);
            },
          ),
        ),

        _showDebugItems ? Material(
          color: widget.isPartial ? Theme.of(context).cardColor : Theme.of(context).backgroundColor,
          child: ListTile(
            leading: Icon(Icons.sd_storage),
            title: TitleText(S.of(context).dump_preferences),
            subtitle: Text(S.of(context).debug_only_logs_the_application_preferences_in_the_console),
            enabled: true,
            onTap: () => SettingsManager.dumpFromStorage(),
          ),
        ) : Container(),

        _showDebugItems ? Material(
          color: widget.isPartial ? Theme.of(context).cardColor : Theme.of(context).backgroundColor,
          child: ListTile(
            leading: Icon(Icons.storage),
            title: TitleText(S.of(context).dump_database),
            subtitle: Text(S.of(context).debug_only_logs_the_application_database_in_the_console),
            enabled: true,
            onTap: () => Database.dump(),
          ),
        ) : Container(),

        SubtitleText(S.of(context).security, padding: EdgeInsets.symmetric(vertical: 30, horizontal: 15).copyWith(bottom: 5)),

        Material(
            color: widget.isPartial ? Theme.of(context).cardColor : Theme.of(context).backgroundColor,
            child: SwitchListTile(
              activeColor: Theme.of(context).primaryColor,
              secondary: Icon(Icons.warning),
              title: TitleText(S.of(context).disable_security_warnings),
              subtitle: Column(children: <Widget>[
                Container(
                  margin: EdgeInsets.only(top: 5),
                  child: Text(S.of(context).this_disables_all_warnings_regarding_potential_security_concerns),
                ),

                RichText(text: TextSpan(
                  style: TextStyle(fontFamily: 'Futura'),
                  children: [
                    if(!_disableSecurityMessages)
                      TextSpan(text: "\n" + S.of(context).we_recommend_that_you_do_not_enable_this_option_unless, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red))
                    else
                      TextSpan(text: "\n" + S.of(context).security_warnings_have_been_disabled, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red))
                  ]
                ))
              ]),
              value: _disableSecurityMessages,
              onChanged: (bool value) async {
                await (Settings.disableSecurityMessages = value);
                Settings.disableSecurityMessages.then((data){
                  setState(() {
                    _disableSecurityMessages = data;

                    if(!_disableSecurityMessages){
                      _scrollView.animateTo(
                        _scrollView.offset + 40,
                        curve: Curves.easeOut,
                        duration: const Duration(milliseconds: 400)
                      );
                    }
                  });
                });
              }
            )
        ),

        Container(margin: EdgeInsets.only(top: 20))
      ],
    );
  }

}
