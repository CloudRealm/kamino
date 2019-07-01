import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kamino/api/tmdb.dart';
import 'package:kamino/models/content.dart';
import 'package:kamino/models/list.dart';
import 'package:objectdb/objectdb.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {

  // GENERAL //
  static Future<ObjectDB> openDatabase() async {
    final Directory appDirectory = await getApplicationDocumentsDirectory();
    ObjectDB database = await ObjectDB("${appDirectory.path}/apolloDB.db").open(false);
    return database;
  }

  static Future<void> bulkWrite(List<Map> content) async {
    ObjectDB database = await openDatabase();
    await database.insertMany(content);
    database.close();
  }

  static Future<void> dump() async {
    print("Opening database...");
    ObjectDB database = await openDatabase();
    print("Dumping contents...");
    debugPrint((await database.find({})).toString(), wrapWidth: 100);
  }

  static Future<void> wipe() async {
    ObjectDB database = await openDatabase();
    await database.remove({});
    database.close();
  }

  // LIST CACHE //
  static Future<void> cachePlaylist(ContentListModel list) async {
    ObjectDB database = await openDatabase();
    await database.insert({
      "docType": "cachedPlaylist",
      "timestamp": new DateTime.now().millisecondsSinceEpoch,
      "data": list.toMap()
    });
    database.close();
  }

  static Future<ContentListModel> getCachedPlaylist(int listId) async {
    ObjectDB database = await openDatabase();
    List<Map> data = await database.find({
      "docType": "cachedPlaylist",
      "data.id": listId
    });

    if(data.length < 1) return null;
    ContentListModel cachedList = ContentListModel.fromJSON(data[0]['data']);
    database.close();
    return cachedList;
  }

  static Future<bool> playlistInCache(int listId) async {
    // Check if database needs to be updated
    ObjectDB database = await openDatabase();
    bool inCache = (await database.find({
      "docType": "cachedPlaylist",
      "data.id": listId,
      Op.gte: {
        "timestamp": new DateTime.now().subtract(Duration(days: 1)).millisecondsSinceEpoch
      }
    })).length > 0;
    database.close();
    return inCache;
  }

  // EDITOR'S CHOICE //
  static Future<void> refreshEditorsChoice(BuildContext context, { bool force = false }) async {
    // Check if database needs to be updated
    ObjectDB database = await openDatabase();
    bool canAvoidCheck = (await database.find({
      "docType": "editorsChoice",
      Op.gte: {
        // If older than 24 hours, we should get Editor's Choice again.
        "timestamp": new DateTime.now().subtract(Duration(days: 1)).millisecondsSinceEpoch
      }
    })).length > 0;
    if(canAvoidCheck) return;

    // Fetch comments and content data from TMDB.
    var editorsChoiceComments = jsonDecode((await TMDB.getList(context, 109986, raw: true)))['comments'] as Map;
    List<ContentModel> editorsChoiceContentList = (await TMDB.getList(context, 109986, loadFully: true)).content;

    // Map the data to EditorsChoice objects.
    List<EditorsChoice> editorsChoice = new List();
    for(ContentModel editorsChoiceContent in editorsChoiceContentList){
      editorsChoice.add(new EditorsChoice(
          id: editorsChoiceContent.id,
          title: editorsChoiceContent.title,
          poster: editorsChoiceContent.posterPath,
          type: editorsChoiceContent.contentType,
          comment: editorsChoiceComments['${getRawContentType(editorsChoiceContent.contentType)}:${editorsChoiceContent.id}']
      ));
    }

    // Map the EditorsChoice objects to documents.
    List<Map> editorsChoiceDocuments = editorsChoice.map(
      (EditorsChoice choice) => choice.toMap()
    ).toList();

    // Write data to database.
    await database.insert({
      "docType": "editorsChoice",
      "data": editorsChoiceDocuments,
      "timestamp": new DateTime.now().millisecondsSinceEpoch
    });
    database.close();

  }

  static Future<EditorsChoice> selectRandomEditorsChoice() async {
    ObjectDB database = await openDatabase();
    List<Map> results = await database.find({
      "docType": "editorsChoice"
    });
    if(results.length < 1) return null;

    List editorsChoiceDocuments = results[0]["data"];

    // Randomly select a choice from the Editor's Choice list.
    Map selectedChoice = editorsChoiceDocuments[Random().nextInt(editorsChoiceDocuments.length)];
    return EditorsChoice.fromJSON(selectedChoice);
  }

  static Future<EditorsChoice> selectEditorsChoice(int tmdbID) async {
    ObjectDB database = await openDatabase();

    List<Map> results = await database.find({
      "docType": "editorsChoice"
    });
    if(results.length < 1) return null;

    Map editorsChoice;
    for(Map result in results[0]["data"]){
      if(result['id'] == tmdbID) editorsChoice = result;
    }

    if(editorsChoice == null) return null;
    return EditorsChoice.fromJSON(editorsChoice);
  }

  // WATCH HISTORY //
  static Future<void> setWatchProgressById(BuildContext context, ContentType type, int tmdbID, {
    @required int millisecondsWatched,
    @required int totalMilliseconds,
    int season,
    int episode,
    bool isFinished,
    DateTime lastUpdated,
  }) async {

    //TODO: do not get TMDB data if already have it
    await setWatchProgress(
      await TMDB.getContentInfo(context, type, tmdbID),
      millisecondsWatched: millisecondsWatched,
      totalMilliseconds: totalMilliseconds,
      season: season,
      episode: episode,
      isFinished: isFinished,
      lastUpdated: lastUpdated
    );
  }

  static Future<void> setWatchProgress(ContentModel model, {
    @required int millisecondsWatched,
    @required int totalMilliseconds,
    int season,
    int episode,
    bool isFinished,
    DateTime lastUpdated,
  }) async {
    if(isFinished == null)
      isFinished = (millisecondsWatched / 1000).floor()
                      == (totalMilliseconds / 1000).floor();

    ObjectDB database = await openDatabase();

    if(model.contentType == ContentType.TV_SHOW){
      if(season == null) throw new Exception("Season must not be null.");
      if(episode == null) throw new Exception("Episode must not be null.");

      // If TV show exists in database.
      List<Map> results = await database.find({
        "docType": "watchProgress",
        "type": getRawContentType(model.contentType),
        "id": model.id
      });

      if(results.length > 0){
        await database.update({
          "docType": "watchProgress",
          "type": getRawContentType(model.contentType),
          "id": model.id
        }, {
          "seasons": {
            season.toString(): {
              episode.toString(): {
                "watched": millisecondsWatched,
                "total": totalMilliseconds
              }
            }
          }
        });

        await database.close();
        return;
      }
    }

    await database.insert({
      "docType": "watchProgress",

      "id": model.id,
      "type": getRawContentType(model.contentType),

      "content": {
        "imdbId": model.imdbId,
        "title": model.title,
        "poster": model.posterPath,
        "backdrop": model.backdropPath
      },

      "progress": model.contentType == ContentType.TV_SHOW
          ? {
        "seasons": {
          season.toString(): {
            episode.toString(): {
              "lastUpdated": lastUpdated != null ? lastUpdated.toString() : new DateTime.now().toString(),
              "watched": millisecondsWatched,
              "total": totalMilliseconds,
              "isFinished": isFinished
            }
          }
        }
      } : {
        "lastUpdated": lastUpdated != null ? lastUpdated.toString() : new DateTime.now().toString(),
        "watched": millisecondsWatched,
        "total": totalMilliseconds,
        "isFinished": isFinished
      }
    });

    await database.close();
  }

  static Future<WatchProgressWrapper> getWatchProgress(ContentModel model, {
    int season,
    int episode
  }) async {
    ObjectDB database = await openDatabase();

    Map filter = {
      "docType": "watchProgress",
      "id": model.id,
      "type": getRawContentType(model.contentType)
    };
    filter.addAll(model.contentType == ContentType.TV_SHOW ? {
      "progress.seasons.$season.$episode": true
    } : {});

    List<Map> watchData = await database.find(filter);
    database.close();

    if(watchData.length < 1) return null;
    return WatchProgressWrapper.fromJSON(watchData[0]);
  }

  static Future<void> clearAllWatchProgress() async {
    ObjectDB database = await openDatabase();
    await database.remove({
      "docType": "watchProgress"
    });
    database.close();
  }

  // FAVORITES //
  static Future<void> saveFavoriteById(BuildContext context, ContentType type, int id) async {
    await saveFavorite(await TMDB.getContentInfo(context, type, id));
  }
  
  static Future<void> saveFavorite(ContentModel content) async {
    ObjectDB database = await openDatabase();

    Map dataEntry = FavoriteDocument.fromModel(content).toMap();
    await database.insert(dataEntry);

    database.close();
  }

  static Future<void> saveFavorites(List<FavoriteDocument> content) async {
    bulkWrite(content.map((FavoriteDocument document) => document.toMap()).toList());
  }

  static Future<bool> isFavorite(int tmdbId) async {
    ObjectDB database = await openDatabase();

    var results = await database.find({
      "docType": "favorites",
      "tmdbID": tmdbId
    });

    database.close();
    return results.length == 1 ? true : false;
  }

  static Future<void> removeFavorite(ContentModel model) async {
    await removeFavoriteById(model.id);
  }
  
  static Future<void> removeFavoriteById(int id) async {
    ObjectDB database = await openDatabase();
    await database.remove({"docType": "favorites", "tmdbID": id});
    database.close();
  }

  static Future<void> purgeFavoritesByAuthority(FavoriteAuthority authority) async {
    ObjectDB database = await openDatabase();
    await database.remove({"authority": authority.toString()});
    database.close();
  }

  static Future<Map<String, List<FavoriteDocument>>> getAllFavorites() async {
    return {
      'tv': await getFavoritesByType(ContentType.TV_SHOW),
      'movie': await getFavoritesByType(ContentType.MOVIE)
    };
  }

  static Future<List<int>> getAllFavoriteIds() async {
    ObjectDB database = await openDatabase();
    List<Map> results = await database.find({
      "docType": "favorites"
    });

    database.close();
    return results.map((Map result) => result['tmdbID'] as int).toList();
  }

  static Future<List<FavoriteDocument>> getFavoritesByType(ContentType type) async {
    ObjectDB database = await openDatabase();
    List<Map> results = await database.find({
      "docType": "favorites",
      "contentType": getRawContentType(type)
    });

    database.close();
    return results.map((Map result) => FavoriteDocument(result)).toList();
  }

  // SEARCH HISTORY //

  static Future<List<String>> getSearchHistory() async {
    ObjectDB database = await openDatabase();
    List<Map> results = await database.find({
      "docType": "pastSearch"
    });
    database.close();

    results = results.take(40).toList(growable: false)
      // Sort by timestamp
      ..sort(
          (Map current, Map next) =>
              current['timestamp'].compareTo(next['timestamp'])
      );
    // ...and map to a simple List<String>
    return results.map((Map result) => result['text']).toList().reversed.toList(growable: false).cast<String>();
  }

  static Future<void> writeToSearchHistory(String text) async {
    // Ignore if text is null.
    if(text == null || text.isEmpty) return;

    ObjectDB database = await openDatabase();

    // If already in the database, remove it.
    await database.remove({
      "docType": "pastSearch",
      "text": text
    });

    await database.insert({
      "docType": "pastSearch",
      "text": text,
      "timestamp": new DateTime.now().millisecondsSinceEpoch
    });

    await database.close();
  }

  static Future<void> removeFromSearchHistory(String text) async {
    ObjectDB database = await openDatabase();
    database.remove({
      "docType": "pastSearch",
      "text": text
    });
    database.close();
  }

  static Future<void> clearSearchHistory() async {
    ObjectDB database = await openDatabase();
    database.remove({
      "docType": "pastSearch"
    });
    database.close();
  }
}

