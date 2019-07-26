import 'package:json_annotation/json_annotation.dart';

part 'models.g.dart';

DateTime identity(DateTime x) => x;

@JsonSerializable(includeIfNull: false)
class UnpubVersion {
  final String version;
  final Map<String, dynamic> pubspec;
  final String pubspecYaml;
  final String readme;
  final String changelog;
  final String uploader;

  @JsonKey(fromJson: identity, toJson: identity)
  final DateTime createdAt;

  UnpubVersion(
    this.version,
    this.pubspec,
    this.pubspecYaml,
    this.readme,
    this.changelog,
    this.uploader,
    this.createdAt,
  );

  factory UnpubVersion.fromJson(Map<String, dynamic> map) =>
      _$UnpubVersionFromJson(map);

  Map<String, dynamic> toJson() => _$UnpubVersionToJson(this);
}

@JsonSerializable()
class UnpubPackage {
  final String name;
  final List<UnpubVersion> versions;
  final List<String> uploaders;
  final bool private;

  @JsonKey(fromJson: identity, toJson: identity)
  final DateTime createdAt;

  @JsonKey(fromJson: identity, toJson: identity)
  final DateTime updatedAt;

  final int download;

  UnpubPackage(
    this.name,
    this.versions,
    this.private,
    this.uploaders,
    this.createdAt,
    this.updatedAt,
    this.download,
  );

  factory UnpubPackage.fromJson(Map<String, dynamic> map) =>
      _$UnpubPackageFromJson(map);
}
