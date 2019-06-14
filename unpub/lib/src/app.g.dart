// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app.dart';

// **************************************************************************
// ShelfRouterGenerator
// **************************************************************************

Router _$UnpubAppRouter(UnpubApp service) {
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
  router.add('GET', '/webapi/top', service.getTopPackages);
  router.add('GET', '/webapi/detail/<name>', service.getPackageDetail);
  return router;
}
