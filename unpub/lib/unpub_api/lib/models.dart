import 'package:json_annotation/json_annotation.dart';

part 'models.g.dart';

@JsonSerializable()
class ListApi {
  int count;
  List<ListApiPackage> packages;

  ListApi(this.count, this.packages);

  factory ListApi.fromJson(Map<String, dynamic> map) => _$ListApiFromJson(map);
  Map<String, dynamic> toJson() => _$ListApiToJson(this);
}

@JsonSerializable()
class ListApiPackage {
  String name;
  String description;
  List<String> tags;
  String latest;
  DateTime updatedAt;

  ListApiPackage(
      this.name, this.description, this.tags, this.latest, this.updatedAt);

  factory ListApiPackage.fromJson(Map<String, dynamic> map) =>
      _$ListApiPackageFromJson(map);
  Map<String, dynamic> toJson() => _$ListApiPackageToJson(this);
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
class WebapiDetailView {
  String name;
  String version;
  String description;
  String homepage;
  List<String> uploaders;
  DateTime createdAt;
  final String readme;
  final String changelog;
  List<DetailViewVersion> versions;
  List<String> authors;
  List<String> dependencies;
  List<String> tags;

  WebapiDetailView(
      this.name,
      this.version,
      this.description,
      this.homepage,
      this.uploaders,
      this.createdAt,
      this.readme,
      this.changelog,
      this.versions,
      this.authors,
      this.dependencies,
      this.tags);

  factory WebapiDetailView.fromJson(Map<String, dynamic> map) =>
      _$WebapiDetailViewFromJson(map);

  Map<String, dynamic> toJson() => _$WebapiDetailViewToJson(this);
}
