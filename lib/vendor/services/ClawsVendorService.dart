import 'dart:async';
import 'dart:convert' as Convert;
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as Crypto;
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:kamino/external/ExternalService.dart';
import 'package:kamino/external/api/realdebrid.dart';
import 'package:kamino/external/api/tmdb.dart';
import 'package:kamino/generated/i18n.dart';
import 'package:kamino/main.dart';
import 'package:kamino/models/content.dart';
import 'package:kamino/models/movie.dart';
import 'package:kamino/models/source.dart';
import 'package:kamino/models/tv_show.dart';
import 'package:kamino/ui/interface.dart';
import 'package:kamino/util/settings.dart';
import 'package:kamino/vendor/struct/VendorService.dart';
import 'package:w_transport/w_transport.dart' as Transport;
import 'package:w_transport/vm.dart' show vmTransportPlatform;

class ClawsVendorService extends VendorService {
  // Settings
  static const bool ALLOW_SOURCE_SELECTION = true;
  static const bool FORCE_TOKEN_REGENERATION = true;

  // Claws information
  final String server;
  final String clawsKey;
  final bool isOfficial;

  ClawsVendorService(
      {this.server,
      this.clawsKey,
      this.isOfficial = false,
      @required bool allowSourceSelection})
      : super(
            allowSourceSelection: allowSourceSelection, isNetworkService: true);

  Transport.WebSocket _webSocket;
  String _token;
  bool _userHasRd;

  @override
  Future<bool> initialize(BuildContext context) async {
    if (_webSocket != null) _webSocket.close();
    clearSourceList();

    _userHasRd = await Service.get<RealDebrid>().isAuthenticated() && (await Service.get<RealDebrid>().getUserInfo()).isPremium();
    if (_userHasRd) {
      await Service.get<RealDebrid>().validateToken();
    }

    setStatus(context, VendorServiceStatus.INITIALIZING);

    /* ATTEMPT TO CONNECT TO SERVER */
    try {
      Response response = await get(server + 'api/v1/status')
          .timeout(Duration(seconds: 10), onTimeout: () => null);

      if (response != null && response.statusCode == 200) {
        // TODO: Perhaps show a warning if the server is under high load?
        // var status = Convert.jsonDecode(response.body);
        return true;
      }

      this.setStatus(context, VendorServiceStatus.IDLE);
      Interface.showSimpleErrorDialog(context,
          title: S.of(context).unable_to_connect,
          reason: S.of(context).the_request_timed_out + "\n\n(" + S.of(context).is_your_connection_too_slow + ")");
      return false;
    } catch (ex) {
      this.setStatus(context, VendorServiceStatus.IDLE);
      print("Exception whilst determining Claws status: $ex");

      if(ex is SocketException){
        reportError(ex, null, shouldShowDialog: true, cancelPop: true);
        return false;
      }

      Interface.showSimpleErrorDialog(context,
          title: S.of(context).unable_to_connect,
          reason: isOfficial
              ? S.of(context).the_appname_server_is_currently_offline_for_server_upgrades(appName) + "\n" + S.of(context).please_check_the_announcements_channel_in_our_discord_server_for
              : S.of(context).unable_to_connect_to_server);
      return false;
    }
  }

