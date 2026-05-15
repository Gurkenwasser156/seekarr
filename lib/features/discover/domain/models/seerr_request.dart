enum RequestStatus {
  pendingApproval,
  approved,
  declined,
  failed,
  completed,
  unknown;

  static RequestStatus fromCode(dynamic value) {
    int? intValue;
    if (value is int) {
      intValue = value;
    } else if (value is String) {
      intValue = int.tryParse(value);
    }

    switch (intValue) {
      case 1:
        return RequestStatus.pendingApproval;
      case 2:
        return RequestStatus.approved;
      case 3:
        return RequestStatus.declined;
      case 4:
        return RequestStatus.failed;
      case 5:
        return RequestStatus.completed;
      default:
        return RequestStatus.unknown;
    }
  }
}

enum MediaAvailability {
  unknown,
  pending,
  processing,
  partiallyAvailable,
  available,
  deleted;

  static MediaAvailability fromCode(dynamic value) {
    int? intValue;
    if (value is int) {
      intValue = value;
    } else if (value is String) {
      intValue = int.tryParse(value);
    }

    switch (intValue) {
      case 1:
        return MediaAvailability.unknown;
      case 2:
        return MediaAvailability.pending;
      case 3:
        return MediaAvailability.processing;
      case 4:
        return MediaAvailability.partiallyAvailable;
      case 5:
        return MediaAvailability.available;
      case 6:
        return MediaAvailability.deleted;
      default:
        return MediaAvailability.unknown;
    }
  }

  String get label {
    switch (this) {
      case MediaAvailability.unknown:
        return 'Unknown';
      case MediaAvailability.pending:
        return 'Pending';
      case MediaAvailability.processing:
        return 'Processing';
      case MediaAvailability.partiallyAvailable:
        return 'Partially Available';
      case MediaAvailability.available:
        return 'Available';
      case MediaAvailability.deleted:
        return 'Deleted';
    }
  }
}

class SeerrRequest {
  final int id;
  final RequestStatus status;
  final RequestMedia? media;
  final String createdAt;
  final int? profileId;
  final String? profileName;
  final List<RequestSeason>? seasons;
  final String type; // 'movie' or 'tv'
  final bool is4k;
  final int? serverId;
  final bool canRemove;
  final RequestedBy? requestedBy;

  const SeerrRequest({
    required this.id,
    required this.status,
    this.media,
    required this.createdAt,
    this.profileId,
    this.profileName,
    this.seasons,
    required this.type,
    this.is4k = false,
    this.serverId,
    this.canRemove = false,
    this.requestedBy,
  });

  factory SeerrRequest.fromJson(Map<String, dynamic> json) {
    return SeerrRequest(
      id: json['id'] ?? 0,
      status: RequestStatus.fromCode(json['status']),
      media: json['media'] != null
          ? RequestMedia.fromJson(json['media'])
          : null,
      createdAt: json['createdAt'] ?? '',
      profileId: json['profileId'],
      profileName: json['profileName'],
      seasons: (json['seasons'] as List<dynamic>?)
          ?.map((e) => RequestSeason.fromJson(e))
          .toList(),
      type: json['type'] ?? 'movie',
      is4k: _parseBool(json['is4k']),
      serverId: json['serverId'],
      canRemove: _parseBool(json['canRemove']),
      requestedBy: json['requestedBy'] != null
          ? RequestedBy.fromJson(json['requestedBy'])
          : null,
    );
  }

  // Allow enriching with new media (e.g. with title/poster metadata)
  SeerrRequest copyWith({RequestMedia? media}) {
    return SeerrRequest(
      id: id,
      status: status,
      media: media ?? this.media,
      createdAt: createdAt,
      profileId: profileId,
      profileName: profileName,
      seasons: seasons,
      type: type,
      is4k: is4k,
      serverId: serverId,
      canRemove: canRemove,
      requestedBy: requestedBy,
    );
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    return false;
  }
}

enum SeerrRequestDisplayKind {
  pending,
  approved,
  available,
  partiallyAvailable,
  processing,
  deleted,
  declined,
  failed,
  completed,
  unknown,
}

typedef SeerrRequestDisplayStatus = ({
  String label,
  SeerrRequestDisplayKind kind,
});

