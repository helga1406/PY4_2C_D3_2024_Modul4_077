import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logbook_app_077/features/logbook/models/log_model.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);
  final ValueNotifier<List<LogModel>> filteredLogs = ValueNotifier([]);
  
  final ValueNotifier<String> searchQuery = ValueNotifier(""); 
  final ValueNotifier<String> selectedFilter = ValueNotifier("Semua"); 
  
  final String username;
  late final String _userStorageKey;

  LogController({required this.username}) {
    _userStorageKey = 'user_logs_data_$username';
    loadFromDisk();
  }

  void searchLog(String query) {
    searchQuery.value = query; 
    _applyFilters();
  }

  void setFilterCategory(String category) {
    selectedFilter.value = category;
    _applyFilters();
  }

  void _applyFilters() {
    final String query = searchQuery.value.toLowerCase();
    final String category = selectedFilter.value;

    filteredLogs.value = logsNotifier.value.where((log) {
      final bool matchesSearch = log.title.toLowerCase().contains(query);
      final bool matchesCategory = category == "Semua" || log.category == category;
      return matchesSearch && matchesCategory; 
    }).toList();
  }

  void addLog(String title, String desc, String category) {
    final String formattedTime = DateTime.now().toString().substring(0, 16);
    final newLog = LogModel(
      title: title, 
      description: desc, 
      timestamp: formattedTime, 
      category: category, 
    );
    
    logsNotifier.value = [...logsNotifier.value, newLog];
    _applyFilters(); 
    saveToDisk();
  }

  void updateLog(int index, String title, String desc, String category) {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    final logToUpdate = filteredLogs.value[index];
    final realIndex = currentLogs.indexOf(logToUpdate);

    if (realIndex != -1) {
      final String formattedTime = DateTime.now().toString().substring(0, 16);
      currentLogs[realIndex] = LogModel(
        title: title, 
        description: desc, 
        timestamp: formattedTime,
        category: category, 
      );
      
      logsNotifier.value = currentLogs;
      _applyFilters(); 
      saveToDisk();
    }
  }

  void removeLog(int index) {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    final logToRemove = filteredLogs.value[index];
    currentLogs.removeWhere((log) => log == logToRemove);
    
    logsNotifier.value = currentLogs;
    _applyFilters(); 
    saveToDisk();
  }

  Future<void> saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(logsNotifier.value.map((e) => e.toMap()).toList());
    await prefs.setString(_userStorageKey, encodedData);
  }

  Future<void> loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_userStorageKey);
    if (data != null) {
      final List decoded = jsonDecode(data);
      logsNotifier.value = decoded.map((e) => LogModel.fromMap(e)).toList();
      _applyFilters(); 
    } else {
      logsNotifier.value = [];
      filteredLogs.value = [];
    }
  }
}