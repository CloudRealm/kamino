import 'package:dart_chromecast/casting/cast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:kamino/cast/cast_devices_dialog.dart';
import 'package:kamino/generated/i18n.dart';
import 'package:kamino/main.dart';
import 'package:kamino/models/content/content.dart';
import 'package:kamino/models/list.dart';
import 'package:kamino/partials/content_card.dart';
import 'package:kamino/partials/content_poster.dart';
import 'package:kamino/ui/loading.dart';
import 'package:kamino/util/settings.dart';

import 'interface.dart';

class TitleText extends Text {

  TitleText(String text, {
    double fontSize : 18,
    Color textColor,
    bool allowOverflow = false,
    TextAlign textAlign,
    int maxLines,
    TextStyle style
  }) : super(
    text,
    overflow: (allowOverflow
        ? (maxLines == null ? null : TextOverflow.ellipsis)
        : TextOverflow.ellipsis),
    style: TextStyle().merge(style).copyWith(
      fontFamily: 'GlacialIndifference',
      fontSize: fontSize,
      color: textColor,
    ),
    textAlign: textAlign,
    maxLines: (allowOverflow ? maxLines : 1),
  );

}

class SubtitleText extends StatelessWidget {

  final String text;
  final EdgeInsetsGeometry padding;

  SubtitleText(this.text, {
    Key key,
    this.padding = const EdgeInsets.symmetric(horizontal: 5, vertical: 10)
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      child: Text(text.toUpperCase(), style: TextStyle(
        fontSize: 14,
        fontFamily: 'GlacialIndifference',
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
        color: Theme.of(context).primaryTextTheme.display3.color,
      ), textAlign: TextAlign.start),
      padding: padding,
    );
  }

}

class ConcealableText extends StatefulWidget {

  final String text;
  final String revealLabel;
  final String concealLabel;
  final Color color;
  final Color revealLabelColor;
  final TextOverflow overflowType;

  final int maxLines;

  ConcealableText(this.text, {
    @required this.revealLabel,
    @required this.concealLabel,
    @required this.maxLines,
    this.color,
    this.revealLabelColor,
    this.overflowType = TextOverflow.fade
  });

  @override
  State<StatefulWidget> createState() => ConcealableTextState();
}

class ConcealableTextState extends State<ConcealableText> {

  bool isConcealed = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        LayoutBuilder(builder: (context, size){
          var textSpan = TextSpan(
            text: widget.text,
            style: Theme.of(context).primaryTextTheme.body1.copyWith(
              color: widget.color
            )
          );

          var textPainter = TextPainter(
            textScaleFactor: MediaQuery.of(context).textScaleFactor,
            maxLines: widget.maxLines,
            textAlign: TextAlign.start,
            textDirection: Directionality.of(context),
            text: textSpan
          );

          textPainter.layout(maxWidth: size.maxWidth);
          var exceeded = textPainter.didExceedMaxLines;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTap: exceeded ? (){
              setState((){
                isConcealed = !isConcealed;
              });
            } : null,
            onLongPress: (){},
            child: Container(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text.rich(
                        textSpan,
                        overflow: widget.overflowType,
                        maxLines: (isConcealed ? widget.maxLines : null)
                    ),

                    if(exceeded) Padding(
                        padding: isConcealed ? EdgeInsets.only(top: 5.0) : EdgeInsets.only(top: 10.0),
                        child: Text(
                            isConcealed ? widget.revealLabel : widget.concealLabel,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: widget.revealLabelColor
                            )
                        )
                    )
                  ]
              ),
            ),
          );
        })
      ],
    );
  }

}

class ConcealableMarkdownText extends StatefulWidget {

  final MarkdownBody markdown;
  final String revealLabel;
  final String concealLabel;
  final Color revealLabelColor;

  final int maxLines;

  ConcealableMarkdownText(this.markdown, {
    @required this.revealLabel,
    @required this.concealLabel,
    @required this.maxLines,
    this.revealLabelColor,
  });

  @override
  State<StatefulWidget> createState() => ConcealableMarkdownTextState();
}

class ConcealableMarkdownTextState extends State<ConcealableMarkdownText> {

