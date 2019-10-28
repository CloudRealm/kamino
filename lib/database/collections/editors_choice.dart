import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:kamino/database/database.dart';
import 'package:kamino/external/ExternalService.dart';
import 'package:kamino/external/api/tmdb.dart';
import 'package:kamino/models/content/content.dart';
import 'package:kamino/models/content/movie.dart';
import 'package:kamino/models/content/tv_show.dart';
import 'package:objectdb/objectdb.dart';

class EditorsChoiceDocument {

  int id;
  ContentType type;
  String title;
  String comment;
  String poster;

  EditorsChoiceDocument({
    @required this.id,
    @required this.type,
    @required this.title,
    @required this.comment,
    @required this.poster
  });

  EditorsChoiceDocument.fromJSON(Map data){
    this.id = data['id'];
    this.type = getContentTypeFromRawType(data['type']);
    this.title = data['title'];
    this.comment = data['comment'];
    this.poster = data['poster'];
  }

  Map<String, dynamic> toMap(){
    return {
      "id": id,
      "type": getRawContentType(type),
      "title": title,
      "comment": comment,
      "poster": poster
    };
  }

  ContentModel toContentModel(){
    switch(type){
      case ContentType.TV_SHOW:
        return TVShowContentModel(
            id: id,
            title: title,
            posterPath: poster
        );
      case ContentType.MOVIE:
        return MovieContentModel(
            id: id,
            title: title,
            posterPath: poster
        );

      default:
        return null;
    }
  }

  Future<ContentModel> loadFullContent(BuildContext context) async {
    return await Service.get<TMDB>().getContentInfo(context, type, id);
  }

}

class EditorsChoiceCollection {

  static Future<void> updateStore(BuildContext context, { bool force = false }) async {
    // Check if database needs to be updated
    ObjectDB database = await Database.open();
    bool canAvoidCheck = (await database.find({
      "docType": "editorsChoice",
      Op.gte: {
        // If older than 24 hours, we should get Editor's Choice again.
        "timestamp": new DateTime.now().subtract(Duration(days: 1)).millisecondsSinceEpoch
      }
    })).length > 0;
    if(canAvoidCheck) return;

    // Fetch comments and content data from TMDB.
    var editorsChoiceComments = jsonDecode((await Service.get<TMDB>().getList(context, 109986, raw: true)))['comments'] as Map;
    List<ContentModel> editorsChoiceContentList = (await Service.get<TMDB>().getList(context, 109986, loadFully: true)).content;

    // Map the data to EditorsChoice objects.
    List<EditorsChoiceDocument> editorsChoice = new List();
    for(ContentModel editorsChoiceContent in editorsChoiceContentList){
      editorsChoice.add(new EditorsChoiceDocument(
          id: editorsChoiceContent.id,
          title: editorsChoiceContent.title,
          poster: editorsChoiceContent.posterPath,
          type: editorsChoiceContent.contentType,
          comment: editorsChoiceComments['${getRawContentType(editorsChoiceContent.contentType)}:${editorsChoiceContent.id}']
      ));
    }

    // Map the EditorsChoice objects to documents.
    List<Map> editorsChoiceDocuments = editorsChoice.map(
            (EditorsChoiceDocument choice) => choice.toMap()
    ).toList();

    // Write data to database.
    await database.insert({
      "docType": "editorsChoice",
      "data": editorsChoiceDocuments,
      "timestamp": new DateTime.now().millisecondsSinceEpoch
    });
    database.close();

  }

  static Future<EditorsChoiceDocument> loadRandom() async {
    ObjectDB database = await Database.open();
    List<Map> results = await database.find({
      "docType": "editorsChoice"
    });
    if(results.length < 1) return null;

    List editorsChoiceDocuments = results[0]["data"];

    // Randomly select a choice from the Editor's Choice list.
    Map selectedChoice = editorsChoiceDocuments[Random().nextInt(editorsChoiceDocuments.length)];
    return EditorsChoiceDocument.fromJSON(selectedChoice);
  }

  static Future<EditorsChoiceDocument> select(int tmdbID) async {
    ObjectDB database = await Database.open();

    List<Map> results = await database.find({
      "docType": "editorsChoice"
    });
    if(results.length < 1) return null;

    Map editorsChoice;
    for(Map result in results[0]["data"]){
      if(result['id'] == tmdbID) editorsChoice = result;
    }

    if(editorsChoice == null) return null;
    return EditorsChoiceDocument.fromJSON(editorsChoice);
  }

}