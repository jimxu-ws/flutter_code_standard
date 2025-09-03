/// 通知数据模型
class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String? payload;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.payload,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      payload: json['payload'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'payload': payload,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? payload,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      payload: payload ?? this.payload,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }
}

/// 通知类型枚举
enum NotificationType {
  info,
  warning,
  error,
  success,
}

/// 通知请求模型
class NotificationRequest {
  final String title;
  final String body;
  final String? payload;
  final NotificationType? type;
  final DateTime? scheduledTime;

  const NotificationRequest({
    required this.title,
    required this.body,
    this.payload,
    this.type,
    this.scheduledTime,
  });

  factory NotificationRequest.fromJson(Map<String, dynamic> json) {
    return NotificationRequest(
      title: json['title'] as String,
      body: json['body'] as String,
      payload: json['payload'] as String?,
      type: json['type'] != null
          ? NotificationType.values.firstWhere(
              (e) => e.name == json['type'],
              orElse: () => NotificationType.info,
            )
          : null,
      scheduledTime: json['scheduledTime'] != null
          ? DateTime.parse(json['scheduledTime'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
      'payload': payload,
      'type': type?.name,
      'scheduledTime': scheduledTime?.toIso8601String(),
    };
  }
}
