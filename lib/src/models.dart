import 'package:json_annotation/json_annotation.dart';
import 'package:unpub/src/utils.dart';
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
class UnpubVersion {
  final String version;
  final Map<String, dynamic> pubspec;
  final String pubspecYaml;
  final String readme;
  final String changelog;

  UnpubVersion(
    this.version,
    this.pubspec,
    this.pubspecYaml,
    this.readme,
    this.changelog,
  );

  factory UnpubVersion.fromJson(Map<String, dynamic> map) =>
      _$UnpubVersionFromJson(map);

  factory UnpubVersion.fromPubspec(
      String pubspecYaml, String readme, String changelog) {
    var pubspec = loadYamlAsMap(pubspecYaml);

    return UnpubVersion(
      pubspec['version'] as String,
      pubspec,
      pubspecYaml,
      readme,
      changelog,
    );
  }

  Map<String, dynamic> toJson() => _$UnpubVersionToJson(this);
}

@JsonSerializable()
class UnpubPackage {
  final String name;
  final List<UnpubVersion> versions;
  final List<String> uploaders;

  UnpubPackage({
    @required this.name,
    @required this.versions,
    @required this.uploaders,
  });

  factory UnpubPackage.fromJson(Map<String, dynamic> map) =>
      _$UnpubPackageFromJson(map);

  Map<String, dynamic> toJson() => _$UnpubPackageToJson(this);
}
