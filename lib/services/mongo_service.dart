import 'package:flutter/foundation.dart'; 
import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logbook_app_077/features/logbook/models/log_model.dart';

class MongoService {
  // --- SINGLETON PATTERN ---
  MongoService._internal();
  static final MongoService _instance = MongoService._internal();
  factory MongoService() => _instance;

  Db? _db;
  final String _collectionName = "logs";
  final String _source = "mongo_service.dart";

  // Getter DB untuk keperluan unit test (connection_test.dart)
  Db get db {
    if (_db == null) {
      throw Exception("DATABASE: Belum diinisialisasi! Panggil connect() dulu.");
    }
    return _db!;
  }
  Future<DbCollection> _getSafeCollection() async {
    if (_db == null || !_db!.isConnected) {
      debugPrint('\x1B[33m[INFO][$_source] -> Koneksi belum siap, mencoba menghubungkan...\x1B[0m');
      await connect();
    }
    return _db!.collection(_collectionName);
  }

  /// TASK 3: Async Connection with debugPrint
  Future<void> connect() async {
    if (_db != null && _db!.isConnected) return;

    try {
      final mongoUri = dotenv.env['MONGODB_URI'];
      if (mongoUri == null || mongoUri.isEmpty) {
        throw "MONGODB_URI tidak ditemukan di file .env!";
      }

      _db = await Db.create(mongoUri);
      
      await _db!.open().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw "Koneksi ke MongoDB Atlas Timeout (Cek Whitelist IP/Sinyal)";
        },
      );
      debugPrint('\x1B[32m[INFO][$_source] -> DATABASE: Terhubung & Koleksi Siap\x1B[0m');
      
    } catch (e) {
      debugPrint('\x1B[31m[ERROR][$_source] -> DATABASE: Gagal Koneksi - $e\x1B[0m');
      rethrow; 
    }
  }

  // --- TASK 3: CRUD OPERASI ---

  Future<List<LogModel>> getLogs(String username) async {
    try {
      final collection = await _getSafeCollection();
      debugPrint('\x1B[34m[INFO][$_source] -> Fetching data for user: $username\x1B[0m');

      final result = await collection
          .find(where.eq('username', username).sortBy('timestamp', descending: true))
          .toList();
      
      return result.map((e) => LogModel.fromMap(e)).toList();
    } catch (e) {
      debugPrint('\x1B[31m[ERROR][$_source] -> Fetch Failed: $e\x1B[0m');
      return [];
    }
  }

  Future<void> insertLog(LogModel logData, String username) async {
    try {
      final collection = await _getSafeCollection();
      var data = logData.toMap();
      data['username'] = username; 
      
      await collection.insertOne(data);
      debugPrint('\x1B[32m[SUCCESS][$_source] -> Data "${logData.title}" Saved to Cloud\x1B[0m');
    } catch (e) {
      debugPrint('\x1B[31m[ERROR][$_source] -> Insert Failed: $e\x1B[0m');
      rethrow;
    }
  }

  Future<void> updateLog(LogModel updatedLog, String username) async {
    try {
      final collection = await _getSafeCollection();
      if (updatedLog.id == null) throw "ID Log tidak ditemukan untuk update";

      await collection.updateOne(
        where.id(updatedLog.id!).and(where.eq('username', username)),
        modify
            .set('title', updatedLog.title)
            .set('description', updatedLog.description)
            .set('category', updatedLog.category)
            .set('timestamp', updatedLog.timestamp),
      );

      debugPrint('\x1B[32m[SUCCESS][$_source] -> Update "${updatedLog.title}" Berhasil\x1B[0m');
    } catch (e) {
      debugPrint('\x1B[31m[ERROR][$_source] -> Update Gagal: $e\x1B[0m');
      rethrow;
    }
  }

  Future<void> deleteLog(ObjectId logId, String username) async {
    try {
      final collection = await _getSafeCollection();
      await collection.remove(
        where.id(logId).and(where.eq('username', username))
      );

      debugPrint('\x1B[32m[SUCCESS][$_source] -> Hapus ID $logId Berhasil\x1B[0m');
    } catch (e) {
      debugPrint('\x1B[31m[ERROR][$_source] -> Hapus Gagal: $e\x1B[0m');
      rethrow;
    }
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
      debugPrint('\x1B[33m[INFO][$_source] -> DATABASE: Koneksi ditutup\x1B[0m');
    }
  }
}