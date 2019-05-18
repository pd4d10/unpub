// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UnpubAuthor _$UnpubAuthorFromJson(Map<String, dynamic> json) {
  return UnpubAuthor(
      name: json['name'] as String, email: json['email'] as String);
}

Map<String, dynamic> _$UnpubAuthorToJson(UnpubAuthor instance) =>
    <String, dynamic>{'name': instance.name, 'email': instance.email};

UnpubVersion _$UnpubVersionFromJson(Map<String, dynamic> json) {
  return UnpubVersion(
      version: json['version'] as String,
      pubspecYaml: json['pubspecYaml'] as String);
}

Map<String, dynamic> _$UnpubVersionToJson(UnpubVersion instance) =>
    <String, dynamic>{
      'version': instance.version,
      'pubspecYaml': instance.pubspecYaml
    };

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
