import 'package:seekarr/features/settings/domain/service_key.dart';

ServiceKey? manualImportServiceFromRoute(String? value) {
  final normalized = value?.trim().toLowerCase();
  return ServiceKey.values.where((service) {
    return service != ServiceKey.seerr && service.routeParam == normalized;
  }).firstOrNull;
}

String manualImportLocation(String path, ServiceKey service, {int? targetId}) {
  return Uri(
    path: path,
    queryParameters: {
      'service': service.routeParam,
      if (targetId != null && targetId > 0) 'targetId': '$targetId',
    },
  ).toString();
}
