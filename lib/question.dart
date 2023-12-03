import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import 'package:family_hundred/answer.dart';

part 'question.g.dart';

@JsonSerializable()
class Question {
  final String question;
  final List<Answer> answers;
  
  Question({
    required this.question,
    required this.answers,
  });

  Map<String, dynamic> toJson() => _$QuestionToJson(this);

  factory Question.fromJson(Map<String, dynamic> map) => _$QuestionFromJson(map);
}
