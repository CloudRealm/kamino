import 'dart:convert' as Convert;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kamino/external/ExternalService.dart';
import 'package:kamino/external/struct/content_database.dart';
import 'package:kamino/main.dart';
import 'package:kamino/models/content/content.dart';
import 'package:kamino/models/crew.dart';
import 'package:kamino/models/list.dart';
import 'package:kamino/models/content/movie.dart';
import 'package:kamino/models/content/tv_show.dart';
import 'package:kamino/models/person.dart';
import 'package:kamino/util/database_helper.dart';

class TMDB extends ContentDatabaseService {

  TMDBIdentity identity;

  TMDB(TMDBIdentity _identity) : super(
    "TMDB",
    isPrimaryService: true
  ){ identity = _identity; }

  static const String ROOT_URL = "https://api.themoviedb.org/3";
  static const String IMAGE_CDN = "https://image.tmdb.org/t/p/original";
  static const String IMAGE_CDN_LOWRES = "https://image.tmdb.org/t/p/w500";
  static const String IMAGE_CDN_POSTER = "https://image.tmdb.org/t/p/w300";

  /// You will need to define the API key in your vendor configuration file.
  /// Check our documentation for more information.
  String getDefaultArguments(BuildContext context) {
    try {
      KaminoAppState application = context.ancestorStateOfType(const TypeMatcher<KaminoAppState>());
      if(application != null) return "?api_key=${identity.key}&language=en-US";
    }catch(ex) {
    }

    return "";
  }

  // These lists are curated by the ApolloTV team and you're welcome to use them.
  // Otherwise, you can replace them by supplying an array of TMDB list IDs.
  static const Map<ContentType, List<String>> curatedTMDBLists = {
    /*ContentType.MIXED: [
      // Editor's Choice
      "109986",
    ],*/

    ContentType.TV_SHOW: [
      // Awards Season
      "105806",
      // DC Comics
      "108237",
      // Marvel Cinematic Universe
      "105804",
      // Marvel Comics
      "108281",
      // Netflix Exclusives
      "105648",
      // New TV Shows
      "110825",
      // Other Exclusives
      "109260",
      // Season Premieres
      "117689",
      // TV Top Picks
      "107032",
    ],

    ContentType.MOVIE: [
      // Awards Season 2019
      "105805",
      // Christmas
      "107836",
      // DC Comics
      "105614",
      // DC Extended Universe
      "105613",
      // Disney & Friends
      "105547",
      // Halloween
      "110126",
      // James Bond
      "107927",
      // Marvel Cinematic Universe
      "105602",
      // Marvel Comics:
      "105603",
      // Netflix Exlusives
      "105608",
      // New HD releases
      "105604",
      // Other Exclusives
      "105611",
      // Romantic Comedies
      "109896",
      // Star Trek
      "107930",
      // Star Wars
      "107926",
      // Movie Top Picks
      "110599",
      // Wizarding World
      "107925",
    ]
  };


