import 'package:flutter/material.dart';
import 'package:kamino/api/realdebrid.dart';
import 'package:kamino/generated/i18n.dart';
import 'package:kamino/main.dart';
import 'package:kamino/ui/elements.dart';
import "package:kamino/models/source.dart";
import 'package:kamino/util/filesize.dart';
import 'package:kamino/util/player.dart';
import 'package:kamino/util/settings.dart';
import 'package:kamino/vendor/struct/VendorService.dart';

class SourceSelectionView extends StatefulWidget {

  static const double _kAppBarProgressHeight = 4.0;

  final String title;
  final VendorService service;

  @override
  State<StatefulWidget> createState() => SourceSelectionViewState();

  SourceSelectionView({
    @required this.title,
    @required this.service
  });

}

class SourceSelectionViewState extends State<SourceSelectionView> {

  List<SourceModel> sourceList = new List();
  bool rdEnabled = false;

  String sortingMethod = 'quality';
  bool sortReversed = true;

  bool rdExpanded = true;
  bool generalExpanded = true;

  bool isShimVendor = false;
  bool _disableSecurityMessages = false;

  @override
  void initState() {
    (() async {
      rdEnabled = await RealDebrid.isAuthenticated();

      List sortingSettings = await Settings.contentSortSettings;

      KaminoAppState application = context.ancestorStateOfType(const TypeMatcher<KaminoAppState>());
      isShimVendor = await application.isShimVendorEnabled();
      _disableSecurityMessages = await Settings.disableSecurityMessages;

      if(sortingSettings.length == 2) {
        sortingMethod = sortingSettings[0];
        sortReversed = sortingSettings[1].toLowerCase() == 'true';
      }
      setState(() {});
    })();

    widget.service.addUpdateEvent(() {
      if (mounted) setState(() {});
    });

    super.initState();
  }

