import 'package:json_annotation/json_annotation.dart';

part 'answer.g.dart';

@JsonSerializable()
class Answer {
  final String answer;
  final int point;
  Answer({
    required this.answer,
    required this.point,
  });

  Map<String, dynamic> toJson() => _$AnswerToJson(this);

  factory Answer.fromJson(Map<String, dynamic> map) => _$AnswerFromJson(map);
}
