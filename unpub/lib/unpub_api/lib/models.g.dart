// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WebapiListView _$WebapiListViewFromJson(Map<String, dynamic> json) {
  return WebapiListView(
      json['name'] as String,
      json['description'] as String,
      (json['tags'] as List)?.map((e) => e as String)?.toList(),
      json['latest'] as String,
      json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String));
}

Map<String, dynamic> _$WebapiListViewToJson(WebapiListView instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'tags': instance.tags,
      'latest': instance.latest,
      'updatedAt': instance.updatedAt?.toIso8601String()
    };

DetailViewVersion _$DetailViewVersionFromJson(Map<String, dynamic> json) {
  return DetailViewVersion(
      json['version'] as String,
      json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String));
}

Map<String, dynamic> _$DetailViewVersionToJson(DetailViewVersion instance) =>
    <String, dynamic>{
      'version': instance.version,
      'createdAt': instance.createdAt?.toIso8601String()
    };

WebapiDetailView _$WebapiDetailViewFromJson(Map<String, dynamic> json) {
  return WebapiDetailView(
      json['name'] as String,
      json['version'] as String,
      json['description'] as String,
      json['homepage'] as String,
      (json['uploaders'] as List)?.map((e) => e as String)?.toList(),
      json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      json['readme'] as String,
      json['changelog'] as String,
      (json['versions'] as List)
          ?.map((e) => e == null
              ? null
              : DetailViewVersion.fromJson(e as Map<String, dynamic>))
          ?.toList(),
      (json['authors'] as List)?.map((e) => e as String)?.toList(),
      (json['dependencies'] as List)?.map((e) => e as String)?.toList());
}

Map<String, dynamic> _$WebapiDetailViewToJson(WebapiDetailView instance) =>
    <String, dynamic>{
      'name': instance.name,
      'version': instance.version,
      'description': instance.description,
      'homepage': instance.homepage,
      'uploaders': instance.uploaders,
      'createdAt': instance.createdAt?.toIso8601String(),
      'readme': instance.readme,
      'changelog': instance.changelog,
      'versions': instance.versions,
      'authors': instance.authors,
      'dependencies': instance.dependencies
    };
