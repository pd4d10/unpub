import 'package:json_annotation/json_annotation.dart';
import 'package:yaml/yaml.dart';
import 'package:meta/meta.dart';

part 'models.g.dart';

@JsonSerializable()
class UnpubUploader {
  final String email;
  // final String userId;

  UnpubUploader({
    @required this.email,
    // @required this.userId,
  });

  factory UnpubUploader.fromJson(Map<String, dynamic> map) =>
      _$UnpubUploaderFromJson(map);

  Map<String, dynamic> toJson() => _$UnpubUploaderToJson(this);
}

@JsonSerializable()
class UnpubVersion {
  final String name;
  final String version;
  final String pubspec;

  UnpubVersion({
    @required this.name,
    @required this.version,
    @required this.pubspec,
  });

  factory UnpubVersion.fromJson(Map<String, dynamic> map) =>
      _$UnpubVersionFromJson(map);

  factory UnpubVersion.fromPubspec(String pubspec) {
    var map = loadYaml(pubspec);
    map['pubspec'] = pubspec;
    return _$UnpubVersionFromJson(map);
  }

  Map<String, dynamic> toJson() => _$UnpubVersionToJson(this)..remove('name');
}

@JsonSerializable()
class UnpubPackage {
  final String name;
  final List<UnpubVersion> versions;
  final List<UnpubUploader> uploaders;

  UnpubPackage({
    @required this.name,
    @required this.versions,
    @required this.uploaders,
  });

  factory UnpubPackage.fromJson(Map<String, dynamic> map) =>
      _$UnpubPackageFromJson(map);

  Map<String, dynamic> toJson() => _$UnpubPackageToJson(this);
}
