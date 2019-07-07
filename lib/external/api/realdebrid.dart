import 'dart:async';
import 'dart:convert';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:kamino/external/ExternalService.dart';
import 'package:kamino/external/struct/premium_host.dart';
import 'package:kamino/ui/interface.dart';
import 'package:kamino/ui/loading.dart';
import 'package:kamino/util/settings.dart';

import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:kamino/generated/i18n.dart';
import 'package:kamino/main.dart';
import 'package:kamino/ui/elements.dart';

class RealDebrid extends PremiumHostService {

  static RealDebridIdentity identity;

  RealDebrid(RealDebridIdentity _identity) : super(
    "Real-Debrid"
  ){ identity = _identity; }

  static const REAL_DEBRID_OAUTH_ENDPOINT = "https://api.real-debrid.com/oauth/v2";
  static const REAL_DEBRID_API_ENDPOINT = "https://api.real-debrid.com/rest/1.0";
  static const REAL_DEBRID_REFRESH_OFFSET = 300;

  ///
  /// This method authenticates the user with the RD API.
  ///
  Future<bool> authenticate(BuildContext context, { bool shouldShowSnackbar = false }) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => new RealDebridAuthenticator(),
      )
    );

    if (result != null && result is Map && result["access_token"] != null){
      RealDebridCredentials rdCredentials = new RealDebridCredentials.named(
        accessToken: result["access_token"],
        refreshToken: result["refresh_token"],
        expiryDate: DateTime.now().add(new Duration(seconds: result["expires_in"] - REAL_DEBRID_REFRESH_OFFSET)).toString()
      );

      await Settings.setRdCredentials(rdCredentials);
      if(shouldShowSnackbar) Interface.showSnackbar(S.of(context).connected_real_debrid_account, context: context, backgroundColor: Colors.green);
      return true;
    }

    if(result != null) Interface.showSnackbar(S.of(context).appname_was_unable_to_authenticate_with_real_debrid(appName), context: context, backgroundColor: Colors.red);
    return false;
  }

  ///
  /// This method removes the user's credentials.
  ///
  Future<void> deauthenticate(BuildContext context, { bool shouldShowSnackbar = false }) async {
    await Settings.setRdCredentials(RealDebridCredentials.unauthenticated());
    if(shouldShowSnackbar) Interface.showSnackbar(S.of(context).disconnected_real_debrid_account, context: context, backgroundColor: Colors.red);
  }

  Future<RealDebridUser> getUserInfo() async {
    await Service.get<RealDebrid>().validateToken();

    RealDebridCredentials rdCredentials = await Settings.rdCredentials;
    Map<String, String> userHeader = {'Authorization': 'Bearer ' + rdCredentials.accessToken};

    http.Response userDataResponse = await http.get(
      REAL_DEBRID_API_ENDPOINT + "/user",
      headers: userHeader
    );

    if (userDataResponse.statusCode == 200) {
      // Get Real-Debrid user information.
      return RealDebridUser.fromJSON(json.decode(userDataResponse.body));
    }

    return null;
  }

  /// IT SEEMS WE DO NOT HAVE ACCESS TO THIS METHOD.
  Future<bool> convertFidelityPoints(BuildContext context, { bool shouldShowSnackbar = true }) async {
    throw new Exception("Unimplemented method. [We do not have access to this API method.]");
    /*await RealDebrid.validateToken();

    RealDebridCredentials rdCredentials = await Settings.rdCredentials;
    Map<String, String> userHeader = {'Authorization': 'Bearer ' + rdCredentials.accessToken};

    http.Response convertPointsResponse = await http.post(
        REAL_DEBRID_API_ENDPOINT + "/settings/convertPoints",
        headers: userHeader
    );

    print(convertPointsResponse.statusCode);
    print(convertPointsResponse.body);

    return false;*/
  }

  ///
  /// This will check whether or not a user is authenticated with the
  /// RD API.
  ///
  Future<bool> isAuthenticated() async {
    RealDebridCredentials rdCredentials = await Settings.rdCredentials;
    return rdCredentials != null && rdCredentials.isValid();
  }

  Future<Map> _getSecret(String device_code) async {
    String url = REAL_DEBRID_OAUTH_ENDPOINT + "/device"
        "/credentials?client_id=${RealDebrid.identity.clientId}&code=$device_code";

    http.Response res = await http.get(url);

    Map data = json.decode(res.body);

    List<String> rdClientInfo = [data["client_id"], data["client_secret"]];
    Settings.$_rdClientInfo = rdClientInfo;

    return data;
  }

  Future<Map> getToken(String device_code) async {
    Map data = await _getSecret(device_code);

    if (data["client_id"] != null || data["client_secret"] != null) {
      //get the token using the client id and client secret
      String url = REAL_DEBRID_OAUTH_ENDPOINT + "/token";

      Map body = {
        "client_id": data["client_id"],
        "client_secret": data["client_secret"],
        "code": device_code,
        "grant_type": "http://oauth.net/grant_type/device/1.0"
      };

      http.Response res = await http.post(url, body: body);
      if (res.statusCode == 200) {
        return json.decode(res.body);
      }
    }

    return {"access_token": null};
  }

  Future<bool> _refreshToken() async {
    String url = REAL_DEBRID_OAUTH_ENDPOINT + "/token";

    //get rd credentials
    RealDebridCredentials rdCredentials = await Settings.rdCredentials;
    List<String> rdClientInfo = await Settings.$_rdClientInfo;

    Map body = {
      "grant_type": "http://oauth.net/grant_type/device/1.0",
      "client_id": rdClientInfo[0],
      "client_secret": rdClientInfo[1],
      "code": rdCredentials.refreshToken
    };

    http.Response res = await http.post(url, body: body);

    if (res.statusCode == 200) {
      Map result = json.decode(res.body);

      RealDebridCredentials credentials = new RealDebridCredentials.named(
        accessToken: result["access_token"],
        refreshToken: result["refresh_token"],
        expiryDate: DateTime.now().add(new Duration(seconds: result["expires_in"] - REAL_DEBRID_REFRESH_OFFSET)).toString()
      );
      await Settings.setRdCredentials(credentials);

      return true;
    }

    return false;
  }

  Future<Map<String, dynamic>> unrestrictLink(String link) async {
    RealDebridCredentials rdCredentials = await Settings.rdCredentials;
    Map<String, String> userHeader = {'Authorization': 'Bearer ' + rdCredentials.accessToken};

    http.Response _StreamLinkRes = await http
        .post(REAL_DEBRID_API_ENDPOINT + "/unrestrict/link", headers: userHeader, body: {"link": link});

    if (_StreamLinkRes.statusCode == 200) {
      //get the derestricted stream response
      return json.decode(_StreamLinkRes.body);
    }

    return null;
  }

  Future<void> validateToken() async {
    RealDebridCredentials rdCredentials = await Settings.rdCredentials;
    bool tokenCheck = DateTime.now().isBefore(DateTime.parse(rdCredentials.expiryDate));

    if (!tokenCheck) {
      return await _refreshToken();
    }
  }
}

