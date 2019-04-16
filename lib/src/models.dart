import 'package:json_annotation/json_annotation.dart';
import 'package:yaml/yaml.dart';
import 'package:meta/meta.dart';

part 'models.g.dart';

@JsonSerializable()
class UnpubAuthor {
  final String name;
  final String email;

  UnpubAuthor({@required this.name, @required this.email});

  factory UnpubAuthor.fromJson(Map<String, dynamic> map) =>
      _$UnpubAuthorFromJson(map);

  Map<String, dynamic> toJson() => _$UnpubAuthorToJson(this);
}

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
  final String version;
  final String pubspec;

  UnpubVersion({
    @required this.version,
    @required this.pubspec,
  });

  factory UnpubVersion.fromJson(Map<String, dynamic> map) =>
      _$UnpubVersionFromJson(map);

  factory UnpubVersion.fromPubspec(String pubspec) {
    var map = loadYaml(pubspec);
    return _$UnpubVersionFromJson(
        Map<String, dynamic>.from(map)..addAll({'pubspec': pubspec}));
  }

  Map<String, dynamic> toJson() => _$UnpubVersionToJson(this);
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
