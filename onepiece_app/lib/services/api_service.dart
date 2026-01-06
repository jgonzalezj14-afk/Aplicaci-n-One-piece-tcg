import 'dart:convert';
import 'package:flutter/foundation.dart'; 
import 'package:http/http.dart' as http;  
import '../models/card_model.dart';

class ApiService {
  static const String _prodUrl = "https://onepiece-builder.onrender.com";

  static String get baseUrl {
    if (kIsWeb) {
      return kDebugMode ? "http://localhost:6090" : _prodUrl;
    } else {
      return _prodUrl;
    }
  }

  static String fixUrl(String url) {
    if (kIsWeb && url.isNotEmpty && !url.contains("proxy_image")) {
      String host = baseUrl; 
      if (host.isEmpty) host = _prodUrl; 
      
      return "$host/proxy_image?url=${Uri.encodeComponent(url)}";
    }
    return url;
  }

  Future<Map<String, dynamic>> getCardsPaginated({
    String? query,
    String? color,
    String? type,
    String? set,
    String? cost,
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };

    if (query != null && query.isNotEmpty) queryParams['name'] = query;
    if (color != null && !color.startsWith('All')) queryParams['color'] = color;
    if (type != null && !type.startsWith('All')) queryParams['type'] = type;
    if (set != null && !set.startsWith('All')) queryParams['set'] = set;
    if (cost != null && !cost.startsWith('All')) queryParams['cost'] = cost;

    String endpoint = "$baseUrl/onepiece";
    
    final uri = Uri.parse(endpoint).replace(queryParameters: queryParams);

    try {
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final List<dynamic> dataList = jsonResponse['data'] ?? [];
        final int totalPages = jsonResponse['totalPages'] ?? 1;
        
        final List<CardModel> cards = dataList.map((e) => CardModel.fromJson(e)).toList();
        return {'cards': cards, 'totalPages': totalPages};
      } else {
        debugPrint('Error API: ${response.statusCode}');
        throw Exception('Error API: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error conexión: $e');
      throw Exception('Error conexión: $e');
    }
  }

  Future<List<CardModel>> getCardsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    
    final idsString = ids.join(',');
    final uri = Uri.parse("$baseUrl/onepiece").replace(queryParameters: {'ids': idsString, 'pageSize': '100'});
    
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);
          final List<dynamic> dataList = jsonResponse['data'] ?? [];
          return dataList.map((e) => CardModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Error getCardsByIds: $e");
      return [];
    }
  }

  Future<CardModel?> getRandomCard() async {
    final uri = Uri.parse("$baseUrl/random_card");
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CardModel.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint("Error random: $e");
      return null;
    }
  }
}