  bool isConcealed = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        LayoutBuilder(builder: (context, size){
          var textSpan = TextSpan(
              text: widget.markdown.data,
              style: widget.markdown.styleSheet != null ? widget.markdown.styleSheet.p : Theme.of(context).textTheme.body1
          );

          var textPainter = TextPainter(
            textScaleFactor: MediaQuery.of(context).textScaleFactor,
            maxLines: widget.maxLines,
            textAlign: TextAlign.start,
            textDirection: Directionality.of(context),
            text: textSpan,
          );

          textPainter.layout(maxWidth: size.maxWidth);
          var exceeded = textPainter.didExceedMaxLines;

          String markdownData = widget.markdown.data;
          if(isConcealed && exceeded){
            int splitBoundary = textPainter.getWordBoundary(
                textPainter.getPositionForOffset(Offset(textPainter.width, (textSpan.style.fontSize != null ? textSpan.style.fontSize : Theme.of(context).textTheme.body1.fontSize) * widget.maxLines))
            ).start;

            markdownData = markdownData.substring(0, splitBoundary);
            markdownData = ((){
              List<String> markdownList = markdownData.split("\n");
              void _trimLine(){
                markdownList.last = markdownList.last.replaceAll(RegExp("\.\$"), "");
                markdownList.last = markdownList.last.replaceAll(RegExp("\r\$"), "");
                markdownList.last = markdownList.last.replaceAll(RegExp("\n\$"), "");
                markdownList.last = markdownList.last.replaceAll(RegExp("\s\$"), "");
                markdownList.last = markdownList.last.trim();
              }
              _trimLine();

              if(markdownList.last == "") markdownList.removeLast();
              _trimLine();
              return markdownList;
            }()).join("\n");
            if(!markdownData.endsWith("\n")) markdownData += "...";
          }

          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                MarkdownBody(
                  data: markdownData,
                  styleSheet: widget.markdown.styleSheet,
                  syntaxHighlighter: widget.markdown.syntaxHighlighter,
                  onTapLink: widget.markdown.onTapLink,
                  imageDirectory: widget.markdown.imageDirectory
                ),

                (exceeded ?
                GestureDetector(
                  onTap: (){
                    setState((){
                      isConcealed = !isConcealed;
                    });
                  },
                  child: Padding(
                      padding: isConcealed ? EdgeInsets.only(top: 5.0) : EdgeInsets.only(top: 10.0),
                      child: Text(
                          isConcealed ? widget.revealLabel : widget.concealLabel,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: widget.revealLabelColor
                          )
                      )
                  ),
                )
                    : Container()
                )
              ]
          );
        })
      ],
    );
  }

}

class VerticalIconButton extends StatelessWidget {

  Color backgroundColor;
  Color foregroundColor;
  Widget icon;
  Widget title;
  EdgeInsetsGeometry padding;
  BorderRadiusGeometry borderRadius;
  GestureTapCallback onTap;


  VerticalIconButton({
    @required this.icon,
    @required this.title,
    @required this.onTap,
    this.backgroundColor,
    this.padding = const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
    this.borderRadius
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: borderRadius ?? BorderRadius.circular(5),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: borderRadius ?? BorderRadius.circular(5),
        onTap: onTap,
        child: Container(
          padding: padding,
          child: Column(
            children: <Widget>[
              icon,
              Container(child: title, margin: EdgeInsets.only(top: 10))
            ]
          )
        )
      )
    );
  }

}

class OfflineMixin extends StatefulWidget {

  final Function reloadAction;

  OfflineMixin({
    this.reloadAction
  });

  @override
  State<StatefulWidget> createState() => OfflineMixinState();

}

class OfflineMixinState extends State<OfflineMixin> {

  bool _isLoading;

