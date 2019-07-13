import 'package:kamino/models/content/content.dart';
import 'package:kamino/models/crew.dart';
import 'package:kamino/models/review.dart';
import 'package:meta/meta.dart';

class MovieContentModel extends ContentModel {

  final double runtime;

  MovieContentModel({
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
    List cast,
    List crew,
    List<MovieContentModel> recommendations,
    List videos,
    List reviews,
    int totalReviews,

    // Movie parameters
    this.runtime
  }) : super( // Call the parent constructor...
    id: id,
    imdbId: imdbId,
    title: title,
    alternativeTitles: alternativeTitles,
    contentType: ContentType.MOVIE,
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

  static MovieContentModel fromJSON(Map json){
    Map credits = json['credits'] != null ? json['credits'] : {'cast': null, 'crew': null};
    List videos = json['videos'] != null ? json['videos']['results'] : null;
    List<MovieContentModel> recommendations = json['recommendations'] != null
      ? (json['recommendations']['results'] as List).map(
          (element) => MovieContentModel.fromJSON(element)
        ).toList()
      : null;
    List<LocalizedTitleModel> alternativeTitles = json['alternative_titles'] != null
        ? (json['alternative_titles']['titles'] as List).map(
            (element) => LocalizedTitleModel.fromJSON(element)
    ).toList() : null;
    int totalReviews = json['reviews'] != null ? json['reviews']['total_results'] : null;
    List reviews = json['reviews'] != null ? json['reviews']['results'] : null;

    return new MovieContentModel(
      // Inherited properties.
      // (Copy-paste these to other models.)
      id: json["id"],
      imdbId: json["imdb_id"],
      title: json["title"],
      overview: json["overview"],
      releaseDate: json["release_date"],
      homepage: json["homepage"],
      genres: json["genres"],
      rating: json["vote_average"] != null ? json["vote_average"].toDouble() : -1.0,
      backdropPath: json["backdrop_path"],
      posterPath: json["poster_path"],
      voteCount: json.containsKey("vote_count") ? json["vote_count"] : 0,
      cast: credits['cast'] != null ? (credits['cast'] as List).map((entry) => CastMemberModel.fromJSON(entry)).toList() : null,
      crew: credits['crew'] != null ? (credits['crew'] as List).map((entry) => CrewMemberModel.fromJSON(entry)).toList() : null,
      recommendations: recommendations,
      videos: videos,
      alternativeTitles: alternativeTitles,
      originalCountry: json['production_countries'] != null && json['production_countries'].length > 0
          ? json['production_countries'][0]['iso_3166_1'] : null,
      originalTitle: json['original_title'],
      totalReviews: totalReviews != null ? totalReviews : null,
      reviews: reviews != null ? reviews.map((entry) => ReviewModel.fromJSON(entry)).toList() : null,

      // Object-specific properties.
      runtime: json["runtime"] != null ? json["runtime"].toDouble() : null
    );
  }

  @override
  Map toStoredMap() {
    return {
      "id": id,
      "imdbId": imdbId,
      "title": title,
      "contentType": getRawContentType(ContentType.MOVIE),
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
      "runtime": runtime
    };
  }

  static MovieContentModel fromStoredMap(Map map) {
    return MovieContentModel(
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
      runtime: map['runtime']
    );
  }
}
