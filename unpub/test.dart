main(List<String> args) {
  var uri = Uri(
      path: '/webapi/top',
      queryParameters: {'page': 0?.toString(), 'size': 1?.toString()});
  print(uri.toString());
}