  OfflineMixinState() {
    _isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      body: Container(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.offline_bolt, size: 48, color: Colors.grey),
              Container(padding: EdgeInsets.symmetric(vertical: 10)),
              TitleText(S.of(context).youre_offline, fontSize: 24),
              Container(padding: EdgeInsets.symmetric(vertical: 3)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 50),
                child: Text(
                  S.of(context).appname_failed_to_connect_to_the_internet(appName),
                  softWrap: true,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 16
                  ),
                ),
              ),

              widget.reloadAction != null ? Container(
                padding: EdgeInsets.only(top: 10),
                child: !_isLoading ? FlatButton(
                  child: Text(S.of(context).reload.toUpperCase()),
                  textColor: Theme.of(context).primaryColor,
                  onPressed: () async {
                    _isLoading = true;
                    setState((){});
                    await Future.delayed(Duration(seconds: 3));
                    await widget.reloadAction();
                    setState((){});
                    _isLoading = false;
                  },
                ) : Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: ApolloLoadingSpinner(),
                ),
              ) : Container()
            ],
          ),
        ),
      ),
    );
  }

}

class ErrorLoadingMixin extends StatefulWidget {

  final String errorTitle;
  final String errorMessage;
  final Function action;
  final String actionLabel;
  final bool partialForm;

  ErrorLoadingMixin({
    this.errorTitle,
    this.errorMessage,
    this.action,
    this.actionLabel,
    this.partialForm = false
  });

  @override
  State<StatefulWidget> createState() => ErrorLoadingMixinState();

}

class ErrorLoadingMixinState extends State<ErrorLoadingMixin> {

  bool _isLoading;

  ErrorLoadingMixinState(){
    _isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    String errorMessage = widget.errorMessage;
    if(errorMessage == null) errorMessage = S.of(context).an_error_occurred_whilst_loading_this_page;

    if(widget.partialForm) return _buildBody(errorMessage);
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      body: _buildBody(errorMessage),
    );
  }

  Widget _buildBody(String errorMessage){
    return Container(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.error, size: 48, color: Colors.grey),
            Container(padding: EdgeInsets.symmetric(vertical: 10)),
            TitleText(widget.errorTitle != null
                && widget.errorTitle.isNotEmpty ? widget.errorTitle : S.of(context).an_error_occurred, fontSize: 24),
            Container(padding: EdgeInsets.symmetric(vertical: 3)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 50),
              child: Text(
                errorMessage,
                softWrap: true,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16
                ),
              ),
            ),

            widget.action != null ? Container(
              padding: EdgeInsets.only(top: 10),
              child: !_isLoading ? FlatButton(
                child: Text(widget.actionLabel != null
                    && widget.actionLabel.isNotEmpty ? widget.actionLabel.toUpperCase() : S.of(context).reload.toUpperCase()),
                textColor: Theme.of(context).primaryColor,
                onPressed: () async {
                  _isLoading = true;
                  setState((){});
                  await Future.delayed(Duration(seconds: 3));
                  await widget.action();
                  setState((){});
                  _isLoading = false;
                },
              ) : Padding(
                padding: EdgeInsets.only(top: 10),
                child: ApolloLoadingSpinner(),
              ),
            ) : Container()
          ],
        ),
      ),
    );
  }

}

class CastButton extends StatefulWidget {

  @override
  State<StatefulWidget> createState() => CastButtonState();

}

class CastButtonState extends State<CastButton> {

  @override
  Widget build(BuildContext context) {
    KaminoAppState application = context.ancestorStateOfType(const TypeMatcher<KaminoAppState>());
    bool hasActiveCast = application.activeCastSender != null;

    return IconButton(
      icon: hasActiveCast ? Icon(Icons.cast_connected) : Icon(Icons.cast),
      tooltip: hasActiveCast ? S.of(context).disconnect: S.of(context).google_cast_prompt,
      onPressed: () async {
        if(hasActiveCast){
          Interface.showSnackbar(S.of(context).disconnected_from_device(application.activeCastSender.device.friendlyName), context: context, backgroundColor: Colors.red);
          application.activeCastSender.stop();
          await application.activeCastSender.disconnect();
          setState(() {
            application.activeCastSender = null;
          });
          return;
        }

        CastDevice device = await CastDevicesDialog.show(context);
        if(device != null){
          CastSender sender = CastSender(device);
          await sender.connect();
          sender.launch(appCastID);
          setState(() {
            application.activeCastSender = sender;
            Interface.showSnackbar(S.of(context).now_connected_to_device(device.friendlyName), context: context);
          });
        }
      },
    );
  }

}

