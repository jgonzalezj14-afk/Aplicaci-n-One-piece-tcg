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
    String? set,
    int page = 1,
    int pageSize = 20,
  }) async {
    final uri = Uri.parse('$baseUrl/onepiece').replace(queryParameters: {
      if (query != null && query.isNotEmpty) 'name': query,
      if (color != null && color != 'All') 'color': color,
      if (type != null && type != 'All') 'type': type,
      if (set != null && set != 'All') 'set': set,
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    });

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final List<dynamic> dataList = jsonResponse['data'] ?? [];
        final int totalPages = jsonResponse['totalPages'] ?? 1;
        final List<CardModel> cards = dataList.map((e) => CardModel.fromJson(e)).toList();
        return {'cards': cards, 'totalPages': totalPages};
      } else {
        throw Exception('Error API: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error conexión: $e');
    }
  }

  Future<List<CardModel>> getCardsByIds(List<String> ids) async {
    final idsString = ids.join(',');
    final uri = Uri.parse('$baseUrl/onepiece').replace(queryParameters: {'ids': idsString, 'pageSize': '100'});
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
         final jsonResponse = jsonDecode(response.body);
         final List<dynamic> dataList = jsonResponse['data'] ?? [];
         return dataList.map((e) => CardModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<CardModel?> getRandomCard() async {
    final uri = Uri.parse('$baseUrl/random_card');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CardModel.fromJson(data);
      }
      return null;
    } catch (e) {
      print("Error random: $e");
      return null;
    }
  }
}