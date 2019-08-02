import 'package:flutter/material.dart';

// CastCrewPersonModel
class CCPersonModel {
  final int id;
  final String name;
  final String profilePath;
  final int gender;
  final String creditId;

  /// For a [CrewMemberModel], role means job.
  /// For a [CastMemberModel], role means character.
  final String role;

  CCPersonModel({
    @required this.id,
    @required this.name,
    this.profilePath,
    this.gender,
    this.creditId,
    this.role
  });
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
      gender: gender,
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
    gender: gender,
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