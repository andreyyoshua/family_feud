import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import 'package:family_hundred/question.dart';

part 'section.g.dart';

enum Difficulty {
  @JsonValue(1)
  easy,
  @JsonValue(2)
  medium,
  @JsonValue(3)
  hard
}

@JsonSerializable()
class Section {
  final Difficulty difficulty;
  final List<Question> questions;

  Section({
    required this.difficulty,
    required this.questions,
  });
  

  Map<String, dynamic> toJson() => _$SectionToJson(this);

  factory Section.fromJson(Map<String, dynamic> source) => _$SectionFromJson(source);
}
