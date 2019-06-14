import 'package:json_annotation/json_annotation.dart';

part 'models.g.dart';

@JsonSerializable()
class PackageView {
  String name;
  String description;
  List<String> tags;
  String latest;
  DateTime updateAt;

  PackageView(
      this.name, this.description, this.tags, this.latest, this.updateAt);

  factory PackageView.fromJson(Map<String, dynamic> map) =>
      _$PackageViewFromJson(map);

  Map<String, dynamic> toJson() => _$PackageViewToJson(this);
}

@JsonSerializable()
class DetailViewVersion {
  String version;
  DateTime createAt;

  DetailViewVersion(this.version, this.createAt);

  factory DetailViewVersion.fromJson(Map<String, dynamic> map) =>
      _$DetailViewVersionFromJson(map);

  Map<String, dynamic> toJson() => _$DetailViewVersionToJson(this);
}

@JsonSerializable()
class DetailView {
  String name;
  String version;
  DateTime createAt;
  Map<String, dynamic> pubspec;
  List<String> uploaders;
  String readme;
  String changelog;
  List<DetailViewVersion> versions;

  DetailView(this.name, this.version, this.createAt, this.pubspec,
      this.uploaders, this.readme, this.changelog, this.versions);

  factory DetailView.fromJson(Map<String, dynamic> map) =>
      _$DetailViewFromJson(map);

  Map<String, dynamic> toJson() => _$DetailViewToJson(this);
}
