import 'package:yaml/yaml.dart';

convertYaml(dynamic value) {
  if (value is YamlMap) {
    return value
        .cast<String, dynamic>()
        .map((k, v) => MapEntry(k, convertYaml(v)));
  }
  if (value is YamlList) {
    return value.map((e) => convertYaml(e)).toList();
  }
  return value;
}

Map<String, dynamic> loadYamlAsMap(dynamic value) {
  var yamlMap = loadYaml(value) as YamlMap;
  return convertYaml(yamlMap).cast<String, dynamic>();
}

List<String> getPackageTags(Map<String, dynamic> pubspec) {
  // TODO: web and other tags
  if (pubspec['flutter'] != null) {
    return ['flutter'];
  } else {
    return ['flutter', 'web', 'other'];
  }
}