class FavoriteAuthority {
  static const LOCAL = const FavoriteAuthority._('local');
  static const SIMKL = const FavoriteAuthority._('simkl');
  static const TMDB = const FavoriteAuthority._('tmdb');
  static const TRAKT = const FavoriteAuthority._('trakt');

  static List<FavoriteAuthority> get values => [LOCAL, SIMKL, TMDB, TRAKT];

  final String value;
  const FavoriteAuthority._(this.value);

  @override
  toString(){
    return value;
  }

  static valueOf(String value){
    return values.firstWhere((authority) => authority.value == value, orElse: null);
  }
}

class FavoriteDocument {

  int tmdbId;
  String name;
  ContentType contentType;
  String imageUrl;
  String year;
  DateTime savedOn;
  FavoriteAuthority authority;

  FavoriteDocument(Map data) :
    tmdbId = data['tmdbID'],
    name = data['name'],
    contentType = data['contentType'] == 'tv' ? ContentType.TV_SHOW : ContentType.MOVIE,
    imageUrl = data['imageUrl'],
    year = data['year'],
    savedOn = DateTime.parse(data['saved_on']),
    authority = FavoriteAuthority.valueOf(data['authority']);

  FavoriteDocument.fromModel(ContentModel model, { FavoriteAuthority authority = FavoriteAuthority.LOCAL }) :
    tmdbId = model.id,
    name = model.title,
    contentType = model.contentType,
    imageUrl = model.posterPath,
    year = model.releaseDate != null && model.releaseDate != ""
        ? DateFormat.y("en_US").format(DateTime.tryParse(model.releaseDate) ?? "1970-01-01")
        : "",
    savedOn = DateTime.now().toUtc(),
    authority = authority;

