package xyz.apollotv.kamino;

import android.app.UiModeManager;
import android.content.ComponentName;
import android.content.Intent;
import android.content.pm.LabeledIntent;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.content.res.Configuration;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.drawable.AdaptiveIconDrawable;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.util.Base64;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.ByteArrayOutputStream;
import java.io.DataInputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.List;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;
import xyz.apollotv.kamino.share.ClipboardShareActivity;

public class MainActivity extends FlutterActivity {

  @Override
  protected void onCreate(Bundle savedInstanceState) {

    super.onCreate(savedInstanceState);
    GeneratedPluginRegistrant.registerWith(this);

    new MethodChannel(getFlutterView(), "xyz.apollotv.kamino/init").setMethodCallHandler((methodCall, result) -> {

        if(methodCall.method.equals("getDeviceType")){

            UiModeManager uiModeManager = (UiModeManager) getSystemService(UI_MODE_SERVICE);

            if(uiModeManager.getCurrentModeType() == Configuration.UI_MODE_TYPE_TELEVISION){
                // Mode 1: TV
                result.success(1);
                return;
            }

            // Mode 0: GENERAL
            result.success(0);

            return;

        }

        result.notImplemented();

    });

    new MethodChannel(getFlutterView(), "xyz.apollotv.kamino/ota").setMethodCallHandler((methodCall, result) -> {

        if(methodCall.method.equals("install")){
            if(installOTA(methodCall.argument("path"))){
                result.success(true);
            }else{
                result.error("ERROR", "An error occurred whilst installing OTA updates.", null);
            }
            return;
        }

        result.notImplemented();
    });

    new MethodChannel(getFlutterView(), "xyz.apollotv.kamino/playThirdParty").setMethodCallHandler((methodCall, result) -> {

        if(methodCall.method.equals("play")){
            try {

                String activityPackage = methodCall.argument("activityPackage");
                String activityName = methodCall.argument("activityName");
                String videoTitle = methodCall.argument("videoTitle");
                String videoURL = methodCall.argument("videoURL");
                String mimeType = methodCall.argument("mimeType");

                Intent playIntent = new Intent(Intent.ACTION_VIEW);
                playIntent.setDataAndTypeAndNormalize(Uri.parse(videoURL), mimeType);
                playIntent.putExtra("title", videoTitle);
                playIntent.setClassName(activityPackage, activityName);

                List<ResolveInfo> activities = getPackageManager().queryIntentActivities(
                    playIntent, 0
                );
                boolean isIntentSafe = activities.size() > 0;

                if(isIntentSafe){
                    startActivity(playIntent);
                    result.success(null);
                    return;
                }

                result.error(getPackageName(), "Error whilst playing. Intent wasn't safe to use.", "unsafeIntent");

            }catch(Exception ex){
                ex.printStackTrace();
                result.error(getPackageName(), "Error whilst playing. Details have been logged.", "generic");
            }
            return;
        }

        if(methodCall.method.equals("selectAndPlay")) {
            try {
                String copyToClipboardLabel = methodCall.argument("copyToClipboardLabel");
                String chooserLabel = methodCall.argument("chooserLabel");
                String videoTitle = methodCall.argument("videoTitle");
                String videoURL = methodCall.argument("videoURL");
                String mimeType = methodCall.argument("mimeType");

                List<LabeledIntent> labelledIntents = new ArrayList<>();
                PackageManager packageManager = getPackageManager();

                Intent playIntent = new Intent(Intent.ACTION_VIEW);
                playIntent.setDataAndTypeAndNormalize(Uri.parse(videoURL), mimeType);
                playIntent.putExtra("title", videoTitle);
                playIntent.putExtra("url", videoURL);

                List<ResolveInfo> activities = packageManager.queryIntentActivities(
                        playIntent, 0
                );

                /*boolean isIntentSafe = activities.size() > 0;
                if(!isIntentSafe) {
                    result.error(getPackageName(), "Error whilst playing. Intent wasn't safe to use.", "unsafeIntent");
                    return;
                }*/

                // Add the 'copy to clipboard' action
                Intent copyToClipboard = new Intent(this, ClipboardShareActivity.class);
                copyToClipboard.putExtra("url", videoURL);
                LabeledIntent copyToClipboardIntent = new LabeledIntent(copyToClipboard, getPackageName(), copyToClipboardLabel, 0);
                labelledIntents.add(copyToClipboardIntent);

                // Add the resolved activities.
                for(ResolveInfo activity : activities){
                    Intent activityIntent = (Intent) playIntent.clone();
                    activityIntent.setComponent(new ComponentName(
                            activity.activityInfo.packageName,
                            activity.activityInfo.name
                    ));

                    labelledIntents.add(new LabeledIntent(
                        activityIntent,
                        activity.activityInfo.packageName,
                        activity.loadLabel(packageManager),
                        activity.icon
                    ));
                }

                Intent chooserIntent = Intent.createChooser(playIntent, chooserLabel);
                LabeledIntent[] chooserOptions = labelledIntents.toArray( new LabeledIntent[labelledIntents.size()] );
                chooserIntent.putExtra(Intent.EXTRA_INITIAL_INTENTS, chooserOptions);
                startActivity(chooserIntent);

                result.success(null);
                return;

            }catch(Exception ex){
                ex.printStackTrace();
                result.error(getPackageName(), "Error whilst playing. Details have been logged.", "generic");
            }
            return;
        }

        if(methodCall.method.equals("list")){
            JSONArray response = new JSONArray();

            // Create a video view intent.
            Intent playIntent = new Intent(Intent.ACTION_VIEW);
            // Parse an example URL.
            playIntent.setDataAndTypeAndNormalize(Uri.parse("https://apollotv.xyz/v.mp4"), "video/*");

            // Get a list of activities that support the intent.
            List<ResolveInfo> activities = getPackageManager().queryIntentActivities(playIntent, 0);

            for(ResolveInfo activity : activities){
                try {
                    // Store activity info in a JSON object.
                    JSONObject infoObject = new JSONObject();
                    infoObject.put("activity", activity.activityInfo.name);
                    infoObject.put("package", activity.activityInfo.packageName);
                    infoObject.put("name", activity.activityInfo.applicationInfo.loadLabel(getPackageManager()));
                    infoObject.put("version", getPackageManager().getPackageInfo(
                        activity.activityInfo.applicationInfo.packageName,
                        0
                    ).versionName);
                    infoObject.put("description", activity.activityInfo.loadLabel(getPackageManager()));
                    infoObject.put("isDefault", activity.isDefault);

                    // Convert app icon to bitmap
                    Drawable iconDrawable = activity.loadIcon(getPackageManager());
                    Bitmap icon = Bitmap.createBitmap(iconDrawable.getIntrinsicWidth(), iconDrawable.getIntrinsicHeight(), Bitmap.Config.ARGB_8888);
                    Canvas canvas = new Canvas(icon);
                    iconDrawable.setBounds(0, 0, canvas.getWidth(), canvas.getHeight());
                    iconDrawable.draw(canvas);

                    // Encode the icon for transmission.
                    ByteArrayOutputStream iconOut = new ByteArrayOutputStream();
                    icon.compress(Bitmap.CompressFormat.PNG, 100, iconOut);
                    iconOut.close();
                    infoObject.put("icon", Base64.encodeToString(
                        iconOut.toByteArray(),
                        Base64.DEFAULT
                    ));

                    response.put(infoObject);
                }catch(Exception ex){
                    ex.printStackTrace();
                }
            }

            // Return the JSON array of data.
            result.success(response.toString());
            return;
        }

    });

  }

  private boolean installOTA(String path){
      try {
          Uri fileUri = Uri.parse("file://" + path);

          Intent intent;
          if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
              //AUTHORITY NEEDS TO BE THE SAME ALSO IN MANIFEST
              Uri apkUri = OTAFileProvider.getUriForFile(getApplicationContext(), "xyz.apollotv.kamino.provider", new File(path));
              intent = new Intent(Intent.ACTION_INSTALL_PACKAGE);
              intent.setData(apkUri);
              intent.setFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION|Intent.FLAG_ACTIVITY_NEW_TASK);
          } else {
              intent = new Intent(Intent.ACTION_VIEW);
              intent.setDataAndType(fileUri, "application/vnd.android.package-archive");
              intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
          }

          getApplicationContext().startActivity(intent);
          return true;
      }catch(Exception ex){
          System.out.println("[Platform] Error during ApolloTV OTA installation.");
          System.out.println(ex.getMessage());
          return false;
      }
  }


}