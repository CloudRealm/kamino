import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:kamino/external/ExternalService.dart';
import 'package:kamino/external/api/tmdb.dart';
import 'package:kamino/external/struct/content_tracker.dart';
import 'package:kamino/generated/i18n.dart';
import 'package:kamino/main.dart';
import 'package:kamino/models/content.dart';
import 'package:kamino/ui/elements.dart';
import 'package:kamino/ui/interface.dart';
import 'package:kamino/util/database_helper.dart';
import 'package:kamino/util/settings.dart';

class Trakt extends ContentTrackerService {

  static TraktIdentity identity;

  Trakt(TraktIdentity _identity) : super(
      "Trakt.tv"
  ){ identity = _identity; }

  /*

  TODO: Auto-renew Trakt token when it expires.
  (Not high priority -> tokens expire after 3 months.)

   */

  static const String TRAKT_API_ENDPOINT = "https://api.trakt.tv";

  static const String TRAKT_AUTH_GET_TOKEN = "$TRAKT_API_ENDPOINT/oauth/token";
  static const String TRAKT_AUTH_REVOKE_TOKEN = "$TRAKT_API_ENDPOINT/oauth/revoke";

  static const String TRAKT_SYNC_HISTORY = "$TRAKT_API_ENDPOINT/sync/history";
  static const String TRAKT_SYNC_COLLECTION = "$TRAKT_API_ENDPOINT/sync/collection";

  Future<Map<String, String>> _getAuthHeaders(BuildContext context) async {
    TraktCredentials traktCredentials = await getTraktSettings();

    return {
      HttpHeaders.authorizationHeader: 'Bearer ${traktCredentials.accessToken}',
      HttpHeaders.contentTypeHeader: 'application/json',
      'trakt-api-version': '2',
      'trakt-api-key': Trakt.identity.id
    };
  }

  ///
  /// This acts as a convenient way of getting [Settings.traktCredentials]
  /// as a [TraktCredentials] object.
  ///
  Future<TraktCredentials> getTraktSettings() async {
    return await Settings.traktCredentials;
  }

  ///
  /// Returns true if the user has signed into and/or connected Trakt to
  /// ApolloTV.
  ///
  Future<bool> isAuthenticated() async {
    return (await getTraktSettings()).isValid();
  }

  ///
  /// Allows the user to sign in and store their Trakt credentials in the
  /// application settings.
  ///
  Future<bool> authenticate(BuildContext context, { bool shouldShowSnackbar = false }) async {
    String authCode = await Navigator.push(context, MaterialPageRoute(
      fullscreenDialog: true,
      builder: (BuildContext context) => TraktAuthenticator(context: context)
    ));

    // If the authentication code is null, the user probably exited the
    // authentication manually, but let's show a dialog to be safe.
    if(authCode == null){
      Interface.showSnackbar(S.of(context).appname_was_unable_to_authenticate_with_trakttv(appName), context: context, backgroundColor: Colors.red);
      return false;
    }

    http.Response response = await http.post(TRAKT_AUTH_GET_TOKEN, body: {
      'code': authCode,
      'client_id': Trakt.identity.id,
      'client_secret': Trakt.identity.secret,
      'redirect_uri': "urn:ietf:wg:oauth:2.0:oob",
      'grant_type': "authorization_code"
    });

    if(response.statusCode == 200){

      Map responsePayload = json.decode(response.body);
      Settings.setTraktCredentials(new TraktCredentials.named(
          accessToken: responsePayload["access_token"],
          refreshToken: responsePayload["refresh_token"],

          // Trakt tokens expire in 3 months (84 days), after which
          // the token will need to be refreshed.
          expiryDate: DateTime.now().add(Duration(days: 84)).toString()
      ));
      if(shouldShowSnackbar) Interface.showSnackbar(S.of(context).connected_trakt_account, context: context, backgroundColor: Colors.green);
      
      return true;

    }

    Interface.showSnackbar(S.of(context).appname_was_unable_to_authenticate_with_trakttv(appName), context: context, backgroundColor: Colors.red);
    return false;
  }