  @override
  Future<bool> authenticate(BuildContext context) async {
    if (this.status != VendorServiceStatus.INITIALIZING) return false;
    this.setStatus(context, VendorServiceStatus.AUTHENTICATING);

    String token = await Settings.clawsToken;
    double tokenSetTime = await Settings.clawsTokenSetTime;

    var now = await getNTPTime();
    if (!FORCE_TOKEN_REGENERATION &&
        token != null &&
        (tokenSetTime + 3600) >= now) {
      print("Attempting to re-use token...");

      // TODO: Check that token is still valid when reusing!

      _token = token;
      return true;
    } else {
      var clawsClientHash;

      try {
        clawsClientHash = await _generateClawsHash(clawsKey, now)
            .timeout(Duration(seconds: 5), onTimeout: () => null);
      } catch (ex) {
        print(ex);
      }

      if (clawsClientHash == null) {
        this.setStatus(context, VendorServiceStatus.IDLE);
        Interface.showSimpleErrorDialog(context,
            title: S.of(context).unable_to_connect,
            reason:
                S.of(context).authentication_timed_out_please_try_again + "\n\n" + S.of(context).if_this_problem_persists_please_contact_a_member_of_staff);
        return false;
      }

      Response response;
      try {
        response = await post(server + 'api/v1/login',
                body: Convert.jsonEncode({"clientID": clawsClientHash}),
                headers: {"Content-Type": "application/json"})
            .timeout(Duration(seconds: 10), onTimeout: () async {
          return null;
        });
      } catch (ex) {}

      if (response == null || response.statusCode != 200) {
        this.setStatus(context, VendorServiceStatus.IDLE);
        Interface.showSimpleErrorDialog(context,
            title: S.of(context).authentication_failed,
            reason:
                S.of(context).it_seems_this_copy_of_the_app_is_out_of + "\n\n(" + S.of(context).the_server_failed_to_verify_the_apps_integrity + ")"
        );
        return false;
      }

      var tokenResponse = Convert.jsonDecode(response.body);

      try {
        if (tokenResponse["auth"]) {
          var token = tokenResponse["token"];
          var tokenJson = jwtDecode(token);
          await (Settings.clawsToken = token);
          await (Settings.clawsTokenSetTime = tokenJson['exp'].toDouble());
          print("Generated new token...");
          _token = token;

          return true;
        }
      } catch (ex) {}

      this.setStatus(context, VendorServiceStatus.IDLE);
      Interface.showSimpleErrorDialog(context,
          title: S.of(context).unable_to_connect, reason: tokenResponse["message"]);
      return false;
    }
  }

  @override
  Future<void> playMovie(MovieContentModel movie, BuildContext context) async {
    if (!await initialize(context)) return;

    String title = movie.title;
    String releaseDate = movie.releaseDate;

    var year = '';
    if (releaseDate != null && releaseDate != "")
        year = new DateFormat.y("en_US").format(DateTime.parse(releaseDate));

    String clawsToken = _token;
    String webSocketServer = server
        .replaceFirst(new RegExp(r'https?'), "ws")
        .replaceFirst(new RegExp(r'http?'), "ws");
    String endpointURL = "$webSocketServer?token=$clawsToken";

    String data = Convert.jsonEncode({
      "type": "movies",
      "title": title,
      "titles": [title] + Service.get<TMDB>().getAlternativeTitles(movie),
      "year": year,
      "imdb_id": movie.imdbId,
      "hasRD": _userHasRd
    });

    if(!await authenticate(context)) return;
    runZoned<Future<void>>(
      () => _beginProcessing(
        context,
        endpointURL,
        data,
        movie,
        displayTitle: title
      ),
      onError: (error, StackTrace stacktrace){
        print("Error whilst searching TV show: ${error.toString()}");
        print(stacktrace.toString());
      }
    );
  }

  @override
  Future<void> playTVShow(TVShowContentModel show, int seasonNumber,
      int episodeNumber, BuildContext context) async {
    if (!await initialize(context)) return;

    String title = show.title;
    String releaseDate = show.releaseDate;

    var year = '';
    if (releaseDate != null && releaseDate != "")
      year = new DateFormat.y("en_US").format(DateTime.parse(releaseDate));
    var displayTitle =
        "$title \u2022 S${seasonNumber.toString().padLeft(2, '0')} E${episodeNumber.toString().padLeft(2, '0')}";

    String clawsToken = _token;
    String webSocketServer = server
        .replaceFirst(new RegExp(r'https?'), "ws")
        .replaceFirst(new RegExp(r'http?'), "ws");
    String endpointURL = "$webSocketServer?token=$clawsToken";

    String data = Convert.jsonEncode({
      "type": "tv",
      "title": title,
      "titles": [title] + Service.get<TMDB>().getAlternativeTitles(show),
      "year": year,
      "season": seasonNumber,
      "episode": episodeNumber,
      "imdb_id": show.imdbId,
      "hasRD": _userHasRd
    });

    if (!await authenticate(context)) return;
    runZoned<Future<void>>(
      () => _beginProcessing(
        context,
        endpointURL,
        data,
        show,
        displayTitle: displayTitle
      ),
      onError: (error, StackTrace stacktrace){
        print("Error whilst searching TV show: ${error.toString()}");
        print(stacktrace.toString());
      }
    );
  }

