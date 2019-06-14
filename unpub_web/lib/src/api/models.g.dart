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

DetailViewVersion _$DetailViewVersionFromJson(Map<String, dynamic> json) {
  return DetailViewVersion(
      json['version'] as String,
      json['createAt'] == null
          ? null
          : DateTime.parse(json['createAt'] as String));
}

Map<String, dynamic> _$DetailViewVersionToJson(DetailViewVersion instance) =>
    <String, dynamic>{
      'version': instance.version,
      'createAt': instance.createAt?.toIso8601String()
    };

DetailView _$DetailViewFromJson(Map<String, dynamic> json) {
  return DetailView(
      json['name'] as String,
      json['version'] as String,
      json['createAt'] == null
          ? null
          : DateTime.parse(json['createAt'] as String),
      json['pubspec'] as Map<String, dynamic>,
      (json['uploaders'] as List)?.map((e) => e as String)?.toList(),
      json['readme'] as String,
      json['changelog'] as String,
      (json['versions'] as List)
          ?.map((e) => e == null
              ? null
              : DetailViewVersion.fromJson(e as Map<String, dynamic>))
          ?.toList());
}

Map<String, dynamic> _$DetailViewToJson(DetailView instance) =>
    <String, dynamic>{
      'name': instance.name,
      'version': instance.version,
      'createAt': instance.createAt?.toIso8601String(),
      'pubspec': instance.pubspec,
      'uploaders': instance.uploaders,
      'readme': instance.readme,
      'changelog': instance.changelog,
      'versions': instance.versions
    };
