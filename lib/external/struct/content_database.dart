import 'package:flutter/material.dart';
import 'package:kamino/external/ExternalService.dart';

abstract class ContentDatabaseService extends Service {

  ContentDatabaseService(String name, {
    List<ServiceType> types = const [ServiceType.CONTENT_DATABASE],
    bool isPrimaryService
  }) : super(
    name,
    types,
    isPrimaryService: isPrimaryService
  );

  Future<SearchResults> search(BuildContext context, String query, { bool isAutoComplete });

}

class SearchResults {

  final List people;
  final List movies;
  final List shows;

  SearchResults({
    @required this.people,
    @required this.movies,
    @required this.shows
  });

  SearchResults.none()
      : people = [],
        movies = [],
        shows = [];

  @override
  bool operator ==(other) {
    return people == other.people && movies == other.movies && shows == other.shows;
  }

  @override
  int get hashCode => (people.hashCode * 10000) + (movies.hashCode * 100) + shows.hashCode;

}