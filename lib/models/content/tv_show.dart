import 'package:kamino/models/content/content.dart';
import 'package:kamino/models/crew.dart';
import 'package:kamino/models/review.dart';
import 'package:meta/meta.dart';

class TVShowContentModel extends ContentModel {

  final List createdBy;
  final List episodeRuntime;
  final List seasons;
  final List networks;
  final String status;
  final double popularity;

  TVShowContentModel({
    // Content model inherited parameters
    @required int id,
    @required String title,
    List<LocalizedTitleModel> alternativeTitles,
    String originalTitle,
    String originalCountry,
    String imdbId,
    String overview,
    String releaseDate,
    String homepage,
    List genres,
    double rating,
    String backdropPath,
    String posterPath,
    int voteCount,
    //double progress,
    //String lastWatched,
    List cast,
    List crew,
    List<TVShowContentModel> recommendations,
    List videos,
    List reviews,
    int totalReviews,

    // TV Show parameters
    this.createdBy,
    this.episodeRuntime,
    this.seasons,
    this.networks,
    this.status,
    this.popularity
  }) : super( // Call the parent constructor...
    id: id,
    imdbId: imdbId,
    title: title,
    alternativeTitles: alternativeTitles,
    contentType: ContentType.TV_SHOW,
    overview: overview,
    releaseDate: releaseDate,
    homepage: homepage,
    genres: genres,
    rating: rating,
    backdropPath: backdropPath,
    posterPath: posterPath,
    voteCount: voteCount,
    cast: cast,
    crew: crew,
    recommendations: recommendations,
    videos: videos,
    originalTitle: originalTitle,
    originalCountry: originalCountry,
    totalReviews: totalReviews,
    reviews: reviews
  );

  static TVShowContentModel fromJSON(Map json){
    Map credits = json['credits'] != null ? json['credits'] : {'cast': null, 'crew': null};
    List videos = json['videos'] != null ? json['videos']['results'] : null;
    List<TVShowContentModel> recommendations = json['recommendations'] != null
        ? (json['recommendations']['results'] as List).map(
            (element) => TVShowContentModel.fromJSON(element)
    ).toList()
        : null;
    List<LocalizedTitleModel> alternativeTitles = json['alternative_titles'] != null
      ? (json['alternative_titles']['results'] as List).map(
        (element) => LocalizedTitleModel.fromJSON(element)
    ).toList() : null;
    int totalReviews = json['reviews'] != null ? json['reviews']['total_results'] : null;
    List reviews = json['reviews'] != null ? json['reviews']['results'] : null;

    return new TVShowContentModel(
      // Inherited properties.
      // (Copy-paste these to other models - it is fine to make small changes.)
      id: json["id"],
      imdbId: json["external_ids"] != null ? json["external_ids"]["imdb_id"] : null,
      title: json["name"] == null ? json["original_name"] : json["name"],
      overview: json["overview"],
      releaseDate: json["first_air_date"],
      homepage: json["homepage"],
      genres: json["genres"],
      rating: json["vote_average"] != null ? json["vote_average"].toDouble() : -1.0,
      backdropPath: json["backdrop_path"],
      posterPath: json["poster_path"],
      voteCount: json["vote_count"] != null ? json["vote_count"] : 0,
      cast: credits['cast'] != null ? (credits['cast'] as List).map((entry) => CastMemberModel.fromJSON(entry)).toList() : null,
      crew: credits['crew'] != null ? (credits['crew'] as List).map((entry) => CrewMemberModel.fromJSON(entry)).toList() : null,
      recommendations: recommendations,
      videos: videos,
      alternativeTitles: alternativeTitles,
      originalCountry: json['origin_country'] != null && json['origin_country'].length > 0
          ? json['origin_country'][0] : null,
      originalTitle: json['original_name'],
      totalReviews: totalReviews != null ? totalReviews : null,
      reviews: reviews != null ? reviews.map((entry) => ReviewModel.fromJSON(entry)).toList() : null,

      // Object-specific properties.
      createdBy: json["created_by"],
      episodeRuntime: json["episode_run_time"],
      seasons: json["seasons"],
      networks: json["networks"],
      status: json["status"],
      popularity: json["popularity"] != null ? json["popularity"].toDouble() : 0.0,
    );
  }

  @override
  Map toStoredMap() {
    return {
      "id": id,
      "imdbId": imdbId,
      "title": title,
      "contentType": getRawContentType(ContentType.TV_SHOW),
      "overview": overview,
      "releaseDate": releaseDate,
      "homepage": homepage,
      "genres": genres,
      "rating": rating,
      "backdropPath": backdropPath,
      "posterPath": posterPath,
      "voteCount": voteCount,
      "originalTitle": originalTitle,
      "originalCountry": originalCountry,
      "status": status,
      "popularity": popularity
    };
  }

  static TVShowContentModel fromStoredMap(Map map) {
    return TVShowContentModel(
      id: map['id'],
      imdbId: map['imdbId'],
      title: map['title'],
      overview: map['overview'],
      releaseDate: map['releaseDate'],
      homepage: map['homepage'],
      genres: map['genres'],
      rating: map['rating'],
      backdropPath: map['backdropPath'],
      posterPath: map['posterPath'],
      voteCount: map['voteCount'],
      originalTitle: map['originalTitle'],
      originalCountry: map['originalCountry'],
      status: map['status'],
      popularity: map['popularity']
    );
  }

}
