import 'package:flutter/material.dart';

class PersonModel {
  final int id;
  final String name;
  final String profilePath;
  final int gender;

  PersonModel({
    @required this.id,
    @required this.name,
    @required this.profilePath,
    @required this.gender
  });

  static PersonModel fromJSON(Map json){
    return new PersonModel(
      id: json['id'],
      name: json['name'],
      profilePath: json['profile_path'],
      gender: json['gender']
    );
  }
}