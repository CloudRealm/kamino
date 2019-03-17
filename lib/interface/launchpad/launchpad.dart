import 'package:flutter/material.dart';
import 'package:kamino/interface/launchpad/launchpad_renderer.dart';
import 'dart:async';
import 'package:kamino/util/trakt.dart' as trakt;

class Launchpad extends StatefulWidget {
  @override
  LaunchpadState createState() => new LaunchpadState();
}

class LaunchpadState extends State<Launchpad> {

  LaunchpadItemRenderer _renderer;

  @override
  void initState() {

    //check if trakt token needs renewing
    trakt.renewToken(context);

    _renderer = new LaunchpadItemRenderer();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        _renderer.refresh();
        await new Future.delayed(new Duration(seconds: 1));
        return null;
      },
      color: Theme.of(context).primaryColor,
      backgroundColor: Theme.of(context).backgroundColor,
      child: Scrollbar(child: Container(
        color: Theme.of(context).backgroundColor,
          child: Column(children: <Widget>[
            _renderer
          ]),
      )),
    );
  }

}
