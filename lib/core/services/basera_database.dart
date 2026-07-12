import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:basera/core/models/safety_report.dart';

class BaseraDatabase {
  static final BaseraDatabase instance = BaseraDatabase._init();
  static Database? _database;

  BaseraDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('basera.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final pathString = join(dbPath, filePath);

    return await openDatabase(
      pathString,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE visited_urls (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        url TEXT UNIQUE,
        timestamp TEXT,
        is_synced INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE safety_reports (
        child_uid TEXT PRIMARY KEY,
        status TEXT,
        summary TEXT,
        report_json TEXT,
        timestamp TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE cached_analyses (
        url TEXT PRIMARY KEY,
        is_harmful INTEGER,
        category TEXT,
        risk_score INTEGER,
        reason TEXT,
        timestamp TEXT
      )
    ''');
  }

  // --- Visited URLs Database Operations ---

  Future<void> insertUrl(String url, {bool isSynced = false}) async {
    final db = await database;
    final timestamp = DateTime.now().toIso8601String();
    try {
      await db.insert(
        'visited_urls',
        {
          'url': url,
          'timestamp': timestamp,
          'is_synced': isSynced ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    } catch (_) {}
  }

  Future<List<String>> getVisitedUrls() async {
    final db = await database;
    final maps = await db.query(
      'visited_urls',
      orderBy: 'timestamp DESC',
    );
    return maps.map((m) => m['url'] as String).toList();
  }

  Future<List<Map<String, dynamic>>> getUnsyncedUrls() async {
    final db = await database;
    return await db.query(
      'visited_urls',
      where: 'is_synced = 0',
    );
  }

  Future<void> markUrlAsSynced(String url) async {
    final db = await database;
    await db.update(
      'visited_urls',
      {'is_synced': 1},
      where: 'url = ?',
      whereArgs: [url],
    );
  }

  Future<void> clearHistory() async {
    final db = await database;
    await db.delete('visited_urls');
  }

  // --- Safety Reports Database Operations ---

  Future<void> saveSafetyReport(String childUid, SafetyReport report) async {
    final db = await database;
    final timestamp = DateTime.now().toIso8601String();
    await db.insert(
      'safety_reports',
      {
        'child_uid': childUid,
        'status': report.overallRiskScore < 5.0 ? 'Safe' : 'At Risk',
        'summary': report.summary,
        'report_json': jsonEncode(report.toJson()),
        'timestamp': timestamp,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<SafetyReport?> getSafetyReport(String childUid) async {
    final db = await database;
    final maps = await db.query(
      'safety_reports',
      where: 'child_uid = ?',
      whereArgs: [childUid],
    );

    if (maps.isNotEmpty) {
      final jsonStr = maps.first['report_json'] as String;
      try {
        return SafetyReport.fromJson(jsonDecode(jsonStr));
      } catch (_) {}
    }
    return null;
  }

  Future<void> clearAllReports() async {
    final db = await database;
    await db.delete('safety_reports');
    await db.delete('cached_analyses');
  }

  // --- SQLite Cached Analysis Operations ---

  Future<UrlAnalysis?> getCachedAnalysis(String url) async {
    final db = await database;
    final maps = await db.query(
      'cached_analyses',
      where: 'url = ?',
      whereArgs: [url],
    );

    if (maps.isNotEmpty) {
      final map = maps.first;
      return UrlAnalysis(
        url: map['url'] as String,
        isHarmful: (map['is_harmful'] as int) == 1,
        category: map['category'] as String,
        riskScore: map['risk_score'] as int,
        reason: map['reason'] as String,
      );
    }
    return null;
  }

  Future<void> cacheUrlAnalysis(UrlAnalysis analysis) async {
    final db = await database;
    final timestamp = DateTime.now().toIso8601String();
    await db.insert(
      'cached_analyses',
      {
        'url': analysis.url,
        'is_harmful': analysis.isHarmful ? 1 : 0,
        'category': analysis.category,
        'risk_score': analysis.riskScore,
        'reason': analysis.reason,
        'timestamp': timestamp,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }
}