  ///
  /// Revokes the Trakt OAUTH token and clears the trakt credentials from the
  /// application settings.
  ///
  Future<bool> deauthenticate(BuildContext context, { bool shouldShowSnackbar = false }) async {
    TraktCredentials traktCredentials = await getTraktSettings();

    http.Response response = await http.post(TRAKT_AUTH_REVOKE_TOKEN, body: {
      'token': traktCredentials.accessToken,
      'client_id': Trakt.identity.id,
      'client_secret': Trakt.identity.secret
    });

    if(response.statusCode == 200){
      await Settings.setTraktCredentials(TraktCredentials.unauthenticated());
      if(shouldShowSnackbar) Interface.showSnackbar(S.of(context).disconnected_trakt_account, context: context, backgroundColor: Colors.red);

      return true;
    }

    Interface.showSimpleErrorDialog(
      context,
      title: S.of(context).action_unsuccessful,
      reason: S.of(context).an_error_occurred_whilst_deauthenticating_with_trakttv(response.statusCode.toString())
    );
    return false;
  }

  ///
  /// Performs a full synchronization of the ApolloTV app databases with the
  /// connected Trakt.tv profile.
  /// This should ideally be done in the background, every few days and upon
  /// initial setup.
  ///
  Future<void> synchronize(BuildContext context, { bool silent = false }) async {
    /* SYNCHRONIZE FAVORITES */

    // Pre-Step 1 -> Purge favorites where authority is Trakt.
    DatabaseHelper.purgeFavoritesByAuthority(FavoriteAuthority.TRAKT);

    // Step 1 -> Fetch favorites and store in array.
    if(!silent) Interface.showLoadingDialog(context, title: S.of(context).downloading_trakt_data, canCancel: false);
    
    Stream<String> mediaTypes = Stream.fromIterable(['shows', 'movies']);
    var favorites = {
      'shows': <int>[],
      'movies': <int>[]
    };

    await for (String mediaType in mediaTypes){
      http.Response response = await http.get(
        TRAKT_SYNC_COLLECTION + "/$mediaType",
        headers: await _getAuthHeaders(context)
      );

      if(response.statusCode != 200){
        print("An error occurred whilst fetching Trakt data for $mediaType.");
        continue;
      }

      List payload = jsonDecode(response.body);
      String mediaTypeObject = mediaType.substring(0, mediaType.length - 1);

      for(var index = 0; index < payload.length; index++){
        if(payload[index][mediaTypeObject]['ids']['tmdb'] != null)
          favorites[mediaType].add(
              payload[index][mediaTypeObject]['ids']['tmdb']
          );
      }

    }
    if(!silent) Navigator.of(context).pop();

    // Step 2 -> Upload favorites to Trakt.
    if(!silent) Interface.showLoadingDialog(context, title: S.of(context).uploading_favorites, canCancel: false);

    Map data = {};

    Map<String, List<FavoriteDocument>> storedFavorites = await DatabaseHelper.getAllFavorites();
    storedFavorites.forEach((String type, List<FavoriteDocument> documents){
      String traktMediaType = (type == 'movie') ? "movies" : "shows";
      data[traktMediaType] = [];

      documents.forEach((FavoriteDocument document){
        // If Trakt was the initial provider of this favorite, ignore it.
        if(document.authority == FavoriteAuthority.TRAKT) return;
        // If Trakt already has this as a favorite, ignore it.
        if(favorites[traktMediaType].contains(document.tmdbId)) return;

        data[traktMediaType].add({
          'collected_at': document.savedOn.toString(),
          'title': document.name,
          'year': document.year,
          'ids': {
            'tmdb': document.tmdbId
          }
        });
      });
    });

    await http.post(
        TRAKT_SYNC_COLLECTION,
        headers: await _getAuthHeaders(context),
        body: json.encode(data)
    );

    if(!silent) Navigator.of(context).pop();

    // Step 3 -> Map IDs to FavoriteDocuments.
    if(!silent) Interface.showLoadingDialog(context, title: S.of(context).saving_content_information, canCancel: false);
    List<Future> favoriteSyncDelegate = new List();

    for(var entry in favorites.entries){
      String mediaType = entry.key;
      List<int> data = entry.value;

      List<FavoriteDocument> documents = [];

      await for (int id in Stream.fromIterable(data)){

        // Don't bother writing if already a favorite.
        if(!await DatabaseHelper.isFavorite(id)) {
          ContentModel model = await Service.get<TMDB>().getContentInfo(
              context,
              mediaType == 'shows' ? ContentType.TV_SHOW : ContentType.MOVIE,
              id
          );
          documents.add(new FavoriteDocument.fromModel(model, authority: FavoriteAuthority.TRAKT));
        }

      }

      DatabaseHelper.saveFavorites(documents);
    }

    Future.wait(favoriteSyncDelegate);
    if(!silent) Navigator.of(context).pop();

    /* END: SYNCHRONIZE FAVORITES */
  }

