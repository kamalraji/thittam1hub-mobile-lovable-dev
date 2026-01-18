import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:thittam1hub/supabase/supabase_config.dart';

/// Verification types
enum VerificationType { selfie, linkedin, github, email }

/// Verification status
enum VerificationStatus { pending, approved, rejected }

/// Profile verification model
class ProfileVerification {
  final String id;
  final String userId;
  final VerificationType type;
  final VerificationStatus status;
  final String? selfieUrl;
  final String? linkedAccountId;
  final String? linkedAccountUrl;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewerNotes;

  const ProfileVerification({
    required this.id,
    required this.userId,
    required this.type,
    required this.status,
    this.selfieUrl,
    this.linkedAccountId,
    this.linkedAccountUrl,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewerNotes,
  });

  factory ProfileVerification.fromMap(Map<String, dynamic> map) {
    return ProfileVerification(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      type: _parseType(map['verification_type'] as String),
      status: _parseStatus(map['status'] as String),
      selfieUrl: map['selfie_url'] as String?,
      linkedAccountId: map['linked_account_id'] as String?,
      linkedAccountUrl: map['linked_account_url'] as String?,
      submittedAt: DateTime.parse(map['submitted_at'] as String),
      reviewedAt: map['reviewed_at'] != null ? DateTime.parse(map['reviewed_at'] as String) : null,
      reviewerNotes: map['reviewer_notes'] as String?,
    );
  }

  static VerificationType _parseType(String type) {
    switch (type.toUpperCase()) {
      case 'SELFIE':
        return VerificationType.selfie;
      case 'LINKEDIN':
        return VerificationType.linkedin;
      case 'GITHUB':
        return VerificationType.github;
      case 'EMAIL':
        return VerificationType.email;
      default:
        return VerificationType.email;
    }
  }

  static VerificationStatus _parseStatus(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return VerificationStatus.approved;
      case 'REJECTED':
        return VerificationStatus.rejected;
      default:
        return VerificationStatus.pending;
    }
  }

  bool get isApproved => status == VerificationStatus.approved;
}

/// Aggregated verification status for a user
class UserVerificationStatus {
  final bool isVerified;
  final List<VerificationType> verifiedTypes;
  final List<ProfileVerification> verifications;
  final VerificationType? primaryType;

  const UserVerificationStatus({
    required this.isVerified,
    required this.verifiedTypes,
    required this.verifications,
    this.primaryType,
  });

  bool hasType(VerificationType type) => verifiedTypes.contains(type);
}

/// Service for managing profile verification
class VerificationService {
  final _supabase = SupabaseConfig.client;

