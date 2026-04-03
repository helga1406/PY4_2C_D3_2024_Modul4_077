import 'package:flutter_test/flutter_test.dart';
import 'package:logbook_app_077/features/logbook/models/log_model.dart';

class FakeMongoService {
  final List<Map<String, dynamic>> _fakeCloud = [];

  Future<void> insertLog(LogModel logData, String username) async {
    if (username.trim().isEmpty) {
      throw Exception("Gagal: Username kosong");
    }
    if (logData.title.trim().isEmpty) {
      throw Exception("Gagal: Judul kosong");
    }
    var data = logData.toMap();
    data['username'] = username;
    _fakeCloud.add(data);
  }

  Future<List<LogModel>> getLogs(String username) async {
    var result = _fakeCloud.where((e) => e['username'] == username).toList();
    return result.map((e) => LogModel.fromMap(e)).toList();
  }
}

void main() {
  dynamic actual, expected;

  group('Modul 4 - MongoService Save to Cloud (Test)', () {
    late FakeMongoService fakeService;

    setUp(() {
      // (1) setup (arrange, build)
      // Inisialisasi mock database cloud (FakeMongoService)
      fakeService = FakeMongoService();
    });

    // Sesuai TC01 di Excel Modul 4
    test('insertLog berhasil menyimpan data ke cloud dengan username valid', () async {
      // (1) setup (arrange, build)
      final logData = LogModel(title: "Test Cloud", description: "Data", timestamp: "2026", category: "Umum");

      // (2) exercise (act, operate)
      await fakeService.insertLog(logData, "helga");

      final result = await fakeService.getLogs("helga");
      actual = result.length;
      expected = 1;

      // (3) verify (assert, check)
      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    // Sesuai TC02 di Excel Modul 4 
    test('insertLog menolak menyimpan data jika username kosong', () async {
      // (1) setup (arrange, build)
      final logData = LogModel(title: "Test Cloud", description: "Data", timestamp: "2026", category: "Umum");

      // (2) exercise (act, operate)
      try {
        await fakeService.insertLog(logData, "");
      } catch (e) {
        // Tangkap error jika fungsi sudah diperbaiki 
      }

      final result = await fakeService.getLogs("");
      actual = result.length;
      expected = 0; 

      // (3) verify (assert, check)
      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    // Sesuai TC03 di Excel Modul 4 
    test('insertLog menolak menyimpan data jika judul log kosong', () async {
      // (1) setup (arrange, build)
      final logData = LogModel(title: "", description: "Data", timestamp: "2026", category: "Umum");

      // (2) exercise (act, operate)
      try {
        await fakeService.insertLog(logData, "helga");
      } catch (e) {
        // Tangkap error jika fungsi sudah diperbaiki 
      }

      final result = await fakeService.getLogs("helga");
      actual = result.length;
      expected = 0; 

      // (3) verify (assert, check)
      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });
  });
}