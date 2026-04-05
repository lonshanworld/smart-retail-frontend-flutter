import 'package:smart_retail/app/utils/app_logger.dart';
class StaffDashboardSummaryResponse {
  final String assignedShopName;
  final double salesToday;
  final int transactionsToday;
  final List<ActivityItemDTO> recentActivities;

  StaffDashboardSummaryResponse({
    required this.assignedShopName,
    required this.salesToday,
    required this.transactionsToday,
    required this.recentActivities,
  });

  factory StaffDashboardSummaryResponse.fromJson(Map<String, dynamic> json) {
    getLogger('app').info('ðŸ” [STAFF MODEL] Parsing StaffDashboardSummaryResponse...');
    getLogger('app').info('   Raw JSON: $json');
    getLogger('app').info('   JSON type: ${json.runtimeType}');
    getLogger('app').info('   Keys: ${json.keys.toList()}');

    final activities = <ActivityItemDTO>[];
    final rawActivities = json['recentActivities'];
    if (rawActivities is List) {
      getLogger('app').info(
        '   âœ… recentActivities is a List with ${rawActivities.length} items',
      );
      for (final item in rawActivities) {
        try {
          getLogger('app').info(
            '   Parsing activity item: $item (type: ${item.runtimeType})',
          );
          if (item is ActivityItemDTO) {
            activities.add(item);
          } else if (item is Map) {
            activities.add(
              ActivityItemDTO.fromJson(Map<String, dynamic>.from(item)),
            );
          } else {
            getLogger('app').info(
              '   âš ï¸  Skipping unsupported activity item type: ${item.runtimeType}',
            );
          }
        } catch (e) {
          getLogger('app').info('   âŒ Error parsing activity item: $e');
        }
      }
    } else if (rawActivities != null) {
      getLogger('app').info('   âŒ recentActivities is NOT a List!');
    } else {
      getLogger('app').info('   âš ï¸  recentActivities is null');
    }

    final result = StaffDashboardSummaryResponse(
      assignedShopName: json['assignedShopName'] as String? ?? 'Unknown Shop',
      salesToday: (json['salesToday'] as num?)?.toDouble() ?? 0.0,
      transactionsToday: (json['transactionsToday'] as num?)?.toInt() ?? 0,
      recentActivities: activities,
    );

    getLogger('app').info('âœ… [STAFF MODEL] Parsed successfully');
    return result;
  }
}

class ActivityItemDTO {
  final String type;
  final String details;
  final DateTime timestamp;
  final String? relatedId;

  ActivityItemDTO({
    required this.type,
    required this.details,
    required this.timestamp,
    this.relatedId,
  });

  factory ActivityItemDTO.fromJson(Map<String, dynamic> json) {
    return ActivityItemDTO(
      type: json['type'] as String? ?? 'unknown',
      details: json['details'] as String? ?? 'No details',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      relatedId: json['relatedId'] as String?,
    );
  }
}

