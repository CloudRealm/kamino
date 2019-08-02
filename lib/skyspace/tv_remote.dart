 import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class TVRemote {
  static const UP_ARROW = 19;
  static const DOWN_ARROW = 20;
  static const LEFT_ARROW = 21;
  static const RIGHT_ARROW = 22;

  static const OK = 23;
 }

 class SkyspaceRemoteWrapper extends StatefulWidget {

   final Widget child;

   SkyspaceRemoteWrapper({
     @required this.child
   });

   @override
   State<StatefulWidget> createState() => SkyspaceRemoteWrapperState();

 }

 class SkyspaceRemoteWrapperState extends State<SkyspaceRemoteWrapper> {

   bool _initializedFocusNode = false;

   @override
   void initState(){
     super.initState();
   }

   @override
   Widget build(BuildContext context) {
     if (!_initializedFocusNode) {
       _initializedFocusNode = true;
     }

     return DefaultFocusTraversal(
       policy: ReadingOrderTraversalPolicy(),
       child: FocusScope(
         onKey: _handleKeyEvent,
         autofocus: true,
         child: widget.child,
       ),
     );
   }

   bool _handleKeyEvent(FocusNode node, RawKeyEvent event){
       if(!(event.data is RawKeyEventDataAndroid)) return true;
       if(!(event is RawKeyDownEvent)) return true;

       var _event = event.data as RawKeyEventDataAndroid;

       switch(_event.keyCode){
         case TVRemote.UP_ARROW:
           node.focusInDirection(TraversalDirection.up);
           break;

         case TVRemote.DOWN_ARROW:
           node.focusInDirection(TraversalDirection.down);
           break;

         case TVRemote.LEFT_ARROW:
           node.focusInDirection(TraversalDirection.left);
           break;

         case TVRemote.RIGHT_ARROW:
           node.focusInDirection(TraversalDirection.right);
           break;

         case TVRemote.OK:
           final renderObject = context.findRenderObject();
           if(renderObject is RenderBox){
             // Get the currently focused node.
             FocusNode focusedNode = node.enclosingScope.children.first.children.where((node) => node.hasFocus).first;

             // Get a list of elements at the focused node's coordinates
             BoxHitTestResult result = BoxHitTestResult();
             renderObject.hitTest(result, position: focusedNode.rect.center);

             // Call handleEvent on that pointer event.
             result.path.forEach((entry){
               print(entry.target.runtimeType);

               if(entry.target is RenderSemanticsGestureHandler){
                 var target = entry.target as RenderSemanticsGestureHandler;
                 if(event is RawKeyDownEvent) target.onTap();
               }
             });

           }

           break;
       }

       setState(() {});
       return true;
   }

 }