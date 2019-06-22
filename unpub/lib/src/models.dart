import 'package:json_annotation/json_annotation.dart';
import 'package:unpub/src/utils.dart';
import 'package:meta/meta.dart';

part 'models.g.dart';

DateTime identity(DateTime x) => x;

@JsonSerializable(includeIfNull: false)
class UnpubVersion {
  final String version;
  final Map<String, dynamic> pubspec;
  final String pubspecYaml;
  final String readme;
  final String changelog;

  @JsonKey(fromJson: identity, toJson: identity)
  final DateTime createdAt;

  UnpubVersion(
    this.version,
    this.pubspec,
    this.pubspecYaml,
    this.readme,
    this.changelog,
    this.createdAt,
  );

  factory UnpubVersion.fromJson(Map<String, dynamic> map) =>
      _$UnpubVersionFromJson(map);

  factory UnpubVersion.fromTarball(
      String pubspecYaml, String readme, String changelog) {
    var pubspec = loadYamlAsMap(pubspecYaml);

    return UnpubVersion(
      pubspec['version'] as String,
      pubspec,
      pubspecYaml,
      readme,
      changelog,
      DateTime.now(),
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

@JsonSerializable()
class webapiListView {
  String name;
  String description;
  List<String> tags;
  String latest;
  DateTime updatedAt;

  webapiListView(
      this.name, this.description, this.tags, this.latest, this.updatedAt);

  factory webapiListView.fromJson(Map<String, dynamic> map) =>
      _$webapiListViewFromJson(map);

  Map<String, dynamic> toJson() => _$webapiListViewToJson(this);
}

@JsonSerializable()
class DetailViewVersion {
  String version;
  DateTime createdAt;

  DetailViewVersion(this.version, this.createdAt);

  factory DetailViewVersion.fromJson(Map<String, dynamic> map) =>
      _$DetailViewVersionFromJson(map);

  Map<String, dynamic> toJson() => _$DetailViewVersionToJson(this);
}

@JsonSerializable()
class DetailView {
  String name;
  String version;
  DateTime createdAt;
  Map<String, dynamic> pubspec;
  List<String> uploaders;
  String readme;
  String changelog;
  List<DetailViewVersion> versions;

  DetailView(this.name, this.version, this.createdAt, this.pubspec,
      this.uploaders, this.readme, this.changelog, this.versions);

  factory DetailView.fromJson(Map<String, dynamic> map) =>
      _$DetailViewFromJson(map);

  Map<String, dynamic> toJson() => _$DetailViewToJson(this);
}
