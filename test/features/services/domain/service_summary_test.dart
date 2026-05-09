import 'package:flutter_test/flutter_test.dart';

import 'package:seekarr/features/services/domain/service_summary.dart';
import 'package:seekarr/features/settings/domain/service_key.dart';

void main() {
  group('ServiceSummary', () {
    test('formats online status, version, and plural count labels', () {
      const summary = ServiceSummary(
        service: ServiceKey.radarr,
        status: ServiceSummaryStatus.online,
        host: 'radarr.local:7878',
        version: '5.4.6',
        itemCount: 312,
        itemLabel: 'movies',
      );

      expect(summary.isOnline, isTrue);
      expect(summary.statusLabel, 'Online');
      expect(summary.versionLabel, 'v5.4.6');
      expect(summary.countLabel, '312 movies');
    });

    test('singularizes simple plural item labels for one item', () {
      const summary = ServiceSummary(
        service: ServiceKey.seerr,
        status: ServiceSummaryStatus.online,
        host: 'seerr.local:5055',
        version: 'v2.5.1',
        itemCount: 1,
        itemLabel: 'requests',
      );

      expect(summary.countLabel, '1 request');
      expect(summary.versionLabel, 'v2.5.1');
    });

    test('shows offline only when an offline summary has no count', () {
      const offlineWithoutCount = ServiceSummary(
        service: ServiceKey.lidarr,
        status: ServiceSummaryStatus.offline,
        host: 'lidarr.local:8686',
        version: null,
        itemCount: null,
        itemLabel: 'artists',
      );
      const offlineWithCount = ServiceSummary(
        service: ServiceKey.lidarr,
        status: ServiceSummaryStatus.offline,
        host: 'lidarr.local:8686',
        version: null,
        itemCount: 144,
        itemLabel: 'artists',
      );

      expect(offlineWithoutCount.countLabel, 'Offline');
      expect(offlineWithCount.countLabel, '144 artists');
      expect(offlineWithoutCount.versionLabel, 'v1 API');
    });
  });
}
