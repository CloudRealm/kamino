// Import flutter libraries
import 'dart:async';
import 'dart:io';

import 'package:connectivity/connectivity.dart';
import 'package:dart_chromecast/casting/cast.dart';
import 'package:kamino/animation/transition.dart';
import 'package:kamino/generated/i18n.dart';
import 'package:kamino/interface/favorites.dart';
import 'package:kamino/interface/intro/kamino_intro.dart';
import 'package:kamino/interface/launchpad2/browse.dart';
import 'package:kamino/interface/launchpad2/launchpad2.dart';
import 'package:kamino/interface/settings/utils/ota.dart' as OTA;
import 'package:kamino/skyspace/skyspace.dart';
import 'package:kamino/ui/elements.dart';
import 'package:kamino/ui/interface.dart';
import 'package:kamino/util/settings.dart';
import 'package:kamino/vendor/dist/ShimVendorConfiguration.dart';
import 'package:kamino/vendor/struct/ThemeConfiguration.dart';
import 'package:kamino/vendor/struct/VendorConfiguration.dart';
import 'package:kamino/vendor/struct/VendorService.dart';
import 'package:logging/logging.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kamino/vendor/index.dart';

import 'package:kamino/interface/settings/settings.dart';
import 'package:package_info/package_info.dart';
import 'package:http/http.dart' as http;

const appName = "ApolloTV";
const appCastID = "6569632D";
Logger log;

PlatformType currentPlatform;
const platform = const MethodChannel('xyz.apollotv.kamino/init');
enum PlatformType {
  GENERAL,
  TV
}

class ErrorScaffold extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}

