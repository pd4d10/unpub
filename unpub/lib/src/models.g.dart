// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UnpubVersion _$UnpubVersionFromJson(Map<String, dynamic> json) {
  return UnpubVersion(
      json['version'] as String,
      json['pubspec'] as Map<String, dynamic>,
      json['pubspecYaml'] as String,
      json['readme'] as String,
      json['changelog'] as String,
      json['createdAt'] == null
          ? null
          : identity(json['createdAt'] as DateTime));
}

Map<String, dynamic> _$UnpubVersionToJson(UnpubVersion instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('version', instance.version);
  writeNotNull('pubspec', instance.pubspec);
  writeNotNull('pubspecYaml', instance.pubspecYaml);
  writeNotNull('readme', instance.readme);
  writeNotNull('changelog', instance.changelog);
  writeNotNull('createdAt',
      instance.createdAt == null ? null : identity(instance.createdAt));
  return val;
}

UnpubPackage _$UnpubPackageFromJson(Map<String, dynamic> json) {
  return UnpubPackage(
      name: json['name'] as String,
      versions: (json['versions'] as List)
          ?.map((e) => e == null
              ? null
              : UnpubVersion.fromJson(e as Map<String, dynamic>))
          ?.toList(),
      uploaders:
          (json['uploaders'] as List)?.map((e) => e as String)?.toList());
}

Map<String, dynamic> _$UnpubPackageToJson(UnpubPackage instance) =>
    <String, dynamic>{
      'name': instance.name,
      'versions': instance.versions,
      'uploaders': instance.uploaders
    };

webapiListView _$webapiListViewFromJson(Map<String, dynamic> json) {
  return webapiListView(
      json['name'] as String,
      json['description'] as String,
      (json['tags'] as List)?.map((e) => e as String)?.toList(),
      json['latest'] as String,
      json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String));
}

Map<String, dynamic> _$webapiListViewToJson(webapiListView instance) =>
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

DetailView _$DetailViewFromJson(Map<String, dynamic> json) {
  return DetailView(
      json['name'] as String,
      json['version'] as String,
      json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
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
      'createdAt': instance.createdAt?.toIso8601String(),
      'pubspec': instance.pubspec,
      'uploaders': instance.uploaders,
      'readme': instance.readme,
      'changelog': instance.changelog,
      'versions': instance.versions
    };