  Future<bool> _handlePop() async {
    await widget.service.setStatus(context, VendorServiceStatus.IDLE);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    widget.service.sourceList.forEach((model) {
      // If sourceList does not contain a SourceModel with model's URL
      if (sourceList
          .where((_searchModel) => _searchModel.file.data == model.file.data)
          .length == 0) {
        sourceList.add(model);
      }
    });

    List<SourceModel> _rdSources = rdEnabled ? sourceList.where((SourceModel model) => model.metadata.isRD)
        .toList() : null;
    List<SourceModel> _sources = rdEnabled ? sourceList.where((SourceModel model) => !model.metadata.isRD)
        .toList() : sourceList;

    return WillPopScope(
      onWillPop: _handlePop,
      child: Scaffold(
          backgroundColor: Theme
              .of(context)
              .backgroundColor,
          appBar: AppBar(
            backgroundColor: !isShimVendor || _disableSecurityMessages ? Theme.of(context).backgroundColor
              : Colors.red,
            title: TitleText(
                "${widget.title} \u2022 " + S.of(context).n_sources(sourceList.length.toString())
            ),
            centerTitle: true,
            bottom: PreferredSize(
                child: (
                    widget.service.status != VendorServiceStatus.DONE &&
                    widget.service.status != VendorServiceStatus.IDLE
                )
                    ? SizedBox(
                  height: SourceSelectionView._kAppBarProgressHeight,
                  child: LinearProgressIndicator(
                    backgroundColor: !isShimVendor || _disableSecurityMessages ? null : Colors.red,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        !isShimVendor || _disableSecurityMessages ? Theme.of(context).primaryColor
                            : Colors.white
                    ),
                  ),
                )
                    : Container(),
                preferredSize: Size(
                    double.infinity, SourceSelectionView._kAppBarProgressHeight)
            ),
            actions: <Widget>[
              IconButton(icon: Icon(Icons.sort), onPressed: () => _showSortingDialog(context))
            ],
          ),
          body: Container(
              child: NotificationListener<OverscrollIndicatorNotification>(
                  onNotification: (notification){
                    if(notification.leading){
                      notification.disallowGlow();
                    }
                  },
                  child: ListView(
                    primary: true,
                    children: <Widget>[
                      isShimVendor && !_disableSecurityMessages ? Container(
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                        color: Colors.red,
                        child: Text("SECURITY RISK: You are using an unoffical server. Use of unofficial servers is at your own risk. They have not been vetted or inspected by the ApolloTV team and are not guaranteed to be running official code. By connecting to a server on the internet, you are sharing your IP address. If this is a concern, use a VPN or do not use unofficial servers."),
                      ) : Container(),

                      rdEnabled ? _buildSourceList(
                          _rdSources,
                          title: S.of(context).real_debrid_n_sources(_rdSources.length.toString()),
                          sectionExpanded: rdExpanded,
                          onToggleExpanded: () => setState((){
                            rdExpanded = !rdExpanded;
                          })
                      ) : Container(),
                      _buildSourceList(
                          _sources,
                          title: rdEnabled
                              ? S.of(context).standard_n_sources(_sources.length.toString())
                              : null,
                          sectionExpanded: generalExpanded,
                          onToggleExpanded: () => setState((){
                            generalExpanded = !generalExpanded;
                          })
                      ),

                      Container(margin: EdgeInsets.only(bottom: 15))
                    ],
                  )
              )
          )
      ),
    );
  }

  _buildSourceList(List<SourceModel> sourceList, { String title, bool sectionExpanded = true, Function onToggleExpanded }){
    sourceList = _sortList(sourceList);

    return ListView.builder(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: title != null
            ? (sectionExpanded ? sourceList.length + 1 : 2)
            : sourceList.length,
        itemBuilder: (BuildContext ctx, int index) {

          /* HEADER ROW */
          if(title != null){
            if(index == 0){
              return GestureDetector(
                onTap: onToggleExpanded != null ? onToggleExpanded : null,
                child: Container(
                    padding: EdgeInsets.only(left: 10, right: 15, top: 20, bottom: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        SubtitleText(title),
                        Icon(sectionExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down)
                      ],
                    )
                ),
              );
            }

            if(!sectionExpanded) return Container();

            index -= 1;
          }
          /* END: HEADER ROW */


          var source = sourceList[index];

          String qualityInfo; // until we sort out quality detection
          if (source.metadata.quality != null
              && source.metadata.quality.replaceAll(" ", "").isNotEmpty) {
            qualityInfo = source.metadata.quality;
          }

          /*
                if(source["metadata"]["extended"] != null){
                  var extendedMeta = source["metadata"]["extended"]["streams"][0];
                  var resolution = extendedMeta["coded_height"];

                  if(resolution < 360) qualityInfo = "[LQ]";
                  if(resolution >= 360) qualityInfo = "[SD]";
                  if(resolution > 720) qualityInfo = "[HD]";
                  if(resolution > 1080) qualityInfo = "[FHD]";
                  if(resolution > 2160) qualityInfo = "[4K]";

                  qualityInfo += " [" + extendedMeta["codec_name"].toUpperCase() + "]";
                }
              */

          return Container(
              padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              child: Material(
                clipBehavior: Clip.antiAlias,
                borderRadius: BorderRadius.circular(5),
                color: Theme.of(context).cardColor,
                elevation: 2,
                child: IntrinsicHeight(
                    child: Row(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[

                          Container(
                              width: 80,
                              color: source.metadata.isRD ? Theme.of(context).primaryColor : Color.fromRGBO(
                                  Theme.of(context).cardColor.red + 10,
                                  Theme.of(context).cardColor.green + 10,
                                  Theme.of(context).cardColor.blue + 10,
                                  Theme.of(context).cardColor == const Color(0xFF000000) ? 0.0 : 1.0
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: <Widget>[
                                  Container(
                                      padding: EdgeInsets.symmetric(vertical: 5),
                                      width: 60,
                                      decoration: BoxDecoration(
                                          border: Border.all(color: Colors.white, width: 1.5),
                                          borderRadius: BorderRadius.circular(5)
                                      ),
                                      child: TitleText(
                                        (qualityInfo != null ? qualityInfo : "-"),
                                        textAlign: TextAlign.center,
                                      )
                                  ),

                                  Container(
                                      child: TitleText(
                                          (
                                              source.metadata.contentLength != null
                                                  ? formatFilesize(source.metadata.contentLength, round: 0, decimal: true)
                                                  : ""
                                          )
                                      )
                                  )
                                ],
                              )
                          ),

                          Expanded(
                              child: ListTile(
                                enabled: true,
                                isThreeLine: true,

                                title: TitleText(
                                    "${source.metadata.provider} (${source.metadata
                                        .source})"),
                                subtitle: Text(
                                  source.file.data,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                onTap: () async {
                                  PlayerHelper.play(
                                      context,
                                      title: widget.title,
                                      url: source.file.data,
                                      mimeType: 'video/*'
                                  );
                                },
                                onLongPress: () {
                                  /*Clipboard.setData(
                                      new ClipboardData(text: source.file.data));
                                  Interface.showSnackbar(S
                                      .of(context)
                                      .url_copied, context: ctx);*/
                                  PlayerHelper.choosePlayer(
                                    context,
                                    title: widget.title,
                                    url: source.file.data,
                                    mimeType: 'video/*'
                                  );
                                },
                              )
                          )

                        ]
                    )
                ),
              )
          );
        }
      );
  }

  List<SourceModel> _sortList(List<SourceModel> sourceList) {
    /* By default, sorting is descending. (Ideally best to worst.)
     * Reversed, is descending. */

    sourceList.sort((SourceModel left, SourceModel right) {
      switch(sortingMethod){
        case 'name':
          return left.metadata.provider.compareTo(right.metadata.provider);
        case 'fileSize':
          return left.metadata.contentLength.compareTo(right.metadata.contentLength);
        // Default: sort by quality
        default:
          return _getSourceQualityIndex(left.metadata.quality).compareTo(_getSourceQualityIndex(right.metadata.quality));
      }
    });

    if(this.sortReversed) sourceList = sourceList.reversed.toList();
    if(mounted) setState(() {});

    return sourceList;
  }

  _showSortingDialog(BuildContext context) async {
    var sortingSettings = (await showDialog(context: context, builder: (BuildContext context){
      return SourceSortingDialog(sortingMethod: sortingMethod, sortReversed: sortReversed);
    }));

    if(sortingSettings != null) {
      this.sortingMethod = sortingSettings[0];
      this.sortReversed = sortingSettings[1];

      setState(() {});
      //_sortList();
    }
  }

  int _getSourceQualityIndex(String quality){
    switch(quality){
      case 'CAM': return 0;
      case 'SCR': return 10;
      case 'HQ': return 20;
      case '360p': return 30;
      case '480p': return 40;
      case '720p': return 50;
      case '1080p': return 60;
      case '4K': return 70;
      default: return -1;
    }
  }

}

