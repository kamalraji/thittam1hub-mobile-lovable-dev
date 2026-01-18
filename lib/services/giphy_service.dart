import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GiphyGif {
  final String id;
  final String previewUrl;
  final String fullUrl;
  final String? title;
  final int width;
  final int height;

  const GiphyGif({
    required this.id,
    required this.previewUrl,
    required this.fullUrl,
    this.title,
    required this.width,
    required this.height,
  });

  factory GiphyGif.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as Map<String, dynamic>? ?? {};
    final fixed = images['fixed_width'] as Map<String, dynamic>? ?? {};
    final original = images['original'] as Map<String, dynamic>? ?? {};
    
    return GiphyGif(
      id: json['id'] as String? ?? '',
      title: json['title'] as String?,
      previewUrl: fixed['url'] as String? ?? '',
      fullUrl: original['url'] as String? ?? fixed['url'] as String? ?? '',
      width: int.tryParse(fixed['width']?.toString() ?? '200') ?? 200,
      height: int.tryParse(fixed['height']?.toString() ?? '200') ?? 200,
    );
  }
}

class GiphyService {
  // Note: In production, use edge function proxy for security
  static const String _baseUrl = 'https://api.giphy.com/v1/gifs';
  
  final String apiKey;
  
  GiphyService({required this.apiKey});
  
  /// Get trending GIFs
  Future<List<GiphyGif>> getTrending({int limit = 25, int offset = 0}) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/trending?api_key=$apiKey&limit=$limit&offset=$offset&rating=pg-13'
      );
      
      final response = await http.get(url);
      
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch trending GIFs');
      }
      
      return _parseGifs(response.body);
    } catch (e) {
      debugPrint('Error fetching trending GIFs: $e');
      return [];
    }
  }
  
  /// Search GIFs by query
  Future<List<GiphyGif>> search(String query, {int limit = 25, int offset = 0}) async {
    if (query.trim().isEmpty) return getTrending(limit: limit);
    
    try {
      final url = Uri.parse(
        '$_baseUrl/search?api_key=$apiKey&q=${Uri.encodeComponent(query)}&limit=$limit&offset=$offset&rating=pg-13&lang=en'
      );
      
      final response = await http.get(url);
      
      if (response.statusCode != 200) {
        throw Exception('Failed to search GIFs');
      }
      
      return _parseGifs(response.body);
    } catch (e) {
      debugPrint('Error searching GIFs: $e');
      return [];
    }
  }
  
  /// Parse GIF response
  List<GiphyGif> _parseGifs(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final data = json['data'] as List<dynamic>? ?? [];
    
    return data
        .map((gif) => GiphyGif.fromJson(gif as Map<String, dynamic>))
        .where((gif) => gif.previewUrl.isNotEmpty)
        .toList();
  }
}