  ///
  /// This adds an item to a user's Trakt favorites.
  ///
  Future<void> sendFavoriteToTrakt(BuildContext context, {
    @required ContentType type,
    @required int id,
    @required String title,
    @required String year
  }) async {
    String mediaType = (type == ContentType.TV_SHOW) ? 'shows' : 'movies';

    await http.post(
      TRAKT_SYNC_COLLECTION,
      headers: await _getAuthHeaders(context),
      body: json.encode({
        mediaType: [
          {
            'collected_at': DateTime.now().toUtc().toString(),
            'title': title,
            'year': year,
            'ids': {
              'tmdb': id
            }
          }
        ]
      })
    );
  }

  ///
  /// This removes an item from a user's Trakt favorites.
  ///
  Future<void> removeFavoriteFromTrakt(BuildContext context, {
    @required ContentType type,
    @required int id
  }) async {
    String mediaType = (type == ContentType.TV_SHOW) ? 'shows' : 'movies';

    await http.post(
      TRAKT_SYNC_COLLECTION + "/remove",
      headers: await _getAuthHeaders(context),
      body: json.encode({
        mediaType: [
          {
            "ids": {
              "tmdb": id
            }
          }
        ]
      })
    );
  }

  Future<void> syncWatchHistory(BuildContext context) async {
    // Generate Trakt authentication headers.
    var headers = await _getAuthHeaders(context);

    // Make GET request to history endpoint.
    var responseRaw = await http.get("$TRAKT_SYNC_HISTORY?page=1&limit=1000", headers: headers);
    List<dynamic> response = jsonDecode(responseRaw.body);

    for(Map<String, dynamic> entry in response) {
      String type = entry["type"];
      
      // TODO: Add support for non-tmdb based data.
      int contentId = entry[type]["ids"]["tmdb"];
      if(contentId == null) continue;

      switch(type){
        case "episode":
          String slug = entry["show"]["ids"]["slug"];
          int season = entry["episode"]["season"];
          int episode = entry["episode"]["number"];

          int totalDuration = Duration(minutes: jsonDecode(
              (await http.get("$TRAKT_API_ENDPOINT/shows/$slug/seasons/$season/episodes/$episode/?extended=full", headers: headers)).body
          )["runtime"]).inMilliseconds;

          DatabaseHelper.setWatchProgressById(
            context,
            ContentType.TV_SHOW,
            contentId,
            season: season,
            episode: episode,
            millisecondsWatched: totalDuration,
            totalMilliseconds: totalDuration,
            isFinished: true,
            lastUpdated: DateTime.parse(entry["watched_at"])
          );

          break;
        case "movie":
          String slug = entry["movie"]["ids"]["slug"];
          int totalDuration = Duration(minutes: jsonDecode((await http.get("$TRAKT_API_ENDPOINT/movies/$slug?extended=full", headers: headers)).body)["runtime"]).inMilliseconds;

          DatabaseHelper.setWatchProgress(
            await Service.get<TMDB>().getContentInfo(context, ContentType.MOVIE, contentId),
            millisecondsWatched: totalDuration,
            totalMilliseconds: totalDuration,
            isFinished: true,
            lastUpdated: DateTime.parse(entry["watched_at"])
          );

          break;
        default:
          continue;
      }
    }

  }

