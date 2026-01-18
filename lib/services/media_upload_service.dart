import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:thittam1hub/supabase/supabase_config.dart';

class ImageValidationError implements Exception {
  final String message;
  ImageValidationError(this.message);
  
  @override
  String toString() => message;
}

class MediaUploadService {
  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];
  static const String sparkPostsBucket = 'media-assets';
  
  final _supabase = SupabaseConfig.client;
  
  /// Validate image file before upload
  Future<Uint8List> validateAndProcessImage(XFile file) async {
    final bytes = await file.readAsBytes();
    
    // Validate file size
    if (bytes.length > maxFileSizeBytes) {
      throw ImageValidationError('Image too large (max 5MB)');
    }
    
    // Validate file type
    final ext = file.path.split('.').last.toLowerCase();
    if (!allowedExtensions.contains(ext)) {
      throw ImageValidationError('Invalid file type. Use JPG, PNG, or WebP');
    }
    
    return bytes;
  }
  
  /// Upload image to Supabase Storage
  /// Returns the public URL of the uploaded image
  Future<String> uploadImage({
    required Uint8List bytes,
    required String fileName,
    void Function(double)? onProgress,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');
      
      // Generate unique file path
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = fileName.split('.').last.toLowerCase();
      final path = 'spark-posts/$userId/${timestamp}_$fileName';
      
      onProgress?.call(0.1);
      
      // Upload to Supabase Storage
      await _supabase.storage
          .from(sparkPostsBucket)
          .uploadBinary(path, bytes, fileOptions: FileOptions(
            contentType: 'image/$ext',
            upsert: true,
          ));
      
      onProgress?.call(0.9);
      
      // Get public URL
      final publicUrl = _supabase.storage
          .from(sparkPostsBucket)
          .getPublicUrl(path);
      
      onProgress?.call(1.0);
      
      debugPrint('✅ Image uploaded: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('❌ Error uploading image: $e');
      rethrow;
    }
  }
  
  /// Pick and validate image from gallery
  Future<({Uint8List bytes, String name})?> pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    
    if (image == null) return null;
    
    final bytes = await validateAndProcessImage(image);
    return (bytes: bytes, name: image.name);
  }
  
  /// Pick image from camera
  Future<({Uint8List bytes, String name})?> pickImageFromCamera() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    
    if (image == null) return null;
    
    final bytes = await validateAndProcessImage(image);
    return (bytes: bytes, name: image.name);
  }
}

/// File options for Supabase Storage
class FileOptions {
  final String contentType;
  final bool upsert;
  
  const FileOptions({
    required this.contentType,
    this.upsert = false,
  });
}
