import 'package:kamino/models/content/content.dart';
import 'package:kamino/models/content/movie.dart';
import 'package:kamino/models/content/tv_show.dart';
import 'package:meta/meta.dart';

class ContentListModel {

  final int id;
  String name;
  String backdrop;
  String poster;
  String description;
  String creatorName;
  bool public;
  List<ContentModel> content;
  int revenue;
  double averageRating;
  int runtime;

  bool fullyLoaded;
  int totalPages;

  int items;
  /// This is the greatest page index of the list that has been loaded.
  /// e.g. if only the first page was loaded, this will be 0.
  int loadedUntil;

  Function(ContentListModel, int page) _loadNextPage;
  bool get canLoadNextPage => _loadNextPage != null && !fullyLoaded;

  Future<void> loadNextPage () async {
    this.loadedUntil++;

    if(_loadNextPage != null) await _loadNextPage(this, loadedUntil);
    this.fullyLoaded = loadedUntil >= totalPages;
  }

  ContentListModel({
    @required this.id,
    this.name,
    this.backdrop,
    this.poster,
    this.description,
    this.creatorName,
    this.public,
    this.content,
    @required this.fullyLoaded,
    @required this.totalPages,
    this.revenue,
    this.averageRating,
    this.runtime,
    @required this.items,
    this.loadedUntil,

    Function(ContentListModel, int page) loadNextPage
  }) : this._loadNextPage = loadNextPage;

  static ContentListModel fromJSON(Map json, { Function(ContentListModel, int page) loadNextPage }){
    return new ContentListModel(
      id: json["id"],
      name: json["name"],
      backdrop: json["backdrop_path"],
      poster: json["poster_path"],
      description: json["description"],
      creatorName: json["created_by"] != null ? json["created_by"]["name"] : null,
      public: json["public"],
      content: json["stored"] == null
          ? (json["results"] != null ? (json["results"] as List).map((entry) => entry["media_type"] == "movie"
            ? MovieContentModel.fromJSON(entry)
            : TVShowContentModel.fromJSON(entry)).toList() : null
            )
          : ((json["stored"] as List).map((entry) => ContentModel.fromStoredMap(entry))).toList(),
      totalPages: json["total_pages"],
      fullyLoaded: json["fully_loaded"] != null ? json["fully_loaded"] : false,

      revenue: json["revenue"] != null ? json["revenue"] : null,
      averageRating: json["average_rating"] != null ? json["average_rating"] : null,
      runtime: json["runtime"] != null ? json["runtime"] : null,
      items: json["total_results"] != null ? json["total_results"] : null,
      loadedUntil: json["loaded_pages"] != null ? json["loaded_pages"] : 1,

      loadNextPage: loadNextPage
    );
  }

  Map toMap(){
    return {
      "id": id,
      "name": name,
      "backdrop_path": backdrop,
      "poster_path": poster,
      "description": description,
      "created_by": {
        "name": creatorName
      },
      "public": public,
      "stored": content != null ? content.map((ContentModel model) => model.toStoredMap()).toList() : [],
      "total_pages": totalPages,
      "fullyLoaded": fullyLoaded,
      "revenue": revenue,
      "average_rating": averageRating,
      "runtime": runtime,
      "total_results": items,
      "loaded_pages": loadedUntil
    };
  }

}