  /// Get current user's verification status
  Future<UserVerificationStatus> getVerificationStatus() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return const UserVerificationStatus(
          isVerified: false,
          verifiedTypes: [],
          verifications: [],
        );
      }

      final response = await _supabase
          .from('profile_verifications')
          .select('*')
          .eq('user_id', userId)
          .order('submitted_at', ascending: false);

      final verifications = (response as List)
          .map((v) => ProfileVerification.fromMap(v as Map<String, dynamic>))
          .toList();

      final approved = verifications.where((v) => v.isApproved).toList();
      final verifiedTypes = approved.map((v) => v.type).toList();

      return UserVerificationStatus(
        isVerified: approved.isNotEmpty,
        verifiedTypes: verifiedTypes,
        verifications: verifications,
        primaryType: approved.isNotEmpty ? approved.first.type : null,
      );
    } catch (e) {
      debugPrint('Error fetching verification status: $e');
      return const UserVerificationStatus(
        isVerified: false,
        verifiedTypes: [],
        verifications: [],
      );
    }
  }

  /// Submit selfie verification
  Future<bool> submitSelfieVerification(File selfieImage) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Upload selfie to storage
      final fileName = 'verification_$userId\_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'verifications/$userId/$fileName';

      await _supabase.storage.from('avatars').upload(path, selfieImage);
      final selfieUrl = _supabase.storage.from('avatars').getPublicUrl(path);

      // Create verification record
      await _supabase.from('profile_verifications').insert({
        'user_id': userId,
        'verification_type': 'SELFIE',
        'status': 'PENDING',
        'selfie_url': selfieUrl,
      });

      debugPrint('📸 Selfie verification submitted');
      return true;
    } catch (e) {
      debugPrint('❌ Error submitting selfie verification: $e');
      return false;
    }
  }

  /// Link LinkedIn account for verification
  Future<bool> linkLinkedIn(String linkedInUrl) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Extract LinkedIn profile ID from URL
      final regex = RegExp(r'linkedin\.com/in/([^/]+)');
      final match = regex.firstMatch(linkedInUrl);
      final linkedInId = match?.group(1);

      if (linkedInId == null) {
        debugPrint('Invalid LinkedIn URL');
        return false;
      }

      // Create verification record
      await _supabase.from('profile_verifications').insert({
        'user_id': userId,
        'verification_type': 'LINKEDIN',
        'status': 'PENDING',
        'linked_account_id': linkedInId,
        'linked_account_url': linkedInUrl,
      });

      debugPrint('💼 LinkedIn verification submitted');
      return true;
    } catch (e) {
      debugPrint('❌ Error linking LinkedIn: $e');
      return false;
    }
  }

  /// Link GitHub account for verification
  Future<bool> linkGitHub(String githubUsername) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final githubUrl = 'https://github.com/$githubUsername';

      // Create verification record
      await _supabase.from('profile_verifications').insert({
        'user_id': userId,
        'verification_type': 'GITHUB',
        'status': 'PENDING',
        'linked_account_id': githubUsername,
        'linked_account_url': githubUrl,
      });

      debugPrint('🐙 GitHub verification submitted');
      return true;
    } catch (e) {
      debugPrint('❌ Error linking GitHub: $e');
      return false;
    }
  }

  /// Auto-approve email verification (if user has verified email in auth)
  Future<bool> verifyEmail() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // Check if email is confirmed
      if (user.emailConfirmedAt == null) {
        debugPrint('Email not confirmed');
        return false;
      }

      // Create approved verification record
      await _supabase.from('profile_verifications').insert({
        'user_id': user.id,
        'verification_type': 'EMAIL',
        'status': 'APPROVED',
        'linked_account_id': user.email,
        'reviewed_at': DateTime.now().toIso8601String(),
      });

      // Update impact profile
      await _updateProfileVerification(user.id, 'EMAIL');

      debugPrint('📧 Email verification approved');
      return true;
    } catch (e) {
      debugPrint('❌ Error verifying email: $e');
      return false;
    }
  }

  /// Approve a verification (admin use or auto-approval)
  Future<bool> approveVerification(String verificationId, VerificationType type) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase.from('profile_verifications').update({
        'status': 'APPROVED',
        'reviewed_at': DateTime.now().toIso8601String(),
      }).eq('id', verificationId);

      // Update impact profile
      await _updateProfileVerification(userId, type.name.toUpperCase());

      debugPrint('✅ Verification approved');
      return true;
    } catch (e) {
      debugPrint('❌ Error approving verification: $e');
      return false;
    }
  }

  /// Update profile with verification status
  Future<void> _updateProfileVerification(String userId, String verificationType) async {
    try {
      await _supabase.from('impact_profiles').update({
        'is_verified': true,
        'verification_type': verificationType,
        'verified_at': DateTime.now().toIso8601String(),
      }).eq('user_id', userId);
    } catch (e) {
      debugPrint('Error updating profile verification: $e');
    }
  }

  /// Get pending verifications for current user
  Future<List<ProfileVerification>> getPendingVerifications() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('profile_verifications')
          .select('*')
          .eq('user_id', userId)
          .eq('status', 'PENDING');

      return (response as List)
          .map((v) => ProfileVerification.fromMap(v as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching pending verifications: $e');
      return [];
    }
  }

  /// Validate selfie quality (placeholder for ML-based validation)
  Future<bool> validateSelfieQuality(File image) async {
    // In production, this would use ML to:
    // 1. Detect face in image
    // 2. Check lighting quality
    // 3. Verify single face present
    // 4. Match against profile photo

    // For now, just check file exists and has reasonable size
    try {
      final bytes = await image.readAsBytes();
      if (bytes.length < 10000) {
        debugPrint('Image too small');
        return false;
      }
      if (bytes.length > 10000000) {
        debugPrint('Image too large');
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('Error validating selfie: $e');
      return false;
    }
  }
}
