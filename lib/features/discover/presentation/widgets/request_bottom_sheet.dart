import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seekarr/features/discover/data/jellyseerr_service.dart';

/// Bottom sheet for selecting quality profile and submitting request to Jellyseerr.
///
/// This widget is used from the DiscoverDetailScreen to allow users to select
/// a server, quality profile, and root folder before submitting a media request.
class RequestBottomSheet extends ConsumerStatefulWidget {
  final int mediaId;
  final String mediaType;
  final VoidCallback onRequestComplete;

  const RequestBottomSheet({
    super.key,
    required this.mediaId,
    required this.mediaType,
    required this.onRequestComplete,
  });

  @override
  ConsumerState<RequestBottomSheet> createState() => _RequestBottomSheetState();
}

class _RequestBottomSheetState extends ConsumerState<RequestBottomSheet> {
  List<Map<String, dynamic>> _servers = [];
  List<dynamic> _profiles = [];
  List<dynamic> _rootFolders = [];
  int? _selectedServerId;
  int? _selectedProfileId;
  String? _selectedRootFolder;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadServers();
  }

  Future<void> _loadServers() async {
    try {
      final service = ref.read(jellyseerrServiceProvider);
      final servers = widget.mediaType == 'movie'
          ? await service.getRadarrServers()
          : await service.getSonarrServers();

      if (servers.isEmpty) {
        setState(() {
          _error =
              'No ${widget.mediaType == 'movie' ? 'Radarr' : 'Sonarr'} servers configured in Jellyseerr';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _servers = servers;
        _selectedServerId = servers.first['id'] as int?;
      });

      if (_selectedServerId != null) {
        await _loadProfiles(_selectedServerId!);
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load servers: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProfiles(int serverId) async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(jellyseerrServiceProvider);
      final data = widget.mediaType == 'movie'
          ? await service.getRadarrProfiles(serverId)
          : await service.getSonarrProfiles(serverId);

      final profiles = data['profiles'] as List<dynamic>? ?? [];
      final rootFolders = data['rootFolders'] as List<dynamic>? ?? [];

      // Get the activeProfileId from the selected server
      final selectedServer = _servers.firstWhere(
        (s) => s['id'] == serverId,
        orElse: () => <String, dynamic>{},
      );
      final activeProfileId = selectedServer['activeProfileId'] as int?;
      final activeRootFolder = selectedServer['activeDirectory'] as String?;

      // Select the active profile, or fall back to first
      int? defaultProfileId;
      if (activeProfileId != null &&
          profiles.any((p) => p['id'] == activeProfileId)) {
        defaultProfileId = activeProfileId;
      } else if (profiles.isNotEmpty) {
        defaultProfileId = profiles.first['id'] as int?;
      }

      // Select the active root folder, or fall back to first
      String? defaultRootFolder;
      if (activeRootFolder != null &&
          rootFolders.any((f) => f['path'] == activeRootFolder)) {
        defaultRootFolder = activeRootFolder;
      } else if (rootFolders.isNotEmpty) {
        defaultRootFolder = rootFolders.first['path'] as String?;
      }

      setState(() {
        _profiles = profiles;
        _rootFolders = rootFolders;
        _selectedProfileId = defaultProfileId;
        _selectedRootFolder = defaultRootFolder;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load profiles: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _submitRequest() async {
    if (_selectedProfileId == null) return;

    setState(() => _isSubmitting = true);
    try {
      final service = ref.read(jellyseerrServiceProvider);
      await service.createRequest(
        mediaType: widget.mediaType,
        mediaId: widget.mediaId,
        profileId: _selectedProfileId,
        rootFolder: _selectedRootFolder,
        serverId: _selectedServerId,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onRequestComplete();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Request failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Request ${widget.mediaType == 'movie' ? 'Movie' : 'TV Show'}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),

          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red))
          else ...[
            // Server selector (if multiple)
            if (_servers.length > 1) ...[
              const Text(
                'Server',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _selectedServerId,
                items: _servers
                    .map(
                      (s) => DropdownMenuItem(
                        value: s['id'] as int,
                        child: Text(s['name'] ?? 'Server'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedServerId = value);
                    _loadProfiles(value);
                  }
                },
              ),
              const SizedBox(height: 16),
            ],

            // Quality profile
            const Text(
              'Quality Profile',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _selectedProfileId,
              items: _profiles
                  .map(
                    (p) => DropdownMenuItem(
                      value: p['id'] as int,
                      child: Text(p['name'] ?? 'Profile'),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedProfileId = value),
            ),
            const SizedBox(height: 16),

            // Root folder
            if (_rootFolders.isNotEmpty) ...[
              const Text(
                'Root Folder',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedRootFolder,
                items: _rootFolders
                    .map(
                      (f) => DropdownMenuItem(
                        value: f['path'] as String?,
                        child: Text(f['path'] ?? 'Folder'),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedRootFolder = value),
              ),
              const SizedBox(height: 24),
            ],

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRequest,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit Request'),
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