Future<void> reportError(error, StackTrace stacktrace, {shouldShowDialog = false, cancelPop = false}) async {
  try {
    print(error.toString());
    print(stacktrace);

    PackageInfo packageInfo = await SettingsManager.getPackageInfo();

    OverlayState overlay = KaminoApp.navigatorKey.currentState.overlay;
    if(overlay == null || overlay.context == null || !shouldShowDialog) return;
    BuildContext context = overlay.context;

    if(Navigator.of(context).canPop() && !cancelPop) Navigator.of(context).pop();

    if(error is SocketException){
      showDialog(context: context, builder: (BuildContext context){
        return AlertDialog(
          title: Icon(Icons.offline_bolt, size: 42, color: Colors.grey),
          content: Container(
            width: MediaQuery.of(context).size.width,
            height: 150,
            child: ListView(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              children: <Widget>[
                TitleText(S.of(context).unable_to_connect, fontSize: 26, textAlign: TextAlign.center),
                Container(margin: EdgeInsets.symmetric(vertical: 10)),
                Text(S.of(context).appname_failed_to_connect_to_the_internet(appName), style: TextStyle(
                  fontFamily: 'GlacialIndifference',
                  fontSize: 18,
                ), textAlign: TextAlign.center),
                Container(
                  margin: EdgeInsets.only(top: 15),
                  child: RaisedButton(
                    onPressed: (){
                      Navigator.of(context).pop();
                    },
                    child: Text(S.of(context).close.toUpperCase()),
                    color: Theme.of(context).backgroundColor,
                    elevation: 2,
                    highlightElevation: 2
                  ),
                )
              ]
            ),
          )
        );
      });

      return;
    }

    String _errorReference;
    try {
      _errorReference = stacktrace.toString().split("\n").firstWhere((line) => line.contains("kamino")).split("     ")[1];
    }catch(_){}

    if(_errorReference != null) showDialog(context: context, builder: (BuildContext context) {
      return AlertDialog(
        title: TitleText(S.of(context).an_error_occurred, fontSize: 26, textAlign: TextAlign.center),
        content: Container(
          width: MediaQuery.of(context).size.width,
          height: 0.4 * MediaQuery.of(context).size.height,
          child: ListView(
            children: <Widget>[
              Text(S.of(context).take_screenshot_report_apollotv_discord, style: TextStyle(
                  fontFamily: 'GlacialIndifference',
                  fontSize: 18
              )),
              Container(child: Divider(), margin: EdgeInsets.symmetric(vertical: 10)),
              Container(child: Text("$appName v${packageInfo.version} \u2022 ${KaminoAppState._getInstance().getPrimaryVendorConfig().getName()} Build ${packageInfo.buildNumber}\n", textAlign: TextAlign.center)),
              Container(child: Text(error.toString() + "\n")),
              RichText(
                text: TextSpan(
                    children: <TextSpan>[
                      TextSpan(text: "Reference: ", style: TextStyle(
                          color: Theme.of(context).textTheme.body1.color
                      )),
                      TextSpan(text: _errorReference, style: TextStyle(fontFamily: 'monospace', color: Theme.of(context).textTheme.body1.color))
                    ]
                ),
              )
            ],
          ),
        ),
        actions: <Widget>[
          FlatButton(
            textColor: Theme.of(context).textTheme.button.color,
            child: Text(S.of(context).open_discord),
            onPressed: () => Interface.launchURL("https://discord.gg/euyQRWs"),
          ),
          FlatButton(
            textColor: Theme.of(context).textTheme.button.color,
            child: Text(S.of(context).dismiss),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      );
    });
  }catch(_){}
}

void main() async {
  // Setup logger
  Logger.root.level = Level.OFF;
  Logger.root.onRecord.listen((record) {
    print("[${record.loggerName}: ${record.level.name}] [${record.time}]: ${record.message}");
  });
  log = new Logger(appName);

  /// Get device type and initialize [SettingsManager]
  () async {
    await SettingsManager.onAppInit();

    if(Platform.isAndroid) {
      switch (await platform.invokeMethod('getDeviceType')) {
        case 1:
          return PlatformType.TV;
      }
    }
    return PlatformType.GENERAL;
  }().then((platformType){
    currentPlatform = platformType;

    FlutterError.onError = (FlutterErrorDetails details) async {
      print("A Flutter exception was caught by the $appName internal error handler.");
      await reportError(details.exception, details.stack);
    };

    runZoned<Future<void>>((){
      // Start Kamino (mobile)
      runApp(KaminoApp());
    }, onError: (error, StackTrace stacktrace) async {
      print("A Dart zone exception was caught by the $appName internal error handler.");
      await reportError(error, stacktrace, shouldShowDialog: true);
    });

  });
}

class KaminoAppDelegateProxyRenderer extends StatefulWidget {

  final Widget child;
  KaminoAppDelegateProxyRenderer({ @required this.child });

  @override
  State<StatefulWidget> createState() => KaminoAppDelegateProxy();

}

class KaminoAppDelegateProxy extends State<KaminoAppDelegateProxyRenderer> {

  @override
  Widget build(BuildContext context) => widget.child;

}

class KaminoApp extends StatefulWidget {

  static final navigatorKey = GlobalKey<NavigatorState>();

  @override
  State<StatefulWidget> createState() => KaminoAppState();

}

class KaminoAppState extends State<KaminoApp> {

  CastSender _activeCastSender;
  Locale _currentLocale;

  List<VendorConfiguration> _vendorConfigs;
  List<ThemeConfiguration> _themeConfigs;
  String _activeTheme;
  Color _primaryColorOverride;

  CastSender get activeCastSender {
    return _activeCastSender;
  }

  set activeCastSender (CastSender sender){
    setState(() {
      _activeCastSender = sender;
    });
  }

  // This is used in [main.dart] only, as a fallback.
  static KaminoAppState _instance;
  static KaminoAppState _getInstance(){
    return _instance;
  }

  KaminoAppState(){
    _instance = this;

    // Load vendor and theme configs.
    _vendorConfigs = ApolloVendor.getVendorConfigs();
    _themeConfigs = ApolloVendor.getThemeConfigs();

    // Validate vendor and theme configs
    _themeConfigs.forEach((element){
      if(_themeConfigs.where((consumer) => element.getId() == consumer.getId()).length > 1)
        throw new Exception("Each theme must have a unique ID. Duplicate ID is: ${element.getId()}");
    });

    // Load active theme and primary color override.
    _activeTheme = _themeConfigs[0].getId();
    _primaryColorOverride = null;

    _loadActiveTheme();
    _loadLocale();
  }

  Future<void> setLocale(Locale locale) async {
    await (Settings.locale = [locale.languageCode, locale.countryCode]);
    await _loadLocale();
  }

  Future<void> _loadLocale() async {
    if(!SettingsManager.hasKey("locale")) return;
    var localePref = await Settings.locale;

    setState(() {
      _currentLocale = Locale(localePref[0], localePref[1]);
    });
  }

  Future<void> _loadActiveTheme() async {
    var theme = await (Settings.activeTheme);
    var primaryColorOverride = await (Settings.primaryColorOverride);

    setState(() {
      // If the restored theme setting pref is not null AND the theme exists,
      if(theme != null && _themeConfigs.where((consumer) => consumer.id == theme).length > 0)
        // then apply the theme if it is not already applied.
        if(_activeTheme != null) _activeTheme = theme;

      if(primaryColorOverride != null)
        if(_primaryColorOverride.toString() != primaryColorOverride)
          _primaryColorOverride = new Color(int.parse(primaryColorOverride.split('(0x')[1].split(')')[0], radix: 16));

      // Update SystemUI
      SystemChrome.setSystemUIOverlayStyle(
          getActiveThemeMeta().getOverlayStyle().copyWith(
              statusBarColor: const Color(0x00000000),
              systemNavigationBarColor: getActiveThemeData().cardColor
          )
      );
    });
  }

  Widget _getErrorWidget(FlutterErrorDetails error){
    BuildContext context = KaminoApp.navigatorKey.currentState.overlay.context;

    TextStyle _errorStyle = TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontFamily: ApolloVendor.getThemeConfigs()[0].getThemeData().textTheme.body1.fontFamily,
      decoration: TextDecoration.none,
      fontWeight: FontWeight.normal
    );

    String _errorReference = "Unknown stack reference.";
    try {
      _errorReference = error.stack.toString().split("\n").firstWhere((line) => line.contains("kamino")).split("     ")[1];
    }catch(_){}

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10),
      color: ApolloVendor.getThemeConfigs()[0].getThemeData().backgroundColor,
      child: ListView(
        children: <Widget>[
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Image.asset("assets/images/logo.png", width: 64),

              Container(
                padding: EdgeInsets.only(top: 10),
                child: Center(
                    child: Text(S.of(context).an_error_occurred, style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontFamily: 'GlacialIndifference',
                        fontFamilyFallback: ['SF UI Display', 'Roboto'],
                        decoration: TextDecoration.none,
                        fontWeight: FontWeight.normal
                    ))
                ),
              ),

              Container(
                padding: EdgeInsets.only(top: 10),
                child: Text(error.exceptionAsString(), style: _errorStyle),
              ),

              Container(child: Text("Library: ${error.library}", style: _errorStyle)),
              Container(
                  margin: EdgeInsets.symmetric(horizontal: 30),
                  padding: EdgeInsets.only(top: 30),
                  child: Text("Reference: $_errorReference",
                      textAlign: TextAlign.center,
                      style: _errorStyle)
              ),

              Container(
                margin: EdgeInsets.symmetric(horizontal: 30),
                padding: EdgeInsets.only(top: 30),
                child: Text(S.of(context).take_screenshot_report_apollotv_discord, style: _errorStyle.copyWith(fontSize: 18, fontFamily: 'GlacialIndifference'), textAlign: TextAlign.center),
              ),

              Container(
                padding: EdgeInsets.only(top: 30),
                child: FlatButton(
                    color: context != null ? Theme.of(context).primaryColor
                        : ApolloVendor.getThemeConfigs()[0].getThemeData().primaryColor,
                    child: Text("Open Discord", style: _errorStyle),
                    onPressed: () => Interface.launchURL("https://discord.gg/euyQRWs")
                ),
              ),
            ],
          )
        ],
      )
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ErrorWidget.builder = (FlutterErrorDetails error) => _getErrorWidget(error);

    StatefulWidget applicationHome;
    if(currentPlatform == PlatformType.TV) {
      applicationHome = KaminoSkyspace();
    }else{
      applicationHome = KaminoAppHome();
    }

    return new KaminoAppDelegateProxyRenderer(child: MaterialApp(
      navigatorKey: KaminoApp.navigatorKey,
      localizationsDelegates: [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate
      ],
      supportedLocales: S.delegate.supportedLocales,
      locale: _currentLocale != null ? _currentLocale : Locale('en'),

      title: appName,
      home: applicationHome,
      theme: getActiveThemeData(),

      // Hide annoying debug banner
      debugShowCheckedModeBanner: false
    ));
  }

  Future<bool> isShimVendorEnabled() async {
    return await Settings.serverURLOverride != null &&
        await Settings.serverKeyOverride != null;
  }

  Future<VendorService> getPrimaryVendorService({ bool excludeShim = false }) async {
    if(!excludeShim && await isShimVendorEnabled()){
      return ShimVendorConfiguration().getService();
    }

    return await getPrimaryVendorConfig().getService();
  }

  VendorConfiguration getPrimaryVendorConfig(){
    return getAllVendorConfigs()[0];
  }

  List<VendorConfiguration> getAllVendorConfigs(){
    return _vendorConfigs.toList(growable: false);
  }

  List<ThemeConfiguration> getThemeConfigs(){
    return _themeConfigs;
  }

  String getActiveTheme(){
    return _activeTheme;
  }

  ThemeConfigurationAdapter getActiveThemeMeta(){
    return ThemeConfigurationAdapter.fromConfig(
        _themeConfigs.singleWhere((consumer) => consumer.getId() == _activeTheme)
    );
  }

  ThemeData getActiveThemeData({ bool ignoreOverride: false }){
    if(_primaryColorOverride != null && !ignoreOverride)
      return _themeConfigs.singleWhere((consumer) => consumer.getId() == _activeTheme)
          .getThemeData(primaryColor: _primaryColorOverride);

    return _themeConfigs.singleWhere((consumer) => consumer.getId() == _activeTheme)
        .getThemeData();
  }

  void setActiveTheme(String activeTheme){
    setState((){
      _activeTheme = activeTheme;

      // MD2: Update SystemUI theme and status bar transparency
      SystemChrome.setSystemUIOverlayStyle(
          getActiveThemeMeta().getOverlayStyle().copyWith(
            statusBarColor: const Color(0x00000000),
            systemNavigationBarColor: getActiveThemeData().cardColor,
          )
      );

      // Update preferences
      Settings.activeTheme = activeTheme;
    });
  }

  Color getPrimaryColorOverride(){
    return _primaryColorOverride;
  }

  void setPrimaryColorOverride(Color color){
    setState(() {
      _primaryColorOverride = color;
      setActiveTheme(getActiveTheme());

      Settings.primaryColorOverride = color.toString();
    });
  }

}

