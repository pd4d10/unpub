// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackageView _$PackageViewFromJson(Map<String, dynamic> json) {
  return PackageView(
      json['name'] as String,
      json['description'] as String,
      (json['tags'] as List)?.map((e) => e as String)?.toList(),
      json['latest'] as String,
      json['updateAt'] == null
          ? null
          : DateTime.parse(json['updateAt'] as String));
}

Map<String, dynamic> _$PackageViewToJson(PackageView instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'tags': instance.tags,
      'latest': instance.latest,
      'updateAt': instance.updateAt?.toIso8601String()
    };