  Future<dynamic> getList(BuildContext context, int id, { bool loadFully = false, bool raw = false, bool useCache = false }) async {
    try {
      if (useCache) {
        if (await DatabaseHelper.playlistInCache(id)) {
          // If the list is empty, MISS the cache.
          ContentListModel listModel = await DatabaseHelper.getCachedPlaylist(
              id);
          if (listModel.content.length > 0) return listModel;
        }
      }

      var rawContentResponse = (await http.get(
          "https://api.themoviedb.org/4/list/$id${getDefaultArguments(
              context)}", headers: {
        'Content-Type': 'application/json;charset=utf-8'
      })).body;

      if (raw) return rawContentResponse;
      ContentListModel listModel = ContentListModel.fromJSON(
          Convert.jsonDecode(rawContentResponse));

      if (!listModel.fullyLoaded && loadFully && listModel.totalPages != null &&
          listModel.totalPages > 1) {
        List<ContentModel> fullContentList = new List();

        // (TMDB starts at index of 1 *sigh*)
        for (int i = 1; i < listModel.totalPages; i++) {
          // Make a request to TMDB for the desired page.
          var sublistContentResponse = (await http.get(
              "https://api.themoviedb.org/4/list/$id${getDefaultArguments(
                  context)}&page=$i", headers: {
            'Content-Type': 'application/json;charset=utf-8'
          })).body;

          // Cast the results into a list.
          List sublistContent = Convert.jsonDecode(
              sublistContentResponse)["results"];

          if (sublistContent != null) {
            // Map the list items to ContentModels and add all the items to fullContentList.
            fullContentList.addAll(sublistContent.map((contentItem) =>
            contentItem['media_type'] == 'movie'
                ? MovieContentModel.fromJSON(contentItem)
                : TVShowContentModel.fromJSON(contentItem)
            ).toList());
          }
        }

        // Finally, update the ContentListModel's content item.
        listModel.content = fullContentList;
        listModel.fullyLoaded = true;
      }

      if (useCache) {
        DatabaseHelper.cachePlaylist(listModel);
      }
      return listModel;
    }catch(ex){
      print("Error whilst fetching list #$id");
      throw ex;
    }
  }

  Future<ContentModel> getContentInfo(BuildContext context, ContentType type, int id, { String appendToResponse }) async {
    // Get the data from the server.
    http.Response response = await http.get(
        "${TMDB.ROOT_URL}/${getRawContentType(type)}/$id${getDefaultArguments(context)}"
            + (appendToResponse != null ? "&append_to_response=$appendToResponse,external_ids,alternative_titles" : "&append_to_response=external_ids,alternative_titles")
    );
    String json = response.body;

    if (type == ContentType.MOVIE)
      // Return movie content model.
      return MovieContentModel.fromJSON(
          Convert.jsonDecode(json)
      );
    else if (type == ContentType.TV_SHOW)
      // Return TV show content model.
      return TVShowContentModel.fromJSON(
          Convert.jsonDecode(json)
      );

    throw new Exception("Invalid content type: $type");
  }

  List<String> getAlternativeTitles(ContentModel model){
    List<String> result = [];

    if(model.alternativeTitles == null || model.alternativeTitles.length == 0)
      return result;

    List<LocalizedTitleModel> alternativeTitles = model.alternativeTitles;

    // Select up to 3 English titles
    result.addAll(
      alternativeTitles.where(
        (LocalizedTitleModel title) => title.iso_3166_1 == "US"
      ).take(3).map((LocalizedTitleModel title) => title.title).toList()
    );

    // ...and up to 2 titles from the native locale.
    result.addAll(
        alternativeTitles.where(
                (LocalizedTitleModel title) => title.iso_3166_1 == model.originalCountry
        ).take(2).map((LocalizedTitleModel title) => title.title).toList()
    );

    if(!result.contains(model.originalTitle))
      result = [model.originalTitle] + result;
    return result;
  }

  Future<SearchResults> search(BuildContext context, String query, { bool isAutoComplete }) async {
    final String url = "${TMDB.ROOT_URL}/search/multi"
        "${getDefaultArguments(context)}"
        "&query=$query"
        "&page=1"
        "&include_adult=false";

    Map json = Convert.jsonDecode((await http.get(url)).body);
    List results = json['results'] as List;
    
    List<PersonModel> people = new List();
    List<MovieContentModel> movies = new List();
    List<TVShowContentModel> shows = new List();

    results?.where((result) => result['media_type'] == 'person')?.forEach((person){
      people.add(PersonModel.fromJSON(person));
    });

    results?.where((result) => result['media_type'] == getRawContentType(ContentType.TV_SHOW))?.forEach((show){
      shows.add(TVShowContentModel.fromJSON(show));
    });

    results?.where((result) => result['media_type'] == getRawContentType(ContentType.MOVIE))?.forEach((movie){
      movies.add(MovieContentModel.fromJSON(movie));
    });
    
    return SearchResults(
      people: people,
      movies: movies,
      shows: shows
    );
  }

}

class TMDBIdentity {
  final String key;

  TMDBIdentity({
    @required this.key
  });
}