  Map toMap(){
    return {
      "docType": "favorites",
      "tmdbID": tmdbId,
      "name": name,
      "contentType": getRawContentType(contentType),
      "imageUrl": imageUrl,
      "year": year,
      "saved_on": savedOn.toString(),
      "authority": authority.toString()
    };
  }

}


class EditorsChoice {

  int id;
  ContentType type;
  String title;
  String comment;
  String poster;

  EditorsChoice({
    @required this.id,
    @required this.type,
    @required this.title,
    @required this.comment,
    @required this.poster
  });

  EditorsChoice.fromJSON(Map data){
    this.id = data['id'];
    this.type = getContentTypeFromRawType(data['type']);
    this.title = data['title'];
    this.comment = data['comment'];
    this.poster = data['poster'];
  }

  Map<String, dynamic> toMap(){
    return {
      "id": id,
      "type": getRawContentType(type),
      "title": title,
      "comment": comment,
      "poster": poster
    };
  }

}

class WatchProgress {
  DateTime lastUpdated;
  int watched;
  int total;
  bool isFinished;

  WatchProgress({
    this.lastUpdated,
    this.watched,
    this.total,
    this.isFinished
  });

  WatchProgress.fromJSON(Map json) :
      lastUpdated = DateTime.parse(json['lastUpdated']),
      watched = json['watched'],
      total = json['total'],
      isFinished = json['isFinished'];
}

