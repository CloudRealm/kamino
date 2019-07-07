import 'package:flutter/material.dart';

class ReviewModel {
  String author;
  String content;
  String url;

  ReviewModel({
    @required this.author,
    @required this.content,
    @required this.url
  });

  static ReviewModel fromJSON(Map json){
    return new ReviewModel(
      author: json['author'],
      content: json['content'],
      url: json['url']
    );
  }
}