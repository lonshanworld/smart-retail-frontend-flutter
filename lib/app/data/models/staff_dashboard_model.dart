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
    print('🔍 [STAFF MODEL] Parsing StaffDashboardSummaryResponse...');
    print('   Raw JSON: $json');
    print('   JSON type: ${json.runtimeType}');
    print('   Keys: ${json.keys.toList()}');

    // Handle recentActivities safely
    List<ActivityItemDTO> activities = [];
    if (json['recentActivities'] != null) {
      print(
        '   recentActivities type: ${json['recentActivities'].runtimeType}',
      );
      print('   recentActivities value: ${json['recentActivities']}');

      final activitiesData = json['recentActivities'];
      if (activitiesData is List) {
        print(
          '   ✅ recentActivities is a List with ${activitiesData.length} items',
        );
        activities = activitiesData
            .map((item) {
              try {
                print(
                  '   Parsing activity item: $item (type: ${item.runtimeType})',
                );
                return ActivityItemDTO.fromJson(item as Map<String, dynamic>);
              } catch (e) {
                print('   ❌ Error parsing activity item: $e');
                return null;
              }
            })
            .whereType<ActivityItemDTO>()
            .toList();
      } else {
        print('   ❌ recentActivities is NOT a List!');
      }
    } else {
      print('   ⚠️  recentActivities is null');
    }

    final result = StaffDashboardSummaryResponse(
      assignedShopName: json['assignedShopName'] as String? ?? 'Unknown Shop',
      salesToday: (json['salesToday'] as num?)?.toDouble() ?? 0.0,
      transactionsToday: (json['transactionsToday'] as num?)?.toInt() ?? 0,
      recentActivities: activities,
    );

    print('✅ [STAFF MODEL] Parsed successfully');
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
