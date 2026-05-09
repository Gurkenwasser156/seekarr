import 'package:seekarr/features/settings/domain/service_key.dart';

enum ServiceSummaryStatus { online, offline }

class ServiceSummary {
  final ServiceKey service;
  final ServiceSummaryStatus status;
  final String host;
  final String? version;
  final int? itemCount;
  final String itemLabel;

  const ServiceSummary({
    required this.service,
    required this.status,
    required this.host,
    required this.version,
    required this.itemCount,
    required this.itemLabel,
  });

  bool get isOnline => status == ServiceSummaryStatus.online;

  String get statusLabel => isOnline ? 'Online' : 'Offline';

  String get versionLabel {
    final serviceVersion = version?.trim();
    if (serviceVersion != null && serviceVersion.isNotEmpty) {
      return serviceVersion.startsWith('v')
          ? serviceVersion
          : 'v$serviceVersion';
    }

    return '${service.apiVersion} API';
  }

  String get countLabel {
    if (!isOnline && itemCount == null) {
      return 'Offline';
    }

    final count = itemCount;
    if (count == null) {
      return 'Summary unavailable';
    }

    final label = count == 1 && itemLabel.endsWith('s')
        ? itemLabel.substring(0, itemLabel.length - 1)
        : itemLabel;
    return '$count $label';
  }
}
