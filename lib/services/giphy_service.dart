import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:thittam1hub/supabase/supabase_config.dart';

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

/// Giphy service using secure edge function proxy
class GiphyService {
  /// Get trending GIFs via edge function proxy
  Future<List<GiphyGif>> getTrending({int limit = 25, int offset = 0}) async {
    try {
      final response = await SupabaseConfig.client.functions.invoke(
        'giphy-proxy',
        queryParameters: {
          'action': 'trending',
          'limit': limit.toString(),
          'offset': offset.toString(),
        },
      );
      
      if (response.status != 200) {
        throw Exception('Failed to fetch trending GIFs: ${response.status}');
      }
      
      return _parseGifs(response.data);
    } catch (e) {
      debugPrint('Error fetching trending GIFs: $e');
      return [];
    }
  }
  
  /// Search GIFs by query via edge function proxy
  Future<List<GiphyGif>> search(String query, {int limit = 25, int offset = 0}) async {
    if (query.trim().isEmpty) return getTrending(limit: limit);
    
    try {
      final response = await SupabaseConfig.client.functions.invoke(
        'giphy-proxy',
        queryParameters: {
          'action': 'search',
          'q': query,
          'limit': limit.toString(),
          'offset': offset.toString(),
        },
      );
      
      if (response.status != 200) {
        throw Exception('Failed to search GIFs: ${response.status}');
      }
      
      return _parseGifs(response.data);
    } catch (e) {
      debugPrint('Error searching GIFs: $e');
      return [];
    }
  }
  
  /// Parse GIF response from edge function
  List<GiphyGif> _parseGifs(dynamic responseData) {
    if (responseData == null) return [];
    
    final Map<String, dynamic> json;
    if (responseData is String) {
      json = jsonDecode(responseData) as Map<String, dynamic>;
    } else {
      json = responseData as Map<String, dynamic>;
    }
    
    final data = json['data'] as List<dynamic>? ?? [];
    
    return data
        .map((gif) => GiphyGif.fromJson(gif as Map<String, dynamic>))
        .where((gif) => gif.previewUrl.isNotEmpty)
        .toList();
  }
}
