// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UnpubUploader _$UnpubUploaderFromJson(Map<String, dynamic> json) {
  return UnpubUploader(email: json['email'] as String);
}

Map<String, dynamic> _$UnpubUploaderToJson(UnpubUploader instance) =>
    <String, dynamic>{'email': instance.email};

UnpubVersion _$UnpubVersionFromJson(Map<String, dynamic> json) {
  return UnpubVersion(
      version: json['version'] as String, pubspec: json['pubspec'] as String);
}

Map<String, dynamic> _$UnpubVersionToJson(UnpubVersion instance) =>
    <String, dynamic>{'version': instance.version, 'pubspec': instance.pubspec};

UnpubPackage _$UnpubPackageFromJson(Map<String, dynamic> json) {
  return UnpubPackage(
      name: json['name'] as String,
      versions: (json['versions'] as List)
          ?.map((e) => e == null
              ? null
              : UnpubVersion.fromJson(e as Map<String, dynamic>))
          ?.toList(),
      uploaders: (json['uploaders'] as List)
          ?.map((e) => e == null
              ? null
              : UnpubUploader.fromJson(e as Map<String, dynamic>))
          ?.toList());
}

Map<String, dynamic> _$UnpubPackageToJson(UnpubPackage instance) =>
    <String, dynamic>{
      'name': instance.name,
      'versions': instance.versions,
      'uploaders': instance.uploaders
    };