class RealDebridAuthenticator extends StatefulWidget {
  RealDebridAuthenticator();

  @override
  _RealDebridAuthenticatorState createState() => new _RealDebridAuthenticatorState();
}

class _RealDebridAuthenticatorState extends State<RealDebridAuthenticator> {

  final flutterWebviewPlugin = new FlutterWebviewPlugin();
  StreamSubscription<String> _onUrlChanged;

  Map oauthData;

  String targetUrl;
  bool isAllowed = false;
  // Whether the user will be completing the login process in the app.
  // null = unset (prompt user)
  // false = use code
  // true = login in-app
  bool inAppLogin;

  @override
  void initState() {
    _getOauthData().then((data){
      setState(() {
        oauthData = data;
      });
    });

    if(flutterWebviewPlugin != null) {
      flutterWebviewPlugin.close();

      // Listen for done via URL change.
      _onUrlChanged = flutterWebviewPlugin.onUrlChanged.listen((String url) async {
        // Execute a simple script to 'disarm' the Real-Debrid link
        await flutterWebviewPlugin.evalJavascript(
            "document.querySelectorAll(\"a[href='/']\").forEach((element) => element.onclick = (e) => e.preventDefault());"
        );

        // Check if the application has been authorized (so done state can be set).
        this.isAllowed = await flutterWebviewPlugin.evalJavascript('document.body.innerHTML.indexOf("Application allowed") !== -1') == "true";
        if(mounted) setState(() {});
      });
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if(oauthData == null) return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        title: TitleText(S.of(context).real_debrid_authenticator),
        centerTitle: true,
        elevation: 8.0,
      ),
      body: Center(
        child: ApolloLoadingSpinner(),
      ),
    );

