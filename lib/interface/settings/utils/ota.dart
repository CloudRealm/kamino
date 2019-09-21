import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:kamino/generated/i18n.dart';
import 'package:kamino/ui/elements.dart';
import 'package:kamino/ui/interface.dart';
import 'package:kamino/ui/loading.dart';
import 'package:kamino/util/settings.dart';
import 'package:package_info/package_info.dart';
import 'package:path_provider/path_provider.dart';

class OTAHelper {
  static const platform = {
    "ota": const MethodChannel('xyz.apollotv.kamino/ota'),
    "permission": const MethodChannel('xyz.apollotv.kamino/permission')
  };

  static Future<void> installOTA(String path) async {
    try {
      await platform['ota'].invokeMethod('install', <String, dynamic>{
        "path": path
      });
    } on PlatformException catch (e) {
      print("ERROR INSTALLING UPDATE: $e");
    }
  }
}

Future<Map> checkUpdate(BuildContext context, bool dismissSnackbar) async {
  // Get the package info
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  String buildNumber = packageInfo.buildNumber;

  // Get the build info
  try {
    var buildData = await json.decode(await DefaultAssetBundle.of(context).loadString("assets/state/dev.json"));
    bool isDevBuild = buildData['isDevelopmentBuild'];

    if(isDevBuild != null && isDevBuild){
      int devCode = buildData['devCode'];
      buildNumber += "." + devCode.toString();
    }
  // Catching an inevitable missing file in the event someone does not read
  // the instructions in the file.
  }catch(ex){}


  // Take the current version track in settings.
  String versionTrack = ['stable', 'beta', 'development'][(await Settings.releaseVersionTrack)];

  // Get latest build info from Apollo Houston for the user's track.
  http.Response res = await http.get("https://houston.apollotv.xyz/ota/$versionTrack");

  if (res.statusCode == 200) {
    var results = json.decode(res.body);
    if(results['latest'] == null) return {};

    if (double.parse(results["latest"]["buildNumber"]) > double.parse(buildNumber)) {
      //new version is available
      return {
        "title": results["latest"]["title"],
        "build": results["latest"]["buildNumber"],
        "url": "https://houston.apollotv.xyz/ota/download/${results["latest"]["_id"]}",
        "changelog": results["latest"]["changelog"]
      };
    }
  }

  return {};
}

///
/// Consider [dismissSnackbar] to be ignoreSnackbar.
///
updateApp(BuildContext context, bool dismissSnackbar) async {
  if(!Platform.isAndroid) return;

  // TODO: Show network connection error message.
  Map data;
  try {
    data = await checkUpdate(context, dismissSnackbar);
  }catch(_){ return; }

  //show update dialog
  if (data["url"] != null) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return AlertDialog(
            title: TitleText(data["title"]),
            content: Text(
              data["changelog"],
              style: TextStyle(
                  color: Theme.of(context).primaryTextTheme.body1.color
              ),
            ),
            actions: <Widget>[
              Center(
                child: FlatButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: TitleText(S.of(context).dismiss, textColor: Theme.of(context).primaryTextTheme.body1.color)
                ),
              ),
              Center(
                child: FlatButton(
                  onPressed: () => runInstallProcedure(context, data),
                  child: TitleText(S.of(context).install, textColor: Theme.of(context).primaryTextTheme.body1.color)
                ),
              )
            ],
            //backgroundColor: Theme.of(context).cardColor,
          );
        });
  } else {
    if (dismissSnackbar == false && context != null) {
      Interface.showSnackbar(S.of(context).up_to_date, context: context);
    }
  }
}

runInstallProcedure (context, data) async {
  try {
    Navigator.of(context).pop();

    bool permissionStatus = await OTAHelper.platform['permission'].invokeMethod('checkStorage');
    bool shouldShowPermissionRationale = await OTAHelper.platform['permission'].invokeMethod('shouldShowRationaleStorage');

    if(shouldShowPermissionRationale){
      await Interface.showAlert(
          context: context,
          title: TitleText("ApolloTV needs permission to continue..."),
          content: [
            Text("In order for ApolloTV's auto-updater to download and install this update, you must grant ApolloTV access to device storage."),
          ],
          actions: [
            FlatButton(child: Text("Next"), onPressed: () => Navigator.of(context).pop())
          ]
      );
    }

    if(!permissionStatus) permissionStatus = await OTAHelper.platform['permission'].invokeMethod('requestStorage');
    if(!permissionStatus) throw new FileSystemException(S.of(context).permission_denied);

    final downloadDir = new Directory((await getExternalStorageDirectory()).path + "/.apollo");
    if(!await downloadDir.exists()) await downloadDir.create();
    final downloadFile = new File("${downloadDir.path}/update.apk");
    if(await downloadFile.exists()) await downloadFile.delete();

    http.Client client = new http.Client();
    http.StreamedResponse response = await client.send(
      http.Request("GET", Uri.parse(data["url"]))
    );

    var downloadFileSink = downloadFile.openWrite();
    showDownloadingDialog(context, S.of(context).updating, downloadFile, response.contentLength);
    await response.stream.pipe(downloadFileSink);
    await downloadFileSink.close();

    Navigator.of(context).pop();
    OTAHelper.installOTA(downloadFile.path);
  }catch(e){
    String message = S.of(context).update_failed_please_try_again_later;

    if(e is FileSystemException) message = S.of(context).update_failed_storage_permission_denied;

    if(Scaffold.of(context, nullOk: true) != null) {
      Interface.showSnackbar(message, context: context, backgroundColor: Colors.red);
      return;
    }else{
      showDialog(
          context: context,
          builder: (_){
            return AlertDialog(
              title: TitleText(S.of(context).error_updating_app),
              content: Text(message),
              actions: <Widget>[
                FlatButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: TitleText(S.of(context).dismiss, textColor: Theme.of(context).primaryTextTheme.body1.color)
                )
              ],
            );
          }
      );
    }
  }
}

class DownloadingDialog extends StatefulWidget {

  final String title;
  final File file;
  final int length;

  DownloadingDialog({
    @required this.title,
    @required this.file,
    @required this.length
  });

  @override
  State<StatefulWidget> createState() => DownloadingDialogState();

}

class DownloadingDialogState extends State<DownloadingDialog> {

  double downloadedMB;
  double totalMB;
  double progress;

  @override
  void initState() {
    super.initState();

    Future.doWhile(() async {
      int downloaded = await widget.file.length();
      if(mounted) setState(() {
        downloadedMB = (downloaded / 100000).round() / 10;
        totalMB = (widget.length / 100000).round() / 10;

        progress = downloaded / widget.length;
      });

      return downloaded != widget.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    int progressPercent = ((progress ?? 0) * 100).round();

    return AlertDialog(
      title: TitleText(widget.title),
      content: SingleChildScrollView(
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Container(
                padding: EdgeInsets.only(top: 10, bottom: 10, left: 10, right: 20),
                child: new ApolloLoadingSpinner()
            ),
            Expanded(child: Text(
              "${S.of(context).downloading_update_file}\n"
                  "$progressPercent%: $downloadedMB MB / $totalMB MB",
              softWrap: true
            ))
          ],
        ),
      ),
    );
  }

}

void showDownloadingDialog(BuildContext context, String title, File file, int length){
  showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_){
        return WillPopScope(
          onWillPop: () async => false,
          child: DownloadingDialog(
            title: title,
            file: file,
            length: length
          )
        );
      }
  );
}
