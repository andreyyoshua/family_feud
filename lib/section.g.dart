// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'section.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Section _$SectionFromJson(Map<String, dynamic> json) => Section(
      difficulty: $enumDecode(_$DifficultyEnumMap, json['difficulty']),
      questions: (json['questions'] as List<dynamic>)
          .map((e) => Question.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SectionToJson(Section instance) => <String, dynamic>{
      'difficulty': _$DifficultyEnumMap[instance.difficulty]!,
      'questions': instance.questions,
    };

const _$DifficultyEnumMap = {
  Difficulty.easy: 1,
  Difficulty.medium: 2,
  Difficulty.hard: 3,
};