class SourceSortingDialog extends StatefulWidget {

  final String sortingMethod;
  final bool sortReversed;

  SourceSortingDialog({
    @required this.sortingMethod,
    @required this.sortReversed
  });

  @override
  State<StatefulWidget> createState() => SourceSortingDialogState();

}

class SourceSortingDialogState extends State<SourceSortingDialog> {

  String sortingMethod;
  bool sortReversed;

  @override
  void initState() {
    sortingMethod = widget.sortingMethod;
    sortReversed = widget.sortReversed;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 10).copyWith(top: 20),
      title: TitleText(S.of(context).sort_by),
      children: <Widget>[

        Column(
            children: [Column(
              children: <Widget>[
                RadioListTile(
                  secondary: (MediaQuery.of(context).size.width >= 300) ? Icon(Icons.high_quality) : null,
                  title: Text(S.of(context).quality),
                  subtitle: Text(S.of(context).sorts_by_source_quality),
                  value: 'quality',
                  groupValue: sortingMethod,
                  onChanged: (value){
                    setState(() {
                      sortingMethod = value;
                    });
                  },
                  activeColor: Theme.of(context).primaryColor,
                  controlAffinity: ListTileControlAffinity.trailing,
                ),

                RadioListTile(
                  secondary: (MediaQuery.of(context).size.width >= 300) ? Icon(Icons.sort_by_alpha) : null,
                  title: Text(S.of(context).name),
                  subtitle: Text(S.of(context).sorts_alphabetically_by_name),
                  value: 'name',
                  groupValue: sortingMethod,
                  onChanged: (value){
                    setState(() {
                      sortingMethod = value;
                    });
                  },
                  activeColor: Theme.of(context).primaryColor,
                  controlAffinity: ListTileControlAffinity.trailing,
                ),

                RadioListTile(
                  isThreeLine: true,
                  secondary: (MediaQuery.of(context).size.width >= 300) ? Icon(Icons.import_export) : null,
                  title: Text(S.of(context).file_size),
                  subtitle: Text(S.of(context).sorts_by_the_size_of_the_file),
                  value: 'fileSize',
                  groupValue: sortingMethod,
                  onChanged: (value){
                    setState(() {
                      sortingMethod = value;
                    });
                  },
                  activeColor: Theme.of(context).primaryColor,
                  controlAffinity: ListTileControlAffinity.trailing,
                ),
              ],
            )
            ]),

        Builder(builder: (BuildContext context){
          var _orderButtons = <Widget>[
            FlatButton.icon(
                color: !sortReversed ? Theme.of(context).primaryColor : null,
                onPressed: () async {
                  sortReversed = false;
                  setState(() {});
                },
                icon: Icon(Icons.keyboard_arrow_up),
                label: TitleText(S.of(context).ascending)
            ),
            FlatButton.icon(
                color: sortReversed ? Theme.of(context).primaryColor : null,
                onPressed: () async {
                  sortReversed = true;
                  setState(() {});
                },
                icon: Icon(Icons.keyboard_arrow_down),
                label: TitleText(S.of(context).descending)
            )
          ];

          if(MediaQuery.of(context).size.width < 300){
            return Container(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: ListView(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  children: _orderButtons
              ),
            );
          }else{
            return Container(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _orderButtons
              ),
            );
          }
        }),

        Container(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              new FlatButton(
                padding: EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onPressed: (){
                  Navigator.of(context).pop();
                },
                child: Text(S.of(context).cancel),
                textColor: Theme.of(context).primaryColor,
              ),

              new FlatButton(
                padding: EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onPressed: (){
                  (() async {
                    List sortingSettings = [sortingMethod, sortReversed.toString()];
                    await (Settings.contentSortSettings = sortingSettings);
                    setState(() {});
                  })();
                  Navigator.of(context).pop([sortingMethod, sortReversed]);
                },
                child: Text(S.of(context).done),
                textColor: Theme.of(context).primaryColor,
              )
            ],
          ),
        )
      ],
    );
  }

}