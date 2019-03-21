import 'package:flutter/material.dart';

/*  CONTENT TYPE DEFINITIONS  */
enum ContentType { MOVIE, TV_SHOW }
String getOverviewContentTypeName(ContentType type){
  switch(type) {
    case ContentType.MOVIE:
      return "Movie";
    case ContentType.TV_SHOW:
      return "TV Show";
    default:
      return "Unknown";
  }
}

class ContentModel {
  final int id;
  final ContentType contentType;

  // Content Information
  final String title;
  final String overview;
  final String releaseDate; // For TV shows this is the first release date.
  final String homepage;

  // Content Classification
  final List genres;
  final double rating;
  final int voteCount;

  // Content Art.
  final String backdropPath;
  final String posterPath;

  // Watch information
  double progress;
  String lastWatched;

  ContentModel({
    @required this.id,
    @required this.title,
    @required this.contentType,
    this.overview,
    this.releaseDate,
    this.homepage,
    this.genres,
    this.rating,
    this.backdropPath,
    this.posterPath,
    this.voteCount,
    this.progress,
    this.lastWatched
  });
}
