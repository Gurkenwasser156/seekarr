import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shared state and helpers for loading quality profiles in detail screens.
mixin QualityProfileMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  List<Map<String, dynamic>> qualityProfiles = [];
  String? currentProfileName;
  int? currentProfileId;
  bool _profilesRequested = false;
  int? _boundProfileId;

  void ensureQualityProfiles({
    required int? profileId,
    required Future<List<Map<String, dynamic>>> Function() fetchProfiles,
  }) {
    if (!_profilesRequested) {
      _profilesRequested = true;
      _boundProfileId = profileId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        loadQualityProfiles(
          fetchProfiles: fetchProfiles,
          initialProfileId: profileId,
        );
      });
      return;
    }

    if (qualityProfiles.isNotEmpty && _boundProfileId != profileId) {
      _boundProfileId = profileId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        setState(() {
          currentProfileId = profileId;
          currentProfileName = getProfileName(profileId);
        });
      });
    }
  }

  Future<void> loadQualityProfiles({
    required Future<List<Map<String, dynamic>>> Function() fetchProfiles,
    required int? initialProfileId,
  }) async {
    try {
      final profiles = await fetchProfiles();
      if (!mounted) return;

      setState(() {
        qualityProfiles = profiles;
        currentProfileId = initialProfileId;
        currentProfileName = getProfileName(initialProfileId);
      });
    } catch (_) {
      // Ignore profile loading errors — consistent with existing behavior.
    }
  }

  String? getProfileName(int? profileId) {
    if (profileId == null) return null;

    final profile = qualityProfiles
        .where((p) => p['id'] == profileId)
        .firstOrNull;
    return profile?['name'] as String?;
  }

  void updateProfileState(int profileId) {
    setState(() {
      currentProfileId = profileId;
      currentProfileName = getProfileName(profileId);
    });
  }
}
