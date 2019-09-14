import 'package:flutter/material.dart';

///
/// This route transition currently mirrors that of Android Q's
/// 'Material Design 2' page transition. (An expand-fade effect)
///
class ApolloTransitionRoute extends PageRouteBuilder {

  bool isFullscreenDialog;
  @override
  bool get fullscreenDialog => isFullscreenDialog ?? false;

  Curve get animationCurve => Curves.easeInOut;

  ApolloTransitionRoute({
    WidgetBuilder builder,
    RouteSettings settings,
    this.isFullscreenDialog
  }) : super(
      pageBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation
      ) => builder(context),
      settings: settings,
      transitionDuration: Duration(milliseconds: 200),
  );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child
  ){
    return new ScaleTransition(
        scale: new Tween<double>(
            begin: 0.90,
            end: 1
        ).animate(CurvedAnimation(
            parent: animation,
            curve: animationCurve
        )),
        child: FadeTransition(
          opacity: CurvedAnimation(
              parent: animation,
              curve: Interval(0.2, 0.9, curve: animationCurve)
          ),
          child: buildSecondaryTransitions(
              context,
              animation,
              secondaryAnimation,
              child
          )
        )
    );
  }

  Widget buildSecondaryTransitions(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child
  ){
    return ScaleTransition(
      scale: new Tween<double>(
          begin: 1,
          end: 1.04
      ).animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: animationCurve
      )),
      child: child,
    );
  }

}