  ///
  /// Once authenticated with the server, this method will handle interaction
  /// with the websocket to get results.
  ///
  _beginProcessing(
      BuildContext context, String url, String data, ContentModel model,
      {@required String displayTitle}) async {
    // Prepare to process the information.
    if (displayTitle == null) displayTitle = model.title;
    this.setStatus(context, VendorServiceStatus.PROCESSING,
        title: displayTitle);

    // Connect to the websocket server...
    try {
      _webSocket = await Transport.WebSocket.connect(Uri.parse(url),
              transportPlatform: vmTransportPlatform)
          .timeout(Duration(seconds: 10), onTimeout: () => null);
    } catch (ex) {
      this.setStatus(context, VendorServiceStatus.IDLE);
      Interface.showSimpleErrorDialog(context,
          title: S.of(context).scraping_failed, reason: S.of(context).the_socket_connection_failed);
      print(ex.toString());
      return;
    }

    if (_webSocket == null) {
      this.setStatus(context, VendorServiceStatus.IDLE);
      Interface.showSimpleErrorDialog(context,
          title: S.of(context).scraping_failed,
          reason:
              S.of(context).the_socket_connection_timed_out + " (" + S.of(context).is_your_connection_too_slow + ")");
      return;
    }

    bool isServerDone = false;
    List<String> pendingScrapes = [];

    // Initialize the websocket client.
    _webSocket.listen((message) async {
      try {
        var event = Convert.jsonDecode(message);
        String eventName = event['event'];

        switch (eventName) {
          case 'status':
            print(event);
            break;

          ///
          /// Some sources return URLs that are IP-bound. Meaning data can only be
          /// subsequently accessed from that URL if it is from the IP that
          /// initially retrieved the URL.
          ///
          /// To get around this, Claws uses 'scrape' events. These events return
          /// a URL that the client should request the HTML from and then send to
          /// Claws for analysis.
          ///
          /// For more information, please visit
          /// https://github.com/ApolloTVofficial/Claws/wiki/IP-Locking
          ///
          case 'scrape':
            // Ensure that the headers array is not null.
            if (event['headers'] == null) {
              event['headers'] = new Map<String, String>();
            }
            var cookie = '';
            Response htmlContent;

            // Attempt to receive and process HTML content from source.
            try {
              htmlContent =
                  await get(event['target'], headers: event['headers']);

              if (event['cookieRequired'] != '') {
                var cookieKey = event['cookieRequired'];
                var cookieList = htmlContent.headers['set-cookie'].split(',');
                cookie = cookieList
                    .lastWhere((String i) => i.contains(cookieKey))
                    .split(';')
                    .firstWhere((String i) => i.contains(cookieKey));
              }
            } catch (ex) {
              print(
                  "An error occurred whilst fetching HTML content for analysis from source. (${event['target']})");
              return;
            }

            // Now send the HTML content to Claws for analysis.
            try {
              String message = Convert.jsonEncode({
                'type': 'resolveHtml',
                'provider': event['provider'],
                'resolver': event['resolver'],
                'cookie': cookie,
                'html': Convert.base64
                    .encode(Convert.utf8.encode(htmlContent.body)),
                'scrapeId': event['scrapeId']
              });

              _webSocket.add(message);
              pendingScrapes.add(event['scrapeId']);
            } catch (ex) {
              print(
                  "An error occurred whilst submitting HTML content to Claws for analysis.");
            }
            break;

          ///
          /// Once Claws is finished scraping a source, it sends a 'scrapeEnd'
          /// event. These can be used to keep track of when the connection to
          /// the server can be closed.
          case 'scrapeEnd':
            pendingScrapes.remove(event['scrapeId']);

            if (pendingScrapes.length == 0 && isServerDone)
              setStatus(context, VendorServiceStatus.DONE);
            break;
          ///
          /// If user has RD, he will be served scrape events modified for RD
          /// Events are separated so it doesn't mess with scrape counter
          ///
          case 'RDScrape':
            var rdResult = await Service.get<RealDebrid>().unrestrictLink(event['target']);
            SourceModel rdModel = new SourceModel.fromRDJSON(rdResult);
            var splitParts = rdModel.file.data.split('.');
            var fileExtension =  splitParts[splitParts.length - 1].toLowerCase();
            if (fileExtension == 'mkv' || fileExtension == 'mp4' || fileExtension == 'avi') {
              rdModel.metadata.provider = event['provider'];
              rdModel.metadata.source = event['resolver'];
              rdModel.metadata.quality = event['quality'];

              addSource(rdModel);
            }
            break;
          ///
          /// Once Claws has found a result from a source, it is sent to the
          /// client in the form of a 'result' event.
          ///
          /// These contain a stream URL that can be played by the client as well
          /// as some metadata about the URL, such as quality information.
          ///
          case 'result':
            if(_webSocket.closeReason != null) return;

            var sourceFile = event['file'];
            if (sourceFile == null) {
              print(
                  "No file provided (event['file']), therefore discarding. (${Convert.jsonEncode(event)})");
              return;
            }

            var sourceMeta = event['metadata'];
            String sourceStreamURL = sourceFile['data'];

            // If the URL is invalid, discard the result.
            try {
              Uri.parse(sourceStreamURL);
            } catch (ex) {
              print("Invalid URL: $sourceStreamURL (${ex.toString()})");
              return;
            }

            // If the server was able to analyze the headers and could determine
            // that the URL is not streamable, handle it accordingly.
            if (!event['isResultOfScrape']) {
              if (sourceMeta['isStreamable'] != null &&
                  !sourceMeta['isStreamable']) {
                // For now, the app cannot handle direct download links.
                // Therefore, we will just discard the link.
                print(
                    "Link is not streamable, therefore discarding. ($sourceStreamURL)");
                return;
              }
            }

            // Initialize HttpClient and response...
            HttpClient httpClient = HttpClient();
            HttpClientResponse headResponse;
            // Measure epoch time in milliseconds (to determine ping).
            int preRequest = new DateTime.now().millisecondsSinceEpoch;

            try {
              headResponse = await httpClient
                  .headUrl(Uri.parse(sourceStreamURL))
                  .then((HttpClientRequest request) {
                //request.headers.add('Range', 'bytes=0-125000');
                request.followRedirects = true;
                return request.close();
              }).timeout(Duration(seconds: 10), onTimeout: () => null);
            } catch (ex) {
              print(
                  "Error checking stream data: $sourceStreamURL (${ex.toString()})");
              return;
            }
            httpClient.close();

            if (headResponse == null) {
              print(
                  "Request to $sourceStreamURL timed out whilst being analyzed.");
              // Making this null, should we choose to allow such requests in future.
              event['metadata']['ping'] = null;
              return;
            }

            // If the client was redirected, update the URL, to reflect the
            // redirect.
            if (headResponse.redirects.length > 0) {
              event['file']['data'] =
                  headResponse.redirects.last.location.toString();
              sourceStreamURL = event['file']['data'];
            }

            // Get the response time of the URL.
            int ping = (new DateTime.now().millisecondsSinceEpoch - preRequest);
            if (headResponse.statusCode >= 400) {
              print(
                  "Request statusCode >= 400, therefore discarding. ($sourceStreamURL)");
              return;
            }
            event['metadata']['ping'] = ping;

            // Get the HEAD request details.
            bool supportsRange =
                headResponse.headers.value('accept-ranges').contains("bytes");
            int contentLength = headResponse.contentLength;

            if (!supportsRange) {
              // For now, the app cannot handle direct download links.
              // Therefore, we will just discard the link.
              print(
                  "Link is not streamable, therefore discarding. ($sourceStreamURL)");
              return;
            }

            // Finally, add the data to the source and add the source to the
            // list of found content.
            SourceModel source = SourceModel.fromJSON(event);
            source.metadata.contentLength = contentLength;

            addSource(source);
            break;

          ///
          /// Once Claws has finished searching for a stream, it will return the
          /// 'done' event.
          ///
          /// REMEMBER: This does not take into account scrape results as those
          /// can be sent by the client at any time.
          ///
          case 'done':
            isServerDone = true;
            print("-- Server done! --");

            if (pendingScrapes.length == 0
                // (We don't want to call done twice.)
                && status == VendorServiceStatus.PROCESSING) {
              setStatus(context, VendorServiceStatus.DONE);
            }
            break;

          default:
            print("An unexpected event was received: " + eventName);
        }
      } catch (ex) {
        print("Guys, David did something stupid: " + ex.toString());
      }
    }, onError: (error) {
      this.setStatus(context, VendorServiceStatus.IDLE);
      Interface.showSimpleErrorDialog(context,
          title: S.of(context).scraping_failed,
          reason: S.of(context).an_error_occurred_whilst_communicating_with_claws);
      print(
          S.of(context).an_error_occurred_whilst_communicating_with_claws_detailed(error.toString()));
      return;
    });

    // Add the data to the socket client (thus commanding the server to begin.)
    _webSocket.add(data);
  }

