import 'package:flutter/material.dart';
import 'package:kamino/ui/elements.dart';

class SettingsPage extends StatefulWidget {

  final String title;
  final SettingsPageState pageState;
  final bool isPartial;

  SettingsPage({
    @required this.title,
    @required this.pageState,
    this.isPartial = false
  });

  @override
  createState() => pageState;

}

class SettingsPagePartial extends StatefulWidget {

  final SettingsPageState pageState;

  SettingsPagePartial({
     @required this.pageState
  });

  @override
  createState() => pageState;

}

abstract class SettingsPagePartialState extends SettingsPageState {

  @override
  Widget build(BuildContext context){
    return buildPage(context);
  }

}

abstract class SettingsPageState extends State<SettingsPage> {

  GlobalKey<ScaffoldState> _scaffoldKey;
  double _elevation;

  ///
  /// A [Widget] containing all of the settings widgets.
  ///
  Widget buildPage(BuildContext context);

  List<Widget> actions(BuildContext context){
    // Returns a blank list unless overridden.
    return <Widget>[];
  }

  GlobalKey<ScaffoldState> getScaffoldKey(){
    return _scaffoldKey;
  }

  @override
  void initState() {
    _scaffoldKey = new GlobalKey();
    _elevation = 0.0;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if(widget.isPartial) return new Column(
      children: <Widget>[
        Container(
            child: buildPage(context)
        )
      ],
    );

    return NotificationListener(
      onNotification: (notification){
        if(notification is OverscrollIndicatorNotification){
          if(notification.leading) notification.disallowGlow();
          return true;
        }

        if(notification is ScrollNotification){
          double elevation = _elevation;

          if(notification.metrics.pixels > 0) elevation = 4;
          else elevation = 0;

          if(_elevation != elevation) setState(() {
            _elevation = elevation;
          });
        }
      },
      child: Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: TitleText(widget.title),
            backgroundColor: Theme.of(context).backgroundColor,
            elevation: _elevation,

            // Center title
            centerTitle: true,

            // Page actions
            actions: actions(context),
          ),
          body: new Builder(builder: (BuildContext context) {
            return new Container(
              color: Theme.of(context).backgroundColor,
              child: buildPage(context),
            );
          })
      ),
    );
  }

}