import 'package:flutter/material.dart';
import 'package:logbook_app_077/features/logbook/models/log_model.dart';
import 'package:logbook_app_077/services/mongo_service.dart';

class LogController {
  // --- STATE UI ---
  final ValueNotifier<String> searchQuery = ValueNotifier("");
  final ValueNotifier<String> selectedFilter = ValueNotifier("Semua");

  final String username;

  LogController({required this.username});

  // --- LOGIKA PENCARIAN & FILTER ---
  void searchLog(String query) {
    searchQuery.value = query;
  }

  void setFilterCategory(String category) {
    selectedFilter.value = category;
  }

  // --- TASK 3: CLOUD CRUD ----
  Future<void> addLog(String title, String desc, String category) async {
    final String formattedTime = DateTime.now().toString().substring(0, 16);
    
    final newLog = LogModel(
      title: title,
      description: desc,
      timestamp: formattedTime,
      category: category,
    );
    await MongoService().insertLog(newLog, username);
  }

  Future<void> updateLog(LogModel updatedLog) async {
    await MongoService().updateLog(updatedLog, username);
  }

  Future<void> removeLog(dynamic logId) async {
    if (logId != null) {
      await MongoService().deleteLog(logId, username);
    }
  }
}
