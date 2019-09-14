import 'package:flutter/material.dart';
import 'package:kamino/external/ExternalService.dart';
import 'package:kamino/models/person.dart';

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
  Future<PersonModel> getPerson(BuildContext context, int id);

}

class SearchResults {

  final String query;
  final List people;
  final List movies;
  final List shows;

  SearchResults({
    @required this.query,
    @required this.people,
    @required this.movies,
    @required this.shows
  });

  SearchResults.none({ String query })
      : query = query,
        people = [],
        movies = [],
        shows = [];

  @override
  bool operator ==(other) {
    return query == other.query;
  }

  @override
  int get hashCode => query.hashCode;

}