class SearchFieldWidget extends StatefulWidget {

  final Widget leading;
  final bool disableClearButton;
  final Function(BuildContext, String) child;
  final Color color;

  final Function(String) onUpdate;
  final Function(String) onSubmit;
  final Function onClear;

  final TextEditingController controller;
  final bool autofocus;

  SearchFieldWidget({
    this.leading,
    this.disableClearButton = false,
    this.child,
    this.color,

    this.onUpdate,
    this.onSubmit,
    this.onClear,

    this.controller,
    this.autofocus = true,
  });

  @override
  State<StatefulWidget> createState() => SearchFieldWidgetState();

}

class SearchFieldWidgetState extends State<SearchFieldWidget> with SingleTickerProviderStateMixin {

  TextEditingController inputController;
  FocusNode inputFocusNode;
  bool clearButtonVisible = false;

  List<Function> registeredListeners = new List();

  @override
  void initState() {
    inputFocusNode = new FocusNode();

    if(widget.controller != null)
      this.inputController = widget.controller;
    else inputController = new TextEditingController();

    if(!widget.disableClearButton){
      var disableClearButtonListener = (){
        setState(() {
          clearButtonVisible = inputController.text.length > 0;
        });
      };
      registeredListeners.add(disableClearButtonListener);
      inputController.addListener(disableClearButtonListener);
    }

    super.initState();
  }

  @override
  void dispose() {
    for(var listener in registeredListeners){
      inputController.removeListener(listener);
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = widget.child != null && inputFocusNode.hasPrimaryFocus
        ? widget.child(context, inputController.text) ?? null
        : null;

    return Container(
        margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15).copyWith(top: 20),
        child: Material(
          elevation: 4,
          clipBehavior: Clip.antiAlias,
          color: widget.color != null ? widget.color : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedSize(
            vsync: this,
            duration: Duration(milliseconds: 100),
            alignment: Alignment.topCenter,
            child: Column(children: <Widget>[
              Stack(
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.only(bottom: child != null ? 10 : 0),
                    child: TextField(
                      autofocus: widget.autofocus,
                      onChanged: widget.onUpdate,
                      onSubmitted: widget.onSubmit,
                      focusNode: inputFocusNode,
                      controller: inputController,
                      decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15)
                              .copyWith(
                              left: widget.leading != null ? 50 : null,
                              top: 16,
                              right: clearButtonVisible ? 45 : null
                          ),
                          border: InputBorder.none,
                          fillColor: Theme.of(context).cardColor,
                          hintText: S.of(context).search_people_movies_and_shows,
                          hintStyle: TextStyle(
                              fontSize: 16,
                              height: 1
                          )
                      ),
                      style: TextStyle(
                          fontSize: 16
                      ),
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      widget.leading ?? Container(),

                      IgnorePointer(
                        ignoring: !clearButtonVisible,
                        child: AnimatedOpacity(
                          opacity: clearButtonVisible ? 1 : 0,
                          duration: Duration(milliseconds: 100),
                          child: IconButton(
                            tooltip: S.of(context).clear,
                            highlightColor: Colors.transparent,
                            splashColor: Colors.transparent,
                            icon: Icon(Icons.clear),
                            onPressed: (){
                              inputController.text = "";
                              if(widget.onClear != null) widget.onClear();
                            },
                          ),
                        ),
                      )
                    ],
                  ),

                  if(child != null) Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Divider(),
                  ),
                ],
              ),

              if(child != null)
                child ?? Container()
            ]),
          ),
        )
    );
  }

}

class ResponsiveContentGrid extends StatefulWidget {

  final List<ContentModel> content;
  final double idealItemWidth;
  final double spacing;
  final double margin;

  final bool withLazyLoad;
  /// A future that will load the next page, or null if there is no
  /// next page.
  final Function loadNextPage;

  ResponsiveContentGrid({
    @required this.content,

    this.idealItemWidth = 150,
    this.spacing = 10.0,
    this.margin = 10.0,

    this.withLazyLoad = false,
    this.loadNextPage
  });

  @override
  State<StatefulWidget> createState() => ResponsiveContentGridState();

}

