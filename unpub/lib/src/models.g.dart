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
    json['uploader'] as String,
    identity(json['createdAt'] as DateTime),
  );
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
  writeNotNull('uploader', instance.uploader);
  writeNotNull('createdAt', identity(instance.createdAt));
  return val;
}

UnpubPackage _$UnpubPackageFromJson(Map<String, dynamic> json) {
  return UnpubPackage(
    json['name'] as String,
    (json['versions'] as List)
        ?.map((e) =>
            e == null ? null : UnpubVersion.fromJson(e as Map<String, dynamic>))
        ?.toList(),
    json['private'] as bool,
    (json['uploaders'] as List)?.map((e) => e as String)?.toList(),
    identity(json['createdAt'] as DateTime),
    identity(json['updatedAt'] as DateTime),
    json['download'] as int,
  );
}

Map<String, dynamic> _$UnpubPackageToJson(UnpubPackage instance) =>
    <String, dynamic>{
      'name': instance.name,
      'versions': instance.versions,
      'uploaders': instance.uploaders,
      'private': instance.private,
      'createdAt': identity(instance.createdAt),
      'updatedAt': identity(instance.updatedAt),
      'download': instance.download,
    };
