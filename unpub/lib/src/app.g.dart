// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app.dart';

// **************************************************************************
// ShelfRouterGenerator
// **************************************************************************

Router _$AppRouter(App service) {
  final router = Router();
  router.add('GET', '/api/packages/<name>', service.getVersions);
  router.add(
      'GET', '/api/packages/<name>/versions/<version>', service.getVersion);
  router.add(
      'GET', '/packages/<name>/versions/<version>.tar.gz', service.download);
  router.add('GET', '/api/packages/versions/new', service.getUploadUrl);
  router.add('POST', '/api/packages/versions/newUpload', service.upload);
  router.add(
      'GET', '/api/packages/versions/newUploadFinish', service.uploadFinish);
  router.add('POST', '/api/packages/<name>/uploaders', service.addUploader);
  router.add('DELETE', '/api/packages/<name>/uploaders/<email>',
      service.removeUploader);
  router.add('GET', '/webapi/packages', service.getPackages);
  router.add(
      'GET', '/webapi/package/<name>/<version>', service.getPackageDetail);
  router.add('GET', '/', service.indexHtml);
  router.add('GET', '/packages', service.indexHtml);
  router.add('GET', '/packages/<name>', service.indexHtml);
  router.add('GET', '/packages/<name>/versions/<version>', service.indexHtml);
  router.add('GET', '/main.dart.js', service.mainDartJs);
  router.add('GET', '/badge/<type>/<name>', service.badge);
  return router;
}
