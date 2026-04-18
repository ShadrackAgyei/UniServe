import 'package:sqflite/sqflite.dart';
import '../models/campus_issue.dart';
import '../models/lost_found_item.dart';
import '../models/campus_notification.dart';
import '../models/emergency_contact.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = '$dbPath/uniserve_cache.db';

    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE campus_issues(
            id INTEGER PRIMARY KEY,
            user_id TEXT,
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            category TEXT NOT NULL,
            reporter_name TEXT,
            image_url TEXT,
            status TEXT NOT NULL DEFAULT 'Pending',
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE lost_found_items(
            id INTEGER PRIMARY KEY,
            user_id TEXT,
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            type TEXT NOT NULL,
            reporter_name TEXT,
            image_url TEXT,
            location TEXT NOT NULL,
            contact_info TEXT NOT NULL,
            is_resolved INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE notifications(
            id INTEGER PRIMARY KEY,
            title TEXT NOT NULL,
            message TEXT NOT NULL,
            category TEXT NOT NULL,
            created_at TEXT NOT NULL,
            is_read INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE emergency_contacts(
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            phone TEXT NOT NULL,
            department TEXT NOT NULL,
            icon TEXT NOT NULL,
            sort_order INTEGER DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE campus_issues ADD COLUMN reporter_name TEXT',
          );
          await db.execute(
            'ALTER TABLE lost_found_items ADD COLUMN reporter_name TEXT',
          );
        }
      },
    );
  }

  // ── Campus Issues Cache ─────────────────────────────

  Future<void> cacheIssues(List<CampusIssue> issues) async {
    final db = await database;
    await db.delete('campus_issues');
    for (final issue in issues) {
      await db.insert('campus_issues', issue.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<List<CampusIssue>> getCachedIssues() async {
    final db = await database;
    final maps = await db.query('campus_issues', orderBy: 'created_at DESC');
    return maps.map((m) => CampusIssue.fromMap(m)).toList();
  }

  // ── Lost & Found Cache ──────────────────────────────

  Future<void> cacheLostFoundItems(List<LostFoundItem> items) async {
    final db = await database;
    await db.delete('lost_found_items');
    for (final item in items) {
      await db.insert('lost_found_items', item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<List<LostFoundItem>> getCachedLostFoundItems() async {
    final db = await database;
    final maps = await db.query('lost_found_items', orderBy: 'created_at DESC');
    return maps.map((m) => LostFoundItem.fromMap(m)).toList();
  }

  // ── Notifications Cache ─────────────────────────────

  Future<void> cacheNotifications(List<CampusNotification> notifications) async {
    final db = await database;
    await db.delete('notifications');
    for (final n in notifications) {
      await db.insert('notifications', n.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<List<CampusNotification>> getCachedNotifications() async {
    final db = await database;
    final maps = await db.query('notifications', orderBy: 'created_at DESC');
    return maps.map((m) => CampusNotification.fromMap(m)).toList();
  }

  Future<int> getCachedUnreadCount() async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM notifications WHERE is_read = 0');
    return result.first['count'] as int;
  }

  // ── Emergency Contacts Cache ────────────────────────

  Future<void> cacheEmergencyContacts(List<EmergencyContact> contacts) async {
    final db = await database;
    await db.delete('emergency_contacts');
    for (final c in contacts) {
      await db.insert('emergency_contacts', c.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<List<EmergencyContact>> getCachedEmergencyContacts() async {
    final db = await database;
    final maps = await db.query('emergency_contacts', orderBy: 'sort_order ASC');
    return maps.map((m) => EmergencyContact.fromMap(m)).toList();
  }
}
