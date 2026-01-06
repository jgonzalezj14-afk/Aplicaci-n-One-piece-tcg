import 'dart:convert';
import 'package:flutter/foundation.dart'; 
import 'package:http/http.dart' as http;  
import '../models/card_model.dart';

class ApiService {
  static String get baseUrl {
    if (kDebugMode) {
      if (kIsWeb) return "http://localhost:6090";
      return "http://10.0.2.2:6090";
    }
    
    return ""; 
  }

  static String fixUrl(String url) {
    if (kIsWeb && url.isNotEmpty && !url.contains("proxy_image")) {
      String prefix = baseUrl.isEmpty ? "" : baseUrl;
      return "$prefix/proxy_image?url=${Uri.encodeComponent(url)}";
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

    String finalUrl = '$baseUrl/onepiece';
    if (baseUrl.isEmpty) finalUrl = '/onepiece'; 

    final uri = Uri.parse(finalUrl).replace(queryParameters: queryParams);

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
    String finalUrl = '$baseUrl/onepiece';
    if (baseUrl.isEmpty) finalUrl = '/onepiece';

    final uri = Uri.parse(finalUrl).replace(queryParameters: {'ids': idsString, 'pageSize': '100'});
    
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
    String finalUrl = '$baseUrl/random_card';
    if (baseUrl.isEmpty) finalUrl = '/random_card';

    final uri = Uri.parse(finalUrl);
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