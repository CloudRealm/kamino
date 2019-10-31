import 'package:flutter/material.dart';
import 'package:kamino/database/database.dart';
import 'package:kamino/external/ExternalService.dart';
import 'package:kamino/external/api/tmdb.dart';
import 'package:kamino/models/content/content.dart';
import 'package:objectdb/objectdb.dart';

class WatchProgressCollection {

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
        await Service.get<TMDB>().getContentInfo(context, type, tmdbID),
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

    ObjectDB database = await Database.open();

    if(lastUpdated == null) lastUpdated = new DateTime.now();
    if(model.contentType == ContentType.TV_SHOW) {
      if (season == null) throw new Exception("Season must not be null.");
      if (episode == null) throw new Exception("Episode must not be null.");
    }

      // If content exists in database, simply update it rather than
      // creating a new entry.
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
        "progress": model.contentType == ContentType.TV_SHOW ? {
          "seasons": {
            season.toString(): {
              episode.toString(): {
                "lastUpdated": lastUpdated.toString(),
                "watched": millisecondsWatched,
                "total": totalMilliseconds,
                "isFinished": isFinished
              }
            }
          }
        } : {
          "lastUpdated": lastUpdated.toString(),
          "watched": millisecondsWatched,
          "total": totalMilliseconds,
          "isFinished": isFinished
        }
      });

      await database.close();
      return;
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
              "lastUpdated": lastUpdated.toString(),
              "watched": millisecondsWatched,
              "total": totalMilliseconds,
              "isFinished": isFinished
            }
          }
        }
      } : {
        "lastUpdated": lastUpdated.toString(),
        "watched": millisecondsWatched,
        "total": totalMilliseconds,
        "isFinished": isFinished
      }
    });

    await database.close();
  }

  static Future<WatchProgressDocumentWrapper> getWatchProgress(ContentModel model, {
    int season,
    int episode
  }) async {
    ObjectDB database = await Database.open();

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
    return WatchProgressDocumentWrapper.fromJSON(watchData[0]);
  }

  static Future<void> clearAllWatchProgress() async {
    ObjectDB database = await Database.open();
    await database.remove({
      "docType": "watchProgress"
    });
    database.close();
  }
  
}

class WatchProgressDocument {
  DateTime lastUpdated;
  int watched;
  int total;
  bool isFinished;

  WatchProgressDocument({
    this.lastUpdated,
    this.watched,
    this.total,
    this.isFinished
  });

  WatchProgressDocument.fromJSON(Map json) :
        lastUpdated = DateTime.parse(json['lastUpdated']),
        watched = json['watched'],
        total = json['total'],
        isFinished = json['isFinished'];
}

class EpisodeWatchProgress {

  Map<int, WatchProgressDocument> episodes;

  EpisodeWatchProgress.fromJSON(Map json){
    episodes = json.map((episode, watchProgress) => MapEntry(
        episode,
        WatchProgressDocument.fromJSON(watchProgress)
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

class WatchProgressDocumentWrapper {

  String id;
  ContentType type;

  String imdbId;
  String title;
  String poster;
  String backdrop;

  WatchProgressDocument _otherWatchProgress;
  SeasonWatchProgress _seasonWatchProgress;

  dynamic get watchProgress {
    if(type == ContentType.TV_SHOW) return _seasonWatchProgress;
    return _otherWatchProgress;
  }

  set watchProgress(watchProgress){
    if(type == ContentType.TV_SHOW)  _seasonWatchProgress = watchProgress;
    _otherWatchProgress = watchProgress;
  }

  WatchProgressDocumentWrapper.fromJSON(Map json){

    id = json['id'];
    type = getContentTypeFromRawType(json['type']);

    imdbId = json['content']['imdbId'];
    title = json['content']['title'];
    poster = json['content']['poster'];
    backdrop = json['content']['backdrop'];

    if(type == ContentType.TV_SHOW){
      watchProgress = SeasonWatchProgress.fromJSON(json['progress']['seasons']);
    }else{
      watchProgress = WatchProgressDocument.fromJSON(json['progress']);
    }
  }

}