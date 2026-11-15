enum RequestStatus { submitted, assigned, inProgress, resolved }

extension RequestStatusX on RequestStatus {
  String get label {
    switch (this) {
      case RequestStatus.submitted:
        return 'Submitted';
      case RequestStatus.assigned:
        return 'Assigned';
      case RequestStatus.inProgress:
        return 'In Progress';
      case RequestStatus.resolved:
        return 'Resolved';
    }
  }

  static RequestStatus fromString(String value) {
    return RequestStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => RequestStatus.submitted,
    );
  }
}

enum Priority { low, medium, high, urgent }

extension PriorityX on Priority {
  String get label {
    switch (this) {
      case Priority.low:
        return 'Low';
      case Priority.medium:
        return 'Medium';
      case Priority.high:
        return 'High';
      case Priority.urgent:
        return 'Urgent';
    }
  }

  static Priority fromString(String value) {
    return Priority.values.firstWhere(
      (p) => p.name == value,
      orElse: () => Priority.medium,
    );
  }
}

class ServiceRequest {
  final String id;
  final String equipmentId;
  final String customerId;
  final String title;
  final String issueType;
  final String description;
  final Priority priority;
  final RequestStatus status;
  final DateTime createdAt;
  final String? assignedTechnicianId;
  final DateTime? checkInAt;
  final double? checkInLat;
  final double? checkInLng;
  final DateTime? checkOutAt;
  final double? checkOutLat;
  final double? checkOutLng;
  final DateTime? resolvedAt;
  final int pendingSync;

  const ServiceRequest({
    required this.id,
    required this.equipmentId,
    required this.customerId,
    required this.title,
    required this.issueType,
    required this.description,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.assignedTechnicianId,
    this.checkInAt,
    this.checkInLat,
    this.checkInLng,
    this.checkOutAt,
    this.checkOutLat,
    this.checkOutLng,
    this.resolvedAt,
    this.pendingSync = 0,
  });

  ServiceRequest copyWith({
    RequestStatus? status,
    String? assignedTechnicianId,
    DateTime? checkInAt,
    double? checkInLat,
    double? checkInLng,
    DateTime? checkOutAt,
    double? checkOutLat,
    double? checkOutLng,
    DateTime? resolvedAt,
    int? pendingSync,
  }) {
    return ServiceRequest(
      id: id,
      equipmentId: equipmentId,
      customerId: customerId,
      title: title,
      issueType: issueType,
      description: description,
      priority: priority,
      status: status ?? this.status,
      createdAt: createdAt,
      assignedTechnicianId:
          assignedTechnicianId ?? this.assignedTechnicianId,
      checkInAt: checkInAt ?? this.checkInAt,
      checkInLat: checkInLat ?? this.checkInLat,
      checkInLng: checkInLng ?? this.checkInLng,
      checkOutAt: checkOutAt ?? this.checkOutAt,
      checkOutLat: checkOutLat ?? this.checkOutLat,
      checkOutLng: checkOutLng ?? this.checkOutLng,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      pendingSync: pendingSync ?? this.pendingSync,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'equipmentId': equipmentId,
        'customerId': customerId,
        'title': title,
        'issueType': issueType,
        'description': description,
        'priority': priority.name,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'assignedTechnicianId': assignedTechnicianId,
        'checkInAt': checkInAt?.toIso8601String(),
        'checkInLat': checkInLat,
        'checkInLng': checkInLng,
        'checkOutAt': checkOutAt?.toIso8601String(),
        'checkOutLat': checkOutLat,
        'checkOutLng': checkOutLng,
        'resolvedAt': resolvedAt?.toIso8601String(),
        'pendingSync': pendingSync,
      };

  factory ServiceRequest.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic v) =>
        v == null ? null : DateTime.parse(v as String);
    double? parseDouble(dynamic v) =>
        v == null ? null : (v as num).toDouble();

    return ServiceRequest(
      id: map['id'] as String,
      equipmentId: map['equipmentId'] as String,
      customerId: map['customerId'] as String,
      title: map['title'] as String,
      issueType: map['issueType'] as String,
      description: map['description'] as String,
      priority: PriorityX.fromString(map['priority'] as String),
      status: RequestStatusX.fromString(map['status'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
      assignedTechnicianId: map['assignedTechnicianId'] as String?,
      checkInAt: parseDate(map['checkInAt']),
      checkInLat: parseDouble(map['checkInLat']),
      checkInLng: parseDouble(map['checkInLng']),
      checkOutAt: parseDate(map['checkOutAt']),
      checkOutLat: parseDouble(map['checkOutLat']),
      checkOutLng: parseDouble(map['checkOutLng']),
      resolvedAt: parseDate(map['resolvedAt']),
      pendingSync: (map['pendingSync'] as int?) ?? 0,
    );
  }

  /// Duration from creation to resolution, in hours.
  double? get resolutionHours {
    if (resolvedAt == null) return null;
    return resolvedAt!.difference(createdAt).inMinutes / 60.0;
  }
}

class WorkNote {
  final String id;
  final String requestId;
  final String authorId;
  final String authorName;
  final String text;
  final DateTime createdAt;

  const WorkNote({
    required this.id,
    required this.requestId,
    required this.authorId,
    required this.authorName,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'requestId': requestId,
        'authorId': authorId,
        'authorName': authorName,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };

  factory WorkNote.fromMap(Map<String, dynamic> map) => WorkNote(
        id: map['id'] as String,
        requestId: map['requestId'] as String,
        authorId: map['authorId'] as String,
        authorName: map['authorName'] as String,
        text: map['text'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