class KaminoAppHome extends StatefulWidget {

  @override
  KaminoAppHomeState createState() => KaminoAppHomeState();

}

class KaminoAppPage extends StatefulWidget {

  @override
  State<StatefulWidget> createState() {
    return null;
  }

  Widget buildHeader(BuildContext context){
    return null;
  }

}

class KaminoAppHomeState extends State<KaminoAppHome> {

  bool isConnected;

  final List<KaminoAppPage> _pages = [
    Launchpad2(),
    BrowseTVShowsPage(),
    BrowseMoviesPage(),
    FavoritesPage()
  ];
  int _activePage;

  Future<bool> _onWillPop() async {
    // Allow app close on back
    return true;
  }

  @override
  void initState() {
    _activePage = 0;
    isConnected = true;
    
    (() async {

      // If the initial setup is not complete, show the setup guide.
      if(!await Settings.initialSetupComplete){
        Navigator.of(context).push(MaterialPageRoute(
          builder: (BuildContext context) => KaminoIntro(then: () async {
            setState(() {});
            prepare();
          })
        ));
      }else{
        prepare();
      }

    })();
    
    super.initState();
  }

  StreamSubscription connectivityCheck;
  void prepare(){
    OTA.updateApp(context, true);
    connectivityCheck = Connectivity().onConnectivityChanged.listen((ConnectivityResult result){
      http.head("https://static.apollotv.xyz/generate_204").then((http.Response response){
        if(response == null || response.statusCode != 204) {
          isConnected = false;
        }
      }).catchError((error) => isConnected = false);
    });
  }

