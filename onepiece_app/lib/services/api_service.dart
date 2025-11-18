import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/card_model.dart';

class ApiService {
  static String get baseUrl {
    const String port = "6090";
    if (kIsWeb) return "http://localhost:$port";
    if (Platform.isAndroid) return "http://10.0.2.2:$port";
    return "http://localhost:$port";
  }

  Future<Map<String, dynamic>> getCardsPaginated({
    String? query,
    String? color,
    String? type,
    int page = 1,
  }) async {
    
    final uri = Uri.parse('$baseUrl/onepiece').replace(queryParameters: {
      if (query != null && query.isNotEmpty) 'name': query,
      if (color != null && color != 'All') 'color': color,
      if (type != null && type != 'All') 'type': type,
      'page': page.toString(),
      'pageSize': '20',
    });

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        final List<dynamic> dataList = jsonResponse['data'] ?? [];
        // Leemos el total de páginas, si no viene, asumimos 1
        final int totalPages = jsonResponse['totalPages'] ?? 1; 

        final List<CardModel> cards = dataList
            .map((e) => CardModel.fromJson(e as Map<String, dynamic>))
            .toList();

        return {
          'cards': cards,
          'totalPages': totalPages,
        };
      } else {
        throw Exception('Error API: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error conexión: $e');
    }
  }
}