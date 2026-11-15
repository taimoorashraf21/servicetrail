import 'package:flutter/foundation.dart';

import '../models/equipment.dart';
import '../models/service_request.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';

class DataProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  List<Equipment> equipment = [];
  List<ServiceRequest> requests = [];
  List<AppUser> technicians = [];
  List<AppUser> customers = [];
  Map<String, List<WorkNote>> notesByRequest = {};
  int pendingSyncCount = 0;
  bool loading = false;

  Future<void> loadAll() async {
    loading = true;
    notifyListeners();
    technicians =
        await _db.getUsersByRole(UserRole.technician);
    customers = await _db.getUsersByRole(UserRole.customer);
    equipment = await _db.getAllEquipment();
    requests = await _db.getAllRequests();
    pendingSyncCount = await _db.pendingSyncCount();
    loading = false;
    notifyListeners();
  }

  Future<void> refresh() => loadAll();

  List<Equipment> equipmentFor(String customerId) =>
      equipment.where((e) => e.customerId == customerId).toList();

  List<ServiceRequest> requestsForCustomer(String customerId) =>
      requests.where((r) => r.customerId == customerId).toList();

  List<ServiceRequest> requestsForTechnician(String technicianId) =>
      requests
          .where((r) => r.assignedTechnicianId == technicianId)
          .toList();

  Equipment? equipmentById(String id) {
    try {
      return equipment.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  AppUser? userById(String id) {
    final all = [...technicians, ...customers];
    try {
      return all.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  ServiceRequest? requestById(String id) {
    try {
      return requests.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<WorkNote>> loadNotes(String requestId) async {
    final notes = await _db.getNotesForRequest(requestId);
    notesByRequest[requestId] = notes;
    notifyListeners();
    return notes;
  }

  Future<void> addEquipment(Equipment item) async {
    await _db.insertEquipment(item);
    equipment.insert(0, item);
    pendingSyncCount = await _db.pendingSyncCount();
    notifyListeners();
  }

  Future<ServiceRequest> addRequest(ServiceRequest request) async {
    await _db.insertRequest(request);
    requests.insert(0, request);
    pendingSyncCount = await _db.pendingSyncCount();
    notifyListeners();
    return request;
  }

  Future<void> assignTechnician(
      ServiceRequest request, String technicianId) async {
    final updated = request.copyWith(
      assignedTechnicianId: technicianId,
      status: RequestStatus.assigned,
      pendingSync: 1,
    );
    await _db.updateRequest(updated);
    _replace(updated);
    pendingSyncCount = await _db.pendingSyncCount();
    notifyListeners();
  }

  Future<void> updateStatus(
      ServiceRequest request, RequestStatus status) async {
    final updated = request.copyWith(
      status: status,
      resolvedAt:
          status == RequestStatus.resolved ? DateTime.now() : request.resolvedAt,
      pendingSync: 1,
    );
    await _db.updateRequest(updated);
    _replace(updated);
    pendingSyncCount = await _db.pendingSyncCount();
    notifyListeners();
  }

  /// Returns an error message when GPS was unavailable, null on success.
  Future<String?> checkIn(ServiceRequest request) async {
    final loc = await LocationService.getCurrentPosition();
    final updated = request.copyWith(
      checkInAt: DateTime.now(),
      checkInLat: loc.latitude,
      checkInLng: loc.longitude,
      pendingSync: 1,
    );
    await _db.updateRequest(updated);
    _replace(updated);
    pendingSyncCount = await _db.pendingSyncCount();
    notifyListeners();
    return loc.error;
  }

  /// Returns an error message when GPS was unavailable, null on success.
  Future<String?> checkOut(ServiceRequest request) async {
    final loc = await LocationService.getCurrentPosition();
    final updated = request.copyWith(
      checkOutAt: DateTime.now(),
      checkOutLat: loc.latitude,
      checkOutLng: loc.longitude,
      pendingSync: 1,
    );
    await _db.updateRequest(updated);
    _replace(updated);
    pendingSyncCount = await _db.pendingSyncCount();
    notifyListeners();
    return loc.error;
  }

  Future<void> addNote(
      ServiceRequest request, AppUser author, String text) async {
    final note = WorkNote(
      id: 'note_${DateTime.now().microsecondsSinceEpoch}',
      requestId: request.id,
      authorId: author.id,
      authorName: author.name,
      text: text,
      createdAt: DateTime.now(),
    );
    await _db.insertNote(note);
    final list = notesByRequest[request.id] ?? [];
    notesByRequest[request.id] = [...list, note];
    pendingSyncCount = await _db.pendingSyncCount();
    notifyListeners();
  }

  /// Simulates syncing the offline queue to the server.
  Future<int> syncNow() async {
    final count = await _db.syncNow();
    // Reload so pendingSync flags clear in memory.
    requests = await _db.getAllRequests();
    pendingSyncCount = 0;
    notifyListeners();
    return count;
  }

  void _replace(ServiceRequest updated) {
    final i = requests.indexWhere((r) => r.id == updated.id);
    if (i >= 0) {
      requests[i] = updated;
    } else {
      requests.insert(0, updated);
    }
  }

  // ---- Admin KPIs / analytics helpers ----
  int get openJobs =>
      requests.where((r) => r.status != RequestStatus.resolved).length;

  int get resolvedThisMonth {
    final now = DateTime.now();
    return requests
        .where((r) =>
            r.status == RequestStatus.resolved &&
            r.resolvedAt != null &&
            r.resolvedAt!.year == now.year &&
            r.resolvedAt!.month == now.month)
        .length;
  }

  double get avgResolutionHours {
    final done = requests
        .where((r) => r.resolutionHours != null)
        .map((r) => r.resolutionHours!);
    if (done.isEmpty) return 0;
    return done.reduce((a, b) => a + b) / done.length;
  }

  Map<RequestStatus, int> get jobsByStatus {
    final map = {for (final s in RequestStatus.values) s: 0};
    for (final r in requests) {
      map[r.status] = (map[r.status] ?? 0) + 1;
    }
    return map;
  }

  Map<String, int> get jobsByType {
    final map = <String, int>{};
    for (final r in requests) {
      map[r.issueType] = (map[r.issueType] ?? 0) + 1;
    }
    return map;
  }

  /// Resolved jobs per month for the last 6 months (oldest -> newest).
  List<MapEntry<String, int>> get monthlyCompletions {
    final now = DateTime.now();
    final months = <MapEntry<String, int>>[];
    const labels = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    for (int i = 5; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i, 1);
      final count = requests
          .where((r) =>
              r.status == RequestStatus.resolved &&
              r.resolvedAt != null &&
              r.resolvedAt!.year == m.year &&
              r.resolvedAt!.month == m.month)
          .length;
      months.add(MapEntry(labels[m.month - 1], count));
    }
    return months;
  }
}
