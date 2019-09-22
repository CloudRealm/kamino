import 'package:flutter/material.dart';
import 'package:kamino/models/person.dart';

// CastCrewPersonModel
class CCPersonModel extends PersonModel {
  final String creditId;

  /// For a [CrewMemberModel], role means job.
  /// For a [CastMemberModel], role means character.
  final String role;

  CCPersonModel({
    int id,
    String name,
    String profilePath,
    String gender,
    this.creditId,
    this.role
  }) : super(
    id: id,
    name: name,
    profilePath: profilePath,
    gender: gender
  );
}

class CrewMemberModel extends CCPersonModel {
  final String job;
  final String department;

  CrewMemberModel({
    @required int id,
    @required String name,
    int gender,
    String creditId,
    String profilePath,

    this.job,
    this.department,
  }) : super(
      id: id,
      name: name,
      gender: PersonModel.convertGender(gender),
      creditId: creditId,
      profilePath: profilePath,
      role: job
  );

  static CrewMemberModel fromJSON(Map json){
    return new CrewMemberModel(
      id: json['id'],
      name: json['name'],
      gender: json['gender'],

      creditId: json['credit_id'],
      job: json['job'],
      department: json['department'],
      profilePath: json['profile_path'],
    );
  }
}

class CastMemberModel extends CCPersonModel {
  final int order;
  final int castId;
  final String character;

  CastMemberModel({
    @required int id,
    @required String name,
    int gender,
    String creditId,
    String profilePath,

    this.order,
    this.castId,
    this.character,
  }) : super(
    id: id,
    name: name,
    gender: PersonModel.convertGender(gender),
    creditId: creditId,
    profilePath: profilePath,
    role: character
  );

  static CastMemberModel fromJSON(Map json){
    return new CastMemberModel(
      id: json['id'],
      name: json['name'],
      order: json['order'],
      gender: json['gender'],

      creditId: json['credit_id'],
      castId: json['cast_id'],
      character: json['character'],
      profilePath: json['profile_path']
    );
  }
}