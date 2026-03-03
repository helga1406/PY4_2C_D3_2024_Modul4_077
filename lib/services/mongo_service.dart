import 'dart:developer';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logbook_app_077/features/logbook/models/log_model.dart';

class MongoService {
  // --- SINGLETON PATTERN ---
  MongoService._internal();
  static final MongoService _instance = MongoService._internal();
  factory MongoService() => _instance;

  // Variabel instance untuk koneksi
  Db? _db;
  final String _collectionName = "logs"; 

  // Getter untuk akses database dengan proteksi
  Db get db {
    if (_db == null || !_db!.isConnected) {
      throw Exception("Database tidak tersedia atau koneksi terputus!");
    }
    return _db!;
  }

  // TASK 3: Async Connection with Protection
  Future<void> connect() async {
    // Jika sudah konek, jangan buat koneksi baru (Prinsip Singleton)
    if (_db != null && _db!.isConnected) return;

    try {
      final mongoUri = dotenv.env['MONGODB_URI'];
      if (mongoUri == null || mongoUri.isEmpty) {
        throw "MONGODB_URI tidak ditemukan di file .env!";
      }

      _db = await Db.create(mongoUri);
      await _db!.open();
      
      log("SUCCESS: Terhubung ke MongoDB Atlas Cloud.", name: "MongoService");
    } catch (e) {
      log("ERROR: Gagal terhubung ke MongoDB Atlas", name: "MongoService", error: e);
      rethrow; // Teruskan error agar bisa ditangani di UI/Controller
    }
  }

  // --- TASK 3: CRUD OPERASI ASYNCHRONOUS ---

  // 1. Ambil data (Read)
  Future<List<LogModel>> getLogs(String username) async {
    try {
      await connect();
      final collection = db.collection(_collectionName);
      
      // Mengambil data berdasarkan username
      final result = await collection.find(where.eq('username', username)).toList();
      
      // Konversi list Map menjadi list LogModel
      return result.map((e) => LogModel.fromMap(e)).toList();
    } catch (e) {
      log("Error getLogs: $e", name: "MongoService");
      return [];
    }
  }

  // 2. Tambah data (Create)
  Future<void> insertLog(LogModel logData, String username) async {
    try {
      await connect();
      final collection = db.collection(_collectionName);
      
      var data = logData.toMap();
      data['username'] = username; // Tambahkan field username untuk identifikasi cloud
      
      await collection.insertOne(data);
      log("Data berhasil disimpan ke Cloud", name: "MongoService");
    } catch (e) {
      log("Error insertLog: $e", name: "MongoService");
    }
  }

  // 3. Ubah data (Update) - MENGGUNAKAN ID (ObjectId)
  Future<void> updateLog(LogModel updatedLog, String username) async {
    try {
      await connect();
      final collection = db.collection(_collectionName);
      
      // PERBAIKAN: Gunakan ID agar update akurat (Mapping BSON)
      await collection.updateOne(
        where.id(updatedLog.id!).and(where.eq('username', username)),
        modify
            .set('title', updatedLog.title)
            .set('description', updatedLog.description)
            .set('category', updatedLog.category)
            .set('timestamp', updatedLog.timestamp),
      );
    } catch (e) {
      log("Error updateLog: $e", name: "MongoService");
    }
  }

  // 4. Hapus data (Delete) - MENGGUNAKAN ID (ObjectId)
  Future<void> deleteLog(ObjectId logId, String username) async {
    try {
      await connect();
      final collection = db.collection(_collectionName);
      
      // PERBAIKAN: Hapus berdasarkan ID unik MongoDB
      await collection.remove(
        where.id(logId).and(where.eq('username', username))
      );
    } catch (e) {
      log("Error deleteLog: $e", name: "MongoService");
    }
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
      log("Koneksi database ditutup.", name: "MongoService");
    }
  }
}