  @override
  Future<void> done(BuildContext context) async {
    print("-- All done! --");
    if(_webSocket != null) _webSocket.close();
  }

  ///////////////////////////////
  /// CLAWS UTILITY FUNCTIONS ///
  ///////////////////////////////

  Future<int> getNTPTime() async {
    var response = await get(server + "api/v1/ntp").timeout(Duration(seconds: 10), onTimeout: () => null);
    if(response != null) {
      var responseData = await
      Convert.jsonDecode((response).body);
      return responseData['now'];
    }else{
      return new DateTime.now().millisecondsSinceEpoch;
    }
  }

  Future<String> _generateClawsHash(String clawsClientKey, int now) async {
    Crypto.IV iv = Crypto.IV(Uint8List.fromList(
        new List.generate(8, (_) => Random.secure().nextInt(128))
    ));

    final key = Crypto.Key.fromUtf8(clawsClientKey.substring(0, 32));
    final encryptor = Crypto.Encrypter(Crypto.Salsa20(key));
    final plainText = "$now|$clawsClientKey";
    final payload = encryptor.encrypt(plainText, iv: iv);

    return "${iv.base16}|${payload.base16}";
  }

  String formatBytesAsHexString(Uint8List bytes) {
    var result = StringBuffer();
    for (var i = 0; i < bytes.lengthInBytes; i++) {
      var part = bytes[i];
      result.write('${part < 16 ? '0' : ''}${part.toRadixString(16)}');
    }
    return result.toString();
  }

  String base64UrlDecode(String str) {
    String output = str.replaceAll("-", "+").replaceAll("_", "/");
    switch (output.length % 4) {
      case 0:
        break;
      case 2:
        output += "==";
        break;
      case 3:
        output += "=";
        break;
      default:
        throw "Illegal base64url string!";
    }

    try {
      return Uri.decodeFull(
          Convert.utf8.decode(Convert.base64Url.decode(output)));
    } catch (err) {
      return Convert.utf8.decode(Convert.base64Url.decode(output));
    }
  }

  dynamic jwtDecode(token) {
    try {
      return Convert.jsonDecode(base64UrlDecode(token.split('.')[1]));
    } catch (e) {
      throw "Invalid token specified: " + e.message;
    }
  }
}