class ResponsiveContentGridState extends State<ResponsiveContentGrid> {

  List<ContentModel> lazyLoadedContent;

  bool loading = false;
  bool rendered = false;
  int totalRows;
  double posterWidth;
  double posterHeight;

  @override
  void initState() {
    lazyLoadedContent = widget.content;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if(!widget.withLazyLoad) return buildGrid(context, widget.content);
    if(widget.loadNextPage == null) throw new FlutterError("A loadNextPage function must be provided to ResponsiveContentGrid if withLazyLoad is true.");

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification){
        if(loading) return false;
        if(totalRows == null) return false;

        ScrollMetrics metrics = notification.metrics;
        // Weird hacky way of triggering the next page load because the
        // NestedScrollView just makes all of the extents go weird.
        if(metrics.extentAfter <= posterHeight + (widget.spacing * 4)){

          Function loadNextPage = widget.loadNextPage();
          if(loadNextPage != null){
            if(mounted) setState(() {
              loading = true;
            });

            loadNextPage().then((List<ContentModel> content){
              if(mounted) setState(() {
                lazyLoadedContent = content;
                loading = false;
              });
            });
          }

        }
        return false;
      },
      child: ListView(
        children: <Widget>[
          buildGrid(context, lazyLoadedContent),
          Container(height: 20),
          new Container(
            height: loading ? 64 : 0,
            margin: loading ? EdgeInsets.symmetric(vertical: 20).copyWith(bottom: 40) : EdgeInsets.zero,
            child: Center(
              child: ApolloLoadingSpinner()
            ),
          )
        ],
      ),
    );
  }

  Widget buildGrid(BuildContext context, List<ContentModel> content) {
    return FutureBuilder<bool>(future: new Future(() async {
      return await Settings.detailedContentInfoEnabled;
    }), builder: (BuildContext context, AsyncSnapshot<bool> snapshot){
      if(!snapshot.hasData) return Container(
        margin: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: ApolloLoadingSpinner(),
        ),
      );

      bool cardView = snapshot.data;

      return Container(
        margin: EdgeInsets.symmetric(horizontal: widget.margin),
        child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints){
          int postersPerRow = cardView ? 1 : (constraints.maxWidth / widget.idealItemWidth).ceil();
          totalRows = (content.length / postersPerRow).ceil();

          posterWidth = (constraints.maxWidth / postersPerRow) - (widget.spacing * 2);
          posterHeight = (3 / 2) * posterWidth;
          rendered = true;

          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(
              totalRows,
              (int row) => Container(
                margin: EdgeInsets.symmetric(vertical: widget.spacing),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(
                        postersPerRow,
                        (int col) => Builder(builder: (BuildContext context){

                          bool isFirst = col == 0;
                          bool isLast = (col + 1) == postersPerRow;

                          int index = (row * postersPerRow) + col;
                          ContentModel item = index < content.length
                              ? content[index]
                              : null;

                          if(item == null) return Container(
                            width: posterWidth,
                            margin: EdgeInsets.only(
                                left: isFirst ? 0 : widget.spacing,
                                right: isLast ? 0 : widget.spacing
                            )
                          );

                          if(cardView) return Expanded(
                              child: ContentCard(
                                  content: item,
                                  onTap: () => Interface.openOverview(context, item.id, item.contentType),
                                  elevation: 4,
                                  isFavorite: false
                              )
                          );

                          return Container(
                              margin: EdgeInsets.only(
                                  left: isFirst ? 0 : widget.spacing,
                                  right: isLast ? 0 : widget.spacing
                              ),
                              child: ContentPoster(
                                height: posterHeight,
                                content: item,
                                onTap: () => Interface.openOverview(context, item.id, item.contentType),
                              ),
                          );
                        })
                    )
                ),
              )
            )
          );
        }),
      );
    });
  }

}

class ScrollableRow extends StatelessWidget {

  final List<Widget> children;

  ScrollableRow({
    @required this.children
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        NotificationListener<OverscrollIndicatorNotification>(
          onNotification: (OverscrollIndicatorNotification notification){
            notification.disallowGlow();
            return true;
          },
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            )
          ),
        )
      ]
    );
  }

}