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

  bool fullyLoaded;
  int totalPages;

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
    @required this.totalPages
  });

  static ContentListModel fromJSON(Map json){
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
      fullyLoaded: json["fully_loaded"] != null ? json["fully_loaded"] : false
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
      "fullyLoaded": fullyLoaded
    };
  }

}