class EpisodeWatchProgress {

  Map<int, WatchProgress> episodes;

  EpisodeWatchProgress.fromJSON(Map json){
    episodes = json.map((episode, watchProgress) => MapEntry(
      episode,
      WatchProgress.fromJSON(watchProgress)
    ));
  }

}

class SeasonWatchProgress {

  Map<int, EpisodeWatchProgress> seasons;

  SeasonWatchProgress.fromJSON(Map json){
    seasons = json.map((season, seasonData) => MapEntry(
      season,
      seasonData = EpisodeWatchProgress.fromJSON(seasonData)
    ));
  }

}

class WatchProgressWrapper {

  String id;
  ContentType type;

  String imdbId;
  String title;
  String poster;
  String backdrop;

  WatchProgress _otherWatchProgress;
  SeasonWatchProgress _seasonWatchProgress;

  dynamic get watchProgress {
    if(type == ContentType.TV_SHOW) return _seasonWatchProgress;
    return _otherWatchProgress;
  }

  set watchProgress(watchProgress){
    if(type == ContentType.TV_SHOW)  _seasonWatchProgress = watchProgress;
    _otherWatchProgress = watchProgress;
  }

  WatchProgressWrapper.fromJSON(Map json){

    id = json['id'];
    type = getContentTypeFromRawType(json['type']);

    imdbId = json['content']['imdbId'];
    title = json['content']['title'];
    poster = json['content']['poster'];
    backdrop = json['content']['backdrop'];

    if(type == ContentType.TV_SHOW){
      watchProgress = SeasonWatchProgress.fromJSON(json['progress']['seasons']);
    }else{
      watchProgress = WatchProgress.fromJSON(json['progress']);
    }
  }

}