    if(inAppLogin != null && inAppLogin) return WillPopScope(
      onWillPop: () async {
        setState(() {
          _resetOauthData();
        });

        return false;
      },
      child: targetUrl != null ? WebviewScaffold(
          url: targetUrl,
          userAgent: "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
              "(KHTML, like Gecko) Chrome/71.0.3578.98 Safari/537.36",
          clearCache: true,
          clearCookies: true,
          appBar: AppBar(
            leading: isAllowed ? Container() : IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: (){
                setState(() {
                  _resetOauthData();
                });
              },
            ),
            title: TitleText(S.of(context).real_debrid_authenticator),
            centerTitle: true,
            elevation: 8.0,
            backgroundColor: Theme.of(context).cardColor,
            actions: <Widget>[
              isAllowed ? FlatButton(
                child: Text(S.of(context).done.toUpperCase()),
                onPressed: () async {
                  if(this.context != null && mounted) Navigator.pop(
                      this.context,
                      await Service.get<RealDebrid>().getToken(oauthData["device_code"])
                  );
                },
              ) : Container()
            ],
          )
      ) : Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        appBar: AppBar(
          title: TitleText(S.of(context).real_debrid_authenticator),
          centerTitle: true,
          elevation: 8.0,
          backgroundColor: Theme.of(context).cardColor,
        ),
        body: Center(
          child: ApolloLoadingSpinner(),
        ),
      ),
    );

    if(inAppLogin != null && inAppLogin == false) return WillPopScope(
        onWillPop: () async {
          setState(() {
            _resetOauthData();
          });

          return false;
        },
        child: Scaffold(
          backgroundColor: Theme.of(context).backgroundColor,
          appBar: AppBar(
            leading: isAllowed ? Container() : IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: (){
                _resetOauthData();
              },
            ),
            title: TitleText(S.of(context).real_debrid_authenticator),
            centerTitle: true,
            elevation: 8.0,
            backgroundColor: Theme.of(context).cardColor,
            actions: <Widget>[
              isAllowed ? FlatButton(
                child: Text(S.of(context).done.toUpperCase()),
                onPressed: () async {
                  Navigator.pop(
                      this.context,
                      await Service.get<RealDebrid>().getToken(oauthData["device_code"])
                  );
                },
              ) : Container()
            ],
          ),
          body: Center(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 30),
              child: Card(
                elevation: 4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                      leading: SvgPicture.asset("assets/icons/realdebrid.svg", height: 36, width: 36, color: const Color(0xFF78BB6F)),
                      title: TitleText("Real-Debrid")
                    ),

                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 15),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                        Text("1. " + S.of(context).visit_the_following_url_in_your_browser + " ", style: TextStyle(
                          fontSize: 18,
                        )),
                        AutoSizeText("https://real-debrid.com/device", style: TextStyle(
                          fontFamily: 'monospace'
                        ), maxLines: 1),
                        Container(margin: EdgeInsets.symmetric(vertical: 5)),
                        RichText(text: TextSpan(children: [
                          TextSpan(text: "2. " + S.of(context).enter_the_following_code + " "),
                          TextSpan(text: oauthData["user_code"], style: TextStyle(
                              fontFamily: 'monospace'
                          ))
                        ], style: TextStyle(
                          fontSize: 16,
                        )))
                      ]),
                    ),

                    Container(margin: EdgeInsets.symmetric(vertical: 5)),
                    Center(child: Container(
                      child: RaisedButton.icon(onPressed: () async {
                        if((await Service.get<RealDebrid>().getToken(oauthData["device_code"]))["access_token"] == null){
                          Interface.showAlert(
                              context: context,
                              title: TitleText(S.of(context).appname_was_unable_to_authenticate_with_real_debrid(appName), allowOverflow: true),
                              content: [
                                Text(S.of(context).please_follow_the_instructions_shown_to_log_in_via_your_browser)
                              ],
                              actions: [
                                FlatButton(
                                  child: Text(S.of(context).okay.toUpperCase()),
                                  onPressed: (){
                                    Navigator.of(context).pop();
                                  },
                                )
                              ]
                          );
                          return;
                        }

                        Navigator.pop(
                            this.context,
                            await Service.get<RealDebrid>().getToken(oauthData["device_code"])
                        );
                      }, icon: Icon(Icons.done), label: Text("Done")),
                      margin: EdgeInsets.symmetric(vertical: 10),
                    ))
                  ],
                ),
              ),
            ),
          )
        )
    );


    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: AppBar(
        title: TitleText(S.of(context).real_debrid_authenticator),
        centerTitle: true,
        elevation: 8.0,
        backgroundColor: Theme.of(context).cardColor
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Column(children: <Widget>[
            Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
              Image.asset("assets/images/logo.png", height: 36),
              Text(" + ", style: TextStyle(fontSize: 24)),
              Image.asset("assets/icons/realdebrid-logo.png", height: 64),
            ]),
            TitleText(S.of(context).you_can_log_into_realdebrid_in_two_ways, textAlign: TextAlign.center),
          ]),

          Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  RaisedButton(child: Text(S.of(context).use_code.toUpperCase()), onPressed: (){
                    setState(() {
                      inAppLogin = false;
                    });
                  }),
                  Container(
                    child: Text(S.of(context).or),
                    margin: EdgeInsets.symmetric(horizontal: 10),
                  ),
                  RaisedButton(child: Text(S.of(context).login.toUpperCase()), onPressed: (){
                    setState(() {
                      inAppLogin = true;
                    });

                    _prepare().then((String target) {
                      if(mounted && target != null) setState(() {
                        targetUrl = target;
                      });
                    });
                  })
                ],
              ),

              Container(
                margin: EdgeInsets.only(top: 10),
                child: Text(S.of(context).if_youre_not_sure_what_these_options_are_just_use_login),
              )
            ],
          )
        ],
      ),
    );
  }

  Future<Map> _getOauthData() async {
    // Make a request to the API with the code to get oauth credentials.
    String url = "${RealDebrid.REAL_DEBRID_OAUTH_ENDPOINT}/device/code?client_id=${RealDebrid.identity.clientId}&new_credentials=yes";
    http.Response response = await http.get(url);
    Map data = json.decode(response.body);

    if (data["user_code"] == null) {
      Navigator.of(context).pop(Exception(S.of(context).appname_was_unable_to_authenticate_with_real_debrid(appName)));
    }

    return data;
  }

  void _resetOauthData(){
    setState(() {
      inAppLogin = null;
      oauthData = null;
    });

    (() async {
      oauthData = await _getOauthData();
      setState(() {});
    })();
  }

  Future<String> _prepare() async {
    http.Response response = await http.post(
      oauthData["verification_url"],
      headers: {
        'Content-Type': "application/x-www-form-urlencoded"
      },
      body: "usercode=${oauthData["user_code"]}&action=Continue"
    );

    return response.headers['location'];
  }

  @override
  void dispose() {
    flutterWebviewPlugin.dispose();
    super.dispose();
  }
}

class RealDebridUser {

  int id;
  String username;
  String email;
  int points;
  String locale;
  String avatar;
  String type;
  int premiumSecondsRemaining;
  DateTime expirationDate;

  RealDebridUser.fromJSON(Map json) :
    id = json['id'],
    username = json['username'],
    email = json['email'],
    points = json['points'],
    locale = json['locale'],
    avatar = json['avatar'],
    type = json['type'],
    premiumSecondsRemaining = json['premium'],
    expirationDate = DateTime.parse(json['expiration']);

  bool isPremium(){
    return this.type.toLowerCase() == "premium";
  }

  int get premiumDaysRemaining {
    return new DateTime.fromMillisecondsSinceEpoch(
      new DateTime.now().millisecondsSinceEpoch + (premiumSecondsRemaining * 1000)
    ).difference(
      new DateTime.now()
    ).inDays;
  }

}

class RealDebridIdentity{
  String clientId;

  RealDebridIdentity({
    @required this.clientId
  });
}