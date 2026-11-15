import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/equipment.dart';
import '../models/service_request.dart';
import '../models/user.dart';
import 'seed_data.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._();
  DatabaseService._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'servicetrail.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            email TEXT NOT NULL,
            phone TEXT NOT NULL,
            role TEXT NOT NULL,
            specialty TEXT,
            city TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE equipment(
            id TEXT PRIMARY KEY,
            customerId TEXT NOT NULL,
            type TEXT NOT NULL,
            brand TEXT NOT NULL,
            model TEXT NOT NULL,
            installDate TEXT NOT NULL,
            warrantyExpiry TEXT NOT NULL,
            location TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE requests(
            id TEXT PRIMARY KEY,
            equipmentId TEXT NOT NULL,
            customerId TEXT NOT NULL,
            title TEXT NOT NULL,
            issueType TEXT NOT NULL,
            description TEXT NOT NULL,
            priority TEXT NOT NULL,
            status TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            assignedTechnicianId TEXT,
            checkInAt TEXT,
            checkInLat REAL,
            checkInLng REAL,
            checkOutAt TEXT,
            checkOutLat REAL,
            checkOutLng REAL,
            resolvedAt TEXT,
            pendingSync INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE notes(
            id TEXT PRIMARY KEY,
            requestId TEXT NOT NULL,
            authorId TEXT NOT NULL,
            authorName TEXT NOT NULL,
            text TEXT NOT NULL,
            createdAt TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE sync_queue(
            id TEXT PRIMARY KEY,
            entityType TEXT NOT NULL,
            entityId TEXT NOT NULL,
            action TEXT NOT NULL,
            createdAt TEXT NOT NULL
          )
        ''');
        await _seed(db);
      },
    );
  }

  Future<void> _seed(Database db) async {
    for (final u in SeedData.users) {
      await db.insert('users', u.toMap());
    }
    for (final e in SeedData.equipment) {
      await db.insert('equipment', e.toMap());
    }
    for (final r in SeedData.requests) {
      await db.insert('requests', r.toMap());
    }
    for (final n in SeedData.notes) {
      await db.insert('notes', n.toMap());
    }
  }

  // ---- Users ----
  Future<List<AppUser>> getUsersByRole(UserRole role) async {
    final db = await database;
    final rows = await db.query(
      'users',
      where: 'role = ?',
      whereArgs: [role.name],
      orderBy: 'name ASC',
    );
    return rows.map(AppUser.fromMap).toList();
  }

  Future<AppUser?> getUser(String id) async {
    final db = await database;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return AppUser.fromMap(rows.first);
  }

  // ---- Equipment ----
  Future<List<Equipment>> getEquipmentForCustomer(String customerId) async {
    final db = await database;
    final rows = await db.query(
      'equipment',
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'installDate DESC',
    );
    return rows.map(Equipment.fromMap).toList();
  }

  Future<List<Equipment>> getAllEquipment() async {
    final db = await database;
    final rows = await db.query('equipment', orderBy: 'installDate DESC');
    return rows.map(Equipment.fromMap).toList();
  }

  Future<Equipment?> getEquipment(String id) async {
    final db = await database;
    final rows =
        await db.query('equipment', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Equipment.fromMap(rows.first);
  }

  Future<void> insertEquipment(Equipment equipment) async {
    final db = await database;
    await db.insert('equipment', equipment.toMap());
    await _enqueue('equipment', equipment.id, 'create');
  }

  // ---- Requests ----
  Future<List<ServiceRequest>> getAllRequests() async {
    final db = await database;
    final rows = await db.query('requests', orderBy: 'createdAt DESC');
    return rows.map(ServiceRequest.fromMap).toList();
  }

  Future<List<ServiceRequest>> getRequestsForCustomer(
      String customerId) async {
    final db = await database;
    final rows = await db.query(
      'requests',
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'createdAt DESC',
    );
    return rows.map(ServiceRequest.fromMap).toList();
  }

  Future<List<ServiceRequest>> getRequestsForTechnician(
      String technicianId) async {
    final db = await database;
    final rows = await db.query(
      'requests',
      where: 'assignedTechnicianId = ?',
      whereArgs: [technicianId],
      orderBy: 'createdAt DESC',
    );
    return rows.map(ServiceRequest.fromMap).toList();
  }

  Future<ServiceRequest?> getRequest(String id) async {
    final db = await database;
    final rows =
        await db.query('requests', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return ServiceRequest.fromMap(rows.first);
  }

  Future<void> insertRequest(ServiceRequest request) async {
    final db = await database;
    await db.insert('requests', request.toMap());
    await _enqueue('request', request.id, 'create');
  }

  Future<void> updateRequest(ServiceRequest request) async {
    final db = await database;
    await db.update(
      'requests',
      request.toMap(),
      where: 'id = ?',
      whereArgs: [request.id],
    );
    await _enqueue('request', request.id, 'update');
  }

  // ---- Notes ----
  Future<List<WorkNote>> getNotesForRequest(String requestId) async {
    final db = await database;
    final rows = await db.query(
      'notes',
      where: 'requestId = ?',
      whereArgs: [requestId],
      orderBy: 'createdAt ASC',
    );
    return rows.map(WorkNote.fromMap).toList();
  }

  Future<void> insertNote(WorkNote note) async {
    final db = await database;
    await db.insert('notes', note.toMap());
    await _enqueue('note', note.id, 'create');
  }

  // ---- Sync queue (offline simulation) ----
  Future<void> _enqueue(
      String entityType, String entityId, String action) async {
    final db = await database;
    final id = 'sync_${DateTime.now().microsecondsSinceEpoch}';
    await db.insert('sync_queue', {
      'id': id,
      'entityType': entityType,
      'entityId': entityId,
      'action': action,
      'createdAt': DateTime.now().toIso8601String(),
    });
    // Mark the request itself as pending sync where applicable.
    if (entityType == 'request') {
      await db.rawUpdate(
        'UPDATE requests SET pendingSync = 1 WHERE id = ?',
        [entityId],
      );
    }
  }

  Future<int> pendingSyncCount() async {
    final db = await database;
    final result =
        await db.rawQuery('SELECT COUNT(*) AS c FROM sync_queue');
    return (result.first['c'] as int?) ?? 0;
  }

  /// Simulates pushing the offline queue to a server.
  Future<int> syncNow() async {
    final db = await database;
    // Pretend to upload each queued change.
    await Future<void>.delayed(const Duration(seconds: 1));
    final count = await pendingSyncCount();
    await db.delete('sync_queue');
    await db.rawUpdate('UPDATE requests SET pendingSync = 0');
    return count;
  }

  Future<void> close() async {
    final db = _db;
    _db = null;
    await db?.close();
  }
}
