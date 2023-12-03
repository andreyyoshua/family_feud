// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Group _$GroupFromJson(Map<String, dynamic> json) => Group(
      name: json['name'] as String,
      members:
          (json['members'] as List<dynamic>).map((e) => e as String).toList(),
      isWinner: json['isWinner'] as bool?,
      totalScore: json['totalScore'] as int,
    );

Map<String, dynamic> _$GroupToJson(Group instance) => <String, dynamic>{
      'name': instance.name,
      'members': instance.members,
      'isWinner': instance.isWinner,
      'totalScore': instance.totalScore,
    };