  Future<void> syncPlaybackHistory(BuildContext context) async {
    
  }

  ///
  /// This gets a user's Trakt watch history.
  ///
  @Deprecated("This is no longer used. You should instead syncWatchHistory.")
  Future<List<ContentModel>> getWatchHistory(BuildContext context, { bool includeComplete = false }) async {
    List<ContentModel> progressData = [];

    try {
      // Generate Trakt authentication headers.
      var headers = await _getAuthHeaders(context);

      // Make GET request to history endpoint.
      var responseRaw = await http.get(TRAKT_SYNC_HISTORY, headers: headers);
      List<dynamic> response = jsonDecode(responseRaw.body);

      for(Map<String, dynamic> entry in response){
        if(entry["type"] == 'episode'){
          if(progressData.where((_entry) => _entry.id == entry["show"]["ids"]["tmdb"]).length > 0) continue;

          var content = await Service.get<TMDB>().getContentInfo(context, ContentType.TV_SHOW, entry["show"]["ids"]["tmdb"]);

          var progressResponse = jsonDecode((await http.get("https://api.trakt.tv/shows/${entry["show"]["ids"]["trakt"].toString()}/progress/watched", headers: headers)).body);
          content.progress = (double.parse(progressResponse["completed"].toString()) / double.parse(progressResponse["aired"].toString()));
          content.lastWatched = progressResponse["last_watched_at"];

          if(content.progress < 1 || includeComplete) progressData.add(content);
        }
      }

      return progressData;
    }catch(ex){
      print(ex);
      return null;
      //throw new Exception("An error occurred whilst connecting to Trakt.tv.");
    }
  }

}

class TraktAuthenticator extends StatefulWidget {

  final BuildContext context;
  TraktAuthenticator({ this.context });

  @override
  _TraktAuthenticatorState createState() => new _TraktAuthenticatorState();

}

class _TraktAuthenticatorState extends State<TraktAuthenticator> {

  final flutterWebviewPlugin = new FlutterWebviewPlugin();
  StreamSubscription<String> _onUrlChanged;

  @override
  void initState() {
    flutterWebviewPlugin.close();

    // Listen for the code via URL change.
    _onUrlChanged = flutterWebviewPlugin.onUrlChanged.listen((String url) {
      if (mounted && url.contains("native?code=")) {
        _onUrlChanged.cancel();
        String authCode = url.split("code=")[1].replaceAll("#", "");
        Navigator.of(this.context).pop(authCode);
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String _url = "https://trakt.tv/oauth/authorize?response_type=code&"
        "client_id=${Trakt.identity.id}&"
        "redirect_uri=urn:ietf:wg:oauth:2.0:oob";

    return WebviewScaffold(
      url: _url,
      userAgent: "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
          "(KHTML, like Gecko) Chrome/71.0.3578.98 Safari/537.36",
      clearCache: true,
      clearCookies: true,
      appBar: AppBar(
        title: TitleText(S.of(context).trakt_authenticator),
        centerTitle: true,
        elevation: 8.0,
        backgroundColor: Theme.of(context).cardColor,
      ),
    );
  }

  @override
  void dispose() {
    flutterWebviewPlugin.dispose();
    super.dispose();
  }

}

class TraktIdentity {
  final String id;
  final String secret;

  TraktIdentity({
    @required this.id,
    @required this.secret
  });
}