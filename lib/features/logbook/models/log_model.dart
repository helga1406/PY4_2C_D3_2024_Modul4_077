import 'package:mongo_dart/mongo_dart.dart';

class LogModel {
  final ObjectId? id; 
  final String title;
  final String description;
  final String timestamp;
  final String category; 

  LogModel({
    this.id, 
    required this.title,
    required this.description,
    required this.timestamp,
    required this.category, 
  });

  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      id: map['_id'] as ObjectId?, 
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      timestamp: map['timestamp'] ?? '',
      category: map['category'] ?? 'Pribadi', 
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id ?? ObjectId(), 
      'title': title,
      'description': description,
      'timestamp': timestamp,
      'category': category,
    };
  }
}