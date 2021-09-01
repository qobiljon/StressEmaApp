import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class EMAResponse {
  static const TABLE_NAME = 'EMAResponse';
  static Database db;

  // region EMA response variables
  final int fillTimestamp;
  final int cheerful;
  final int happy;
  final int angry;
  final int nervous;
  final int sad;
  final String activity;
  final double locationLatitude;
  final double locationLongitude;

  // endregion

  EMAResponse({this.fillTimestamp, this.cheerful, this.happy, this.angry, this.nervous, this.sad, this.activity, this.locationLatitude, this.locationLongitude});

  Map<String, dynamic> toMap() => {'fillTimestamp': fillTimestamp, 'cheerful': cheerful, 'happy': happy, 'angry': angry, 'nervous': nervous, 'sad': sad, 'activity': activity, 'locationLatitude': locationLatitude, 'locationLongitude': locationLongitude};

  @override
  String toString() => '$TABLE_NAME{fillTimestamp: $fillTimestamp}';

  void saveReport() async {
    if (db == null) db = await _connectDB();
    db.insert(TABLE_NAME, toMap(), conflictAlgorithm: ConflictAlgorithm.fail);
  }

  void deleteReport() async {
    if (db == null) db = await _connectDB();
    db.delete(TABLE_NAME, where: 'fillTimestamp = ?', whereArgs: [fillTimestamp]);
  }

  static Future<Database> _connectDB() async {
    return await openDatabase(
      join(await getDatabasesPath(), '$TABLE_NAME.db'),
      onCreate: (db, version) => db.execute('CREATE TABLE $TABLE_NAME(fillTimestamp BIGINT PRIMARY KEY, cheerful INTEGER, happy INTEGER, angry INTEGER, nervous INTEGER, sad INTEGER, activity VARCHAR(64), locationLatitude FLOAT, locationLongitude FLOAT);'),
      version: 1,
    );
  }

  static Future<List<EMAResponse>> getEMAReports() async {
    if (db == null) db = await _connectDB();
    final maps = await db.query(TABLE_NAME);
    return List.generate(maps.length, (i) {
      return EMAResponse(
        fillTimestamp: maps[i]['fillTimestamp'],
        cheerful: maps[i]['cheerful'],
        happy: maps[i]['happy'],
        angry: maps[i]['angry'],
        nervous: maps[i]['nervous'],
        sad: maps[i]['sad'],
        activity: maps[i]['activity'],
        locationLatitude: maps[i]['locationLatitude'],
        locationLongitude: maps[i]['locationLongitude'],
      );
    });
  }
}
