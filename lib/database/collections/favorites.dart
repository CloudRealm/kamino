import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kamino/database/database.dart';
import 'package:kamino/external/ExternalService.dart';
import 'package:kamino/external/api/tmdb.dart';
import 'package:kamino/models/content/content.dart';
import 'package:kamino/models/content/movie.dart';
import 'package:kamino/models/content/tv_show.dart';
import 'package:objectdb/objectdb.dart';

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
        authority = FavoriteAuthority.valueOr(data['authority'], FavoriteAuthority.LOCAL);

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

  ContentModel toContentModel(){
    if(contentType == ContentType.TV_SHOW) return new TVShowContentModel(
        id: tmdbId,
        title: name,
        posterPath: imageUrl,
        releaseDate: "$year-01-01"
    );

    if(contentType == ContentType.MOVIE) return new MovieContentModel(
        id: tmdbId,
        title: name,
        posterPath: imageUrl,
        releaseDate: "$year-01-01"
    );

    return null;
  }

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

class FavoritesCollection {

  static Future<void> saveFavoriteById(BuildContext context, ContentType type, int id) async {
    await saveFavorite(await Service.get<TMDB>().getContentInfo(context, type, id));
  }

  static Future<void> saveFavorite(ContentModel content) async {
    ObjectDB database = await Database.open();

    Map dataEntry = FavoriteDocument.fromModel(content).toMap();
    await database.insert(dataEntry);

    database.close();
  }

  static Future<void> saveFavorites(List<FavoriteDocument> content) async {
    Database.bulkWrite(content.map((FavoriteDocument document) => document.toMap()).toList());
  }

  static Future<bool> isFavorite(int tmdbId) async {
    ObjectDB database = await Database.open();

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
    ObjectDB database = await Database.open();
    await database.remove({"docType": "favorites", "tmdbID": id});
    database.close();
  }

  static Future<void> purgeFavoritesByAuthority(FavoriteAuthority authority) async {
    ObjectDB database = await Database.open();
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
    ObjectDB database = await Database.open();
    List<Map> results = await database.find({
      "docType": "favorites"
    });

    database.close();
    return results.map((Map result) => result['tmdbID'] as int).toList();
  }

  static Future<List<FavoriteDocument>> getFavoritesByType(ContentType type) async {
    ObjectDB database = await Database.open();
    List<Map> results = await database.find({
      "docType": "favorites",
      "contentType": getRawContentType(type)
    });

    database.close();
    return results.map((Map result) => FavoriteDocument(result)).toList();
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
    return valueOr(value, null);
  }

  static valueOr(String value, FavoriteAuthority orValue){
    return values.firstWhere((authority) => authority.value == value, orElse: () => orValue);
  }
}