  @override
  void dispose(){
    connectivityCheck.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new WillPopScope(
      onWillPop: _onWillPop,
      child: new Scaffold(
        resizeToAvoidBottomPadding: false,
        backgroundColor: Theme.of(context).backgroundColor,
        // backgroundColor: backgroundColor,
        appBar: AppBar(
          title: Row(
            children: <Widget>[
              _pages.elementAt(_activePage).buildHeader(context) != null
                ? _pages.elementAt(_activePage).buildHeader(context)
                : Interface.generateHeaderLogo(context)
            ],
          ),

          //backgroundColor: Theme.of(context).backgroundColor,
          //elevation: 0,

          backgroundColor: Theme.of(context).cardColor,
          elevation: 6,

          actions: <Widget>[
            CastButton(),

            Interface.generateSearchIcon(context),

            PopupMenuButton<String>(
              tooltip: "Options",
              icon: Icon(Icons.more_vert),
              onSelected: (String index){
                switch(index){
                  case 'discord': return Interface.launchURL("https://discord.gg/euyQRWs");
                  case 'blog': return Interface.launchURL("https://medium.com/apolloblog");
                  case 'privacy': return Interface.launchURL("https://apollotv.xyz/legal/privacy");
                  case 'donate': return Interface.launchURL("https://apollotv.xyz/donate");
                  case 'settings': return Navigator.push(context, ApolloTransitionRoute(
                      builder: (context) => SettingsView()
                  ));

                  default: Interface.showSnackbar("Invalid menu option. Option '$index' was not defined.", context: context);
                }
              },
              itemBuilder: (BuildContext context){
                return [
                  PopupMenuItem<String>(
                    value: 'discord',
                    child: Container(child: Text(S.of(context).discord), padding: EdgeInsets.only(right: 50)),
                  ),

                  PopupMenuItem<String>(
                    value: 'blog',
                    child: Container(child: Text(S.of(context).blog), padding: EdgeInsets.only(right: 50))
                  ),

                  PopupMenuItem<String>(
                    value: 'privacy',
                    child: Container(child: Text(S.of(context).privacy), padding: EdgeInsets.only(right: 50))
                  ),

                  PopupMenuItem<String>(
                    value: 'donate',
                    child: Container(child: Text(S.of(context).donate), padding: EdgeInsets.only(right: 50))
                  ),

                  PopupMenuItem<String>(
                    value: 'settings',
                    child: Container(child: Text(S.of(context).settings), padding: EdgeInsets.only(right: 50))
                  )
                ];
              }
            )
          ],

          // Center title
          centerTitle: false
        ),

          // Body content
        body: Builder(builder: (BuildContext context){
          if(!isConnected) return OfflineMixin(
            reloadAction: () async {
              setState(() {});
            },
          );

          return _pages.elementAt(_activePage);
        }),

        bottomNavigationBar: BottomNavigationBar(
          elevation: 0,

          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).cardColor,
          selectedItemColor: Theme.of(context).primaryColor,

          showSelectedLabels: false,
          showUnselectedLabels: false,
          selectedFontSize: 14,
          unselectedFontSize: 14,

          onTap: (index){
            setState(() => _activePage = index);
          },
          currentIndex: _activePage,

          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              title: Text(S.of(context).home),
              icon: Icon(Icons.home)
            ),

            BottomNavigationBarItem(
              title: Text(S.of(context).tv_shows),
              icon: Icon(Icons.live_tv)
            ),

            BottomNavigationBarItem(
              title: Text(S.of(context).movies),
              icon: Icon(Icons.local_movies)
            ),

            BottomNavigationBarItem(
              title: Text(S.of(context).favorites),
              icon: Icon(Icons.favorite)
            ),
          ]
        ),
      )
    );
  }

}