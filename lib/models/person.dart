import 'package:flutter/material.dart';
import 'package:kamino/models/content/content.dart';
import 'package:kamino/models/content/movie.dart';
import 'package:kamino/models/content/tv_show.dart';

class PersonModel {
  final int id;
  final String name;
  final String profilePath;
  final String gender;
  //final List<ContentModel> knownFor;
  final List<String> alsoKnownAs;

  final String knownForDepartment;
  final String birthday;
  final String deathday;

  final String biography;
  final String placeOfBirth;
  final String homepage;

  final double popularity;

  PersonModel({
    @required this.id,
    @required this.name,
    @required this.profilePath,

    @required this.gender,
    //@required this.knownFor,
    this.alsoKnownAs,

    this.knownForDepartment,
    this.birthday,
    this.deathday,

    this.biography,
    this.placeOfBirth,
    this.homepage,

    this.popularity
  });

  List<String> get aliases => this.alsoKnownAs;

  static PersonModel fromJSON(Map json, { bool alsoConvertKnownFor = false }){
    /*List<ContentModel> knownFor = new List();
    if(alsoConvertKnownFor) (json['known_for']).forEach((entry){
      if(getContentTypeFromRawType(entry['media_type']) == ContentType.MOVIE){
        knownFor.add(MovieContentModel.fromJSON(entry));
      }

      if(getContentTypeFromRawType(entry['media_type']) == ContentType.TV_SHOW){
        knownFor.add(TVShowContentModel.fromJSON(entry));
      }
    });*/

    return new PersonModel(
      id: json['id'],
      name: json['name'],
      profilePath: json['profile_path'],

      gender: json['gender'] is int ? convertGender(json['gender']) : json['gender'],
      //knownFor: knownFor,
      alsoKnownAs: json['also_known_as'] != null ? json['also_known_as'].cast<String>() as List<String> : [],

      knownForDepartment: json['known_for_department'],
      birthday: json['birthday'],
      deathday: json['deathday'],

      biography: json['biography'],
      placeOfBirth: json['place_of_birth'],
      homepage: json['homepage'],

      popularity: json['popularity']
    );
  }

  ///
  /// This currently converts gender according solely to TMDB's API, however
  /// in future, if we use another provider silly enough to implement gender
  /// as a numerical system, this should allow a provider to be passed to it.
  ///
  static String convertGender(int numericalGender){
    switch(numericalGender){
      case 1:
        return "female";
      case 2:
        return "male";

      case 0:
      default:
        return null;
    }
  }
}