import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:thittam1hub/supabase/supabase_config.dart';

/// Link preview data extracted from Open Graph metadata
class LinkPreview {
  final String url;
  final String? title;
  final String? description;
  final String? image;
  final String? siteName;
  final String? favicon;
  final String? domain;

  const LinkPreview({
    required this.url,
    this.title,
    this.description,
    this.image,
    this.siteName,
    this.favicon,
    this.domain,
  });

  factory LinkPreview.fromJson(Map<String, dynamic> json) {
    return LinkPreview(
      url: json['url'] as String? ?? '',
      title: json['title'] as String?,
      description: json['description'] as String?,
      image: json['image'] as String?,
      siteName: json['siteName'] as String?,
      favicon: json['favicon'] as String?,
      domain: json['domain'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'url': url,
    'title': title,
    'description': description,
    'image': image,
    'siteName': siteName,
    'favicon': favicon,
    'domain': domain,
  };

  bool get hasContent => title != null || description != null || image != null;
}

/// Service for extracting link preview data via edge function
class LinkPreviewService {
  /// Extract Open Graph metadata from a URL
  Future<LinkPreview?> extractPreview(String url) async {
    if (url.trim().isEmpty) return null;
    
    // Validate URL format
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    
    try {
      final response = await SupabaseConfig.client.functions.invoke(
        'link-preview',
        body: {'url': url},
      );
      
      if (response.status != 200) {
        debugPrint('Link preview failed: ${response.status}');
        return null;
      }
      
      final Map<String, dynamic> data;
      if (response.data is String) {
        data = jsonDecode(response.data) as Map<String, dynamic>;
      } else {
        data = response.data as Map<String, dynamic>;
      }
      
      return LinkPreview.fromJson(data);
    } catch (e) {
      debugPrint('Error extracting link preview: $e');
      return null;
    }
  }
}
