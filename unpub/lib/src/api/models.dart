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
