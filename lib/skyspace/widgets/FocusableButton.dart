import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kamino/skyspace/tv_remote.dart';

typedef FocusableWidgetBuilder = Widget Function(BuildContext context, bool hasFocus);
class FocusableButton extends StatefulWidget {

  final FocusableWidgetBuilder builder;
  final Function onPress;

  FocusableButton({
    @required this.builder,
    @required this.onPress
  });

  @override
  State<StatefulWidget> createState() => FocusableButtonState();

}

class FocusableButtonState extends State<FocusableButton> {

  FocusNode _node;
  FocusAttachment _attachment;

  @override
  void initState() {
    _node = FocusNode(debugLabel: "FocusableButton");
    _attachment = _node.attach(context, onKey: _handleKeyPress);

    _node.addListener((){
      setState((){});
    });

    super.initState();
  }

  @override
  void dispose(){
    _node.dispose();
    super.dispose();
  }

  bool _handleKeyPress(FocusNode node, RawKeyEvent event) {
    // Ignore it unless it is an [OK] key down event.
    if (!(event is RawKeyDownEvent)) return false;
    if((event.data as RawKeyEventDataAndroid).keyCode != TVRemote.OK)
      return false;

    // Ignore it if the widget has not defined an onPress event.
    if (widget.onPress == null) return false;

    widget.onPress();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    _attachment.reparent();
    return widget.builder(context, _node.hasFocus);
  }


}