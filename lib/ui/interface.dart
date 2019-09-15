import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kamino/animation/transition.dart';
import 'package:kamino/generated/i18n.dart';
import 'package:kamino/interface/content/overview.dart';
import 'package:kamino/interface/search/search.dart';
import 'package:kamino/main.dart';
import 'package:kamino/models/content/content.dart';
import 'package:kamino/ui/elements.dart';
import 'package:kamino/ui/loading.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:url_launcher/url_launcher.dart';

class Interface {

  static void openOverview(BuildContext context, dynamic reference, [ContentType type]){
    int id = -1;
    if(reference is ContentModel) {
      id = reference.id;
      type = reference.contentType;
    } else id = reference;

    Navigator.of(context).push(
        ApolloTransitionRoute(builder: (BuildContext context) => ContentOverview(
          contentId: id,
          contentType: type,
        ))
    );
  }

  static Widget generateHeaderLogo(BuildContext context){
    KaminoAppState appState = context.ancestorStateOfType(const TypeMatcher<KaminoAppState>());

    return Image.asset(
        appState.getActiveThemeData().brightness == Brightness.dark ?
        "assets/images/header_text.png" : "assets/images/header_text_dark.png",
        height: kToolbarHeight - 38
    );
  }

  static IconButton generateSearchIcon(BuildContext context) {
    return IconButton(
      tooltip: S.of(context).search,
      icon: Icon(Icons.search),
      color: Theme.of(context).primaryTextTheme.body1.color,
      onPressed: () => Navigator.of(context).push(ApolloTransitionRoute(
        builder: (BuildContext context) => SearchPage()
      )),
    );
  }
  static void showAlert({@required BuildContext context, @required Widget title, @required List<Widget> content, bool dismissible = false, @required List<Widget> actions}){
    showDialog(
      context: context,
      barrierDismissible: dismissible,
      builder: (BuildContext responseContext) {
        return AlertDialog(
          title: title,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: content,
          ),
          actions: actions
        );
      }
    );
  }

  static Future<void> showSimpleSuccessDialog(BuildContext context, {String title, String message, FlatButton alternativeAction}) async {
    if(title == null) title = S.of(context).success;
    if(message == null) message = S.of(context).action_completed_successfully;
    
    Interface.showAlert(
        context: context,
        title: TitleText(title), // Title
        content: <Widget>[
          Text(message)
        ],
        dismissible: true,
        actions: [
          alternativeAction != null
              ? alternativeAction
              : null,

          new FlatButton(
            onPressed: (){
              Navigator.of(context).pop();
            },
            child: Text("Okay"),
            textColor: Theme.of(context).primaryColor,
          )
        ]
    );
  }

  static Future<void> showSimpleErrorDialog(BuildContext context, {String title, String reason, FlatButton alternativeAction}) async {
    if(title == null) title = S.of(context).an_error_occurred;
    if(reason == null) reason = S.of(context).unable_to_determine_reason;
    
    Interface.showAlert(
        context: context,
        title: TitleText(title), // Title
        content: <Widget>[
          Text(reason)
        ],
        dismissible: true,
        actions: [
          alternativeAction != null
            ? alternativeAction
            : null,

          new FlatButton(
            onPressed: (){
              Navigator.of(context).pop();
            },
            child: Text(S.of(context).close),
            textColor: Theme.of(context).primaryColor,
          )
        ]
    );
  }

  static void showSnackbar(String text, { BuildContext context, ScaffoldState state, Color backgroundColor = Colors.green }){
    try {
      var snackbar = SnackBar(
        duration: Duration(milliseconds: 1500),
        content: TitleText(text, textColor: Colors.white),
        backgroundColor: backgroundColor
      );

      if(context != null) { Scaffold.of(context).showSnackBar(snackbar); return; }
      if(state != null) { state.showSnackBar(snackbar); return; }

      print("Unable to show snackbar (text='$text')! No context or state was provided.");
    }catch(ex){
      print("Error showing snackbar!");
      print(ex);
    }
  }

  static Future<void> launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  static void showLanguageSelectionDialog(BuildContext context){
    showDialog(
        context: context,
        builder: (_) {
          var localesList = S.delegate.supportedLocales.map((element) => element).toList();
          localesList.sort((a, b) => a.languageCode.compareTo(b.languageCode) * -1);
          localesList.sort((_l1, _l2) => _l1.languageCode == "en" ? -1 : 1);
          localesList.sort((_l1, _l2) => _l1.languageCode == "en"
              && _l1.countryCode == "GB"
              && _l2.languageCode == "en"
              && _l2.countryCode == "" ? 1 : -1);

          return SimpleDialog(
              title: TitleText(S.of(context).select_language),
              children: <Widget>[
                Container(
                    height: 400,
                    width: 300,
                    child: ListView.builder(itemBuilder: (BuildContext context, int index) {
                      var currentLocale = localesList[index];
                      var languageCode = currentLocale.languageCode;
                      var languageCountry = currentLocale.countryCode;

                      var iconFile = getLocaleFlag(languageCode, languageCountry);
                      Future _loadLocaleData = S.delegate.load(currentLocale);

                      return FutureBuilder(future: _loadLocaleData, builder: (_, AsyncSnapshot snapshot) {
                        return ListTile(
                          title: TitleText(snapshot.data.$_language_name),
                          subtitle: Text(snapshot.data.$_language_name_english),
                          leading: Container(
                            child: FadeInImage(
                              fadeInDuration: Duration(milliseconds: 400),
                              placeholder: MemoryImage(kTransparentImage),
                              image: AssetImage(
                                "assets/flags/$iconFile.png"
                              ),
                              fit: BoxFit.contain,
                              alignment: Alignment.center,
                              width: 48,
                            )
                          ),
                          enabled: true,
                          onTap: () async {
                            KaminoAppState appState = context.ancestorStateOfType(const TypeMatcher<KaminoAppState>());
                            await appState.setLocale(currentLocale);
                            Navigator.of(context).pop();
                          },
                        );
                      });
                    }, itemCount: localesList.length, shrinkWrap: true)
                )
              ]);
        }
    );
  }

  static String getLocaleFlag(String languageCode, String languageCountry){

    String iconFile = languageCode;
    String iconVariant = languageCountry;

    // Flag corrections
    if(iconFile == "ar") iconFile = "arab_league";
    if(iconFile == "he") iconFile = "hebrew";
    if(iconFile == "en" && iconVariant == "GB") iconFile = "gb";
    if(iconFile == "en") iconFile = "us";
    // ./Flag corrections

    return iconFile;

  }

  static void showConnectingDialog(BuildContext context, { Function onPop }){
    showDialog(
        context: context,
        builder: (BuildContext context) => WillPopScope(
          onWillPop: () async {
            if(onPop != null) onPop();
            return false;
          },
          child: AlertDialog(
              title: TitleText(S.of(context).connecting),
              content: SingleChildScrollView(
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    Container(
                        padding: EdgeInsets.only(top: 10, bottom: 10, left: 10, right: 20),
                        child: new ApolloLoadingSpinner()
                    ),
                    Center(child: Text(S.of(context).please_wait))
                  ],
                ),
              ),

            actions: <Widget>[
              new FlatButton(
                onPressed: (){
                  if(onPop != null) onPop();
                },
                child: Text(S.of(context).cancel),
                textColor: Theme.of(context).primaryColor,
              )
            ],
          ),
        )
    );
  }

  static void showLoadingDialog(BuildContext context, { String title, bool canCancel = false, Function onCancel }){
    if(title == null) title = S.of(context).loading;

    showDialog(
      barrierDismissible: canCancel,
      context: context,
      builder: (BuildContext context) => WillPopScope(
        onWillPop: () async {
          if(!canCancel) return false;
          if(onCancel != null) onCancel();
          return true;
        },
        child: AlertDialog(
          title: TitleText(title),
          content: SingleChildScrollView(
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Container(
                    padding: EdgeInsets.only(top: 10, bottom: 10, left: 10, right: 20),
                    child: ApolloLoadingSpinner()
                ),
                Center(child: Text(S.of(context).please_wait))
              ],
            ),
          ),

          actions: canCancel ? <Widget>[
            new FlatButton(
              onPressed: (){
                if(onCancel != null) onCancel();
                Navigator.of(context).pop();
              },
              child: Text(S.of(context).cancel),
              textColor: Theme.of(context).primaryColor,
            )
          ] : [],
        ),
      )
    );
  }

}

class EmptyScrollBehaviour extends ScrollBehavior {

  @override
  Widget buildViewportChrome(BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }

}