extension SeerrRequestDisplayStatusX on SeerrRequest {
  SeerrRequestDisplayStatus get displayStatus {
    final mediaStatus = media?.status;

    if (mediaStatus != null) {
      switch (mediaStatus) {
        case MediaAvailability.available:
          return (label: 'Available', kind: SeerrRequestDisplayKind.available);
        case MediaAvailability.partiallyAvailable:
          return (
            label: 'Partially Available',
            kind: SeerrRequestDisplayKind.partiallyAvailable,
          );
        case MediaAvailability.processing:
          return (
            label: 'Processing',
            kind: SeerrRequestDisplayKind.processing,
          );
        case MediaAvailability.deleted:
          return (label: 'Deleted', kind: SeerrRequestDisplayKind.deleted);
        case MediaAvailability.pending:
          return (label: 'Pending', kind: SeerrRequestDisplayKind.pending);
        case MediaAvailability.unknown:
          break;
      }
    }

    switch (status) {
      case RequestStatus.pendingApproval:
        return (label: 'Pending', kind: SeerrRequestDisplayKind.pending);
      case RequestStatus.approved:
        return (label: 'Approved', kind: SeerrRequestDisplayKind.approved);
      case RequestStatus.declined:
        return (label: 'Declined', kind: SeerrRequestDisplayKind.declined);
      case RequestStatus.failed:
        return (label: 'Failed', kind: SeerrRequestDisplayKind.failed);
      case RequestStatus.completed:
        return (label: 'Completed', kind: SeerrRequestDisplayKind.completed);
      case RequestStatus.unknown:
        return (label: 'Unknown', kind: SeerrRequestDisplayKind.unknown);
    }
  }
}

class RequestMedia {
  final int? id; // Seerr internal media ID
  final String? title;
  final String? year;
  final int? tmdbId;
  final int? tvdbId;
  final MediaAvailability status;
  final String? externalServiceSlug;
  final int? externalServiceId; // Radarr/Sonarr ID
  final String? mediaType;
  final String? posterPath;

  const RequestMedia({
    this.id,
    this.title,
    this.year,
    this.tmdbId,
    this.tvdbId,
    this.status = MediaAvailability.unknown,
    this.externalServiceSlug,
    this.externalServiceId,
    this.mediaType,
    this.posterPath,
  });

  factory RequestMedia.fromJson(Map<String, dynamic> json) {
    // Basic fields
    final id = json['id'] as int?;
    final tmdbId = json['tmdbId'];
    final tvdbId = json['tvdbId'];
    final status = MediaAvailability.fromCode(json['status']);
    final slug = json['externalServiceSlug']?.toString();
    final externalServiceId = json['externalServiceId'] as int?;
    final mediaType = json['mediaType']?.toString();

    // Initial title attempt (unlikely to be here based on JSON)
    String? title = json['title'] ?? json['name'];
    String? year = json['year']?.toString() ?? json['releaseDate']?.toString();
    final posterPath =
        json['posterPath']?.toString() ?? json['poster_path']?.toString();

    return RequestMedia(
      id: id,
      title: title, // Can be null, service will fetch
      year: year,
      tmdbId: tmdbId,
      tvdbId: tvdbId,
      status: status,
      externalServiceSlug: slug,
      externalServiceId: externalServiceId,
      mediaType: mediaType,
      posterPath: posterPath,
    );
  }

  RequestMedia copyWith({String? title, String? year, String? posterPath}) {
    return RequestMedia(
      id: id,
      title: title ?? this.title,
      year: year ?? this.year,
      tmdbId: tmdbId,
      tvdbId: tvdbId,
      status: status,
      externalServiceSlug: externalServiceSlug,
      externalServiceId: externalServiceId,
      mediaType: mediaType,
      posterPath: posterPath ?? this.posterPath,
    );
  }
}

class RequestSeason {
  final int seasonNumber;
  final String status;

  const RequestSeason({required this.seasonNumber, required this.status});

  factory RequestSeason.fromJson(Map<String, dynamic> json) {
    return RequestSeason(
      seasonNumber: json['seasonNumber'] ?? 0,
      status: json['status']?.toString() ?? 'Unknown',
    );
  }
}

/// Represents the user who made a request.
class RequestedBy {
  final int id;
  final String displayName;
  final String? avatar;

  const RequestedBy({required this.id, required this.displayName, this.avatar});

  factory RequestedBy.fromJson(Map<String, dynamic> json) {
    return RequestedBy(
      id: json['id'] ?? 0,
      displayName: json['displayName'] ?? json['username'] ?? 'Unknown',
      avatar: json['avatar']?.toString(),
    );
  }
}
