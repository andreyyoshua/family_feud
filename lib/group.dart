import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'group.g.dart';

@JsonSerializable()
class Group {
  final String name;
  final List<String> members;
  bool? isWinner;
  int totalScore;
  Group({
    required this.name,
    required this.members,
    this.isWinner,
    required this.totalScore,
  });

  String toJson() => json.encode(_$GroupToJson(this));

  factory Group.fromJson(Map<String, dynamic> source) => _$GroupFromJson(source);
}
