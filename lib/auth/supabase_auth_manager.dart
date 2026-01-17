import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:uuid/uuid.dart';
import 'package:thittam1hub/supabase/supabase_config.dart';
import 'package:thittam1hub/models/models.dart';
import 'auth_manager.dart';

class SupabaseAuthManager extends AuthManager with EmailSignInManager, GoogleSignInManager, AppleSignInManager {
  // Deep link redirect URL for OAuth
  static const String _redirectUrl = 'io.supabase.thittam1hub://login-callback';
  @override
  supabase.User? get currentUser => SupabaseConfig.auth.currentUser;

  @override
  Stream<supabase.AuthState> get authStateChanges => SupabaseConfig.auth.onAuthStateChange;

  @override
  Future<supabase.User?> signInWithEmail(
    BuildContext context,
    String email,
    String password,
  ) async {
    try {
      final response = await SupabaseConfig.auth.signInWithPassword(
        email: email,
        password: password,
      );
      debugPrint('✅ Signed in: ${response.user?.email}');
      return response.user;
    } catch (e) {
      debugPrint('❌ Sign in error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign in failed: ${e.toString()}')),
        );
      }
      rethrow;
    }
  }

  @override
  Future<supabase.User?> createAccountWithEmail(
    BuildContext context,
    String email,
    String password,
    String fullName,
  ) async {
    try {
      final response = await SupabaseConfig.auth.signUp(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        debugPrint('✅ Account created: ${response.user!.email}');
        
        // Create user profile with QR code
        final qrCode = const Uuid().v4();
        await SupabaseConfig.client.from('user_profiles').insert({
          'id': response.user!.id,
          'email': email,
          'full_name': fullName,
          'qr_code': qrCode,
        });
        
        debugPrint('✅ User profile created');
      }
      
      return response.user;
    } catch (e) {
      debugPrint('❌ Sign up error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign up failed: ${e.toString()}')),
        );
      }
      rethrow;
    }
  }

  @override
  Future signOut() async {
    try {
      await SupabaseConfig.auth.signOut();
      debugPrint('✅ Signed out');
    } catch (e) {
      debugPrint('❌ Sign out error: $e');
      rethrow;
    }
  }

  @override
  Future deleteUser(BuildContext context) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('No user logged in');
      
      // Delete user profile first (cascades to registrations)
      await SupabaseConfig.client.from('user_profiles').delete().eq('id', user.id);
      
      // Delete auth user
      await SupabaseConfig.client.rpc('delete_user');
      
      debugPrint('✅ User deleted');
    } catch (e) {
      debugPrint('❌ Delete user error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete account failed: ${e.toString()}')),
        );
      }
      rethrow;
    }
  }

  @override
  Future updateEmail({
    required String email,
    required BuildContext context,
  }) async {
    try {
      await SupabaseConfig.auth.updateUser(supabase.UserAttributes(email: email));
      
      // Update email in users table
      final user = currentUser;
      if (user != null) {
        await SupabaseConfig.client
            .from('user_profiles')
            .update({'email': email})
            .eq('id', user.id);
      }
      
      debugPrint('✅ Email updated');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email updated successfully')),
        );
      }
    } catch (e) {
      debugPrint('❌ Update email error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update email failed: ${e.toString()}')),
        );
      }
      rethrow;
    }
  }

  @override
  Future resetPassword({
    required String email,
    required BuildContext context,
  }) async {
    try {
      await SupabaseConfig.auth.resetPasswordForEmail(email);
      debugPrint('✅ Password reset email sent');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent')),
        );
      }
    } catch (e) {
      debugPrint('❌ Reset password error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reset password failed: ${e.toString()}')),
        );
      }
      rethrow;
    }
  }

  /// Get user profile from database
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final data = await SupabaseConfig.client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      if (data == null) return null;
      return UserProfile.fromJson(data);
    } catch (e) {
      debugPrint('❌ Get user profile error: $e');
      return null;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      await SupabaseConfig.client
          .from('user_profiles')
          .update(profile.toJson())
          .eq('id', profile.id);
      debugPrint('✅ User profile updated');
    } catch (e) {
      debugPrint('❌ Update user profile error: $e');
      rethrow;
    }
  }

  @override
  Future<supabase.User?> signInWithGoogle(BuildContext context) async {
    try {
      await SupabaseConfig.auth.signInWithOAuth(
        supabase.OAuthProvider.google,
        redirectTo: _redirectUrl,
        authScreenLaunchMode: supabase.LaunchMode.externalApplication,
      );
      // OAuth flow handles the rest via deep linking
      return null; // User will be set via authStateChanges stream
    } catch (e) {
      debugPrint('❌ Google sign in error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign in failed: ${e.toString()}')),
        );
      }
      rethrow;
    }
  }

  @override
  Future<supabase.User?> signInWithApple(BuildContext context) async {
    try {
      await SupabaseConfig.auth.signInWithOAuth(
        supabase.OAuthProvider.apple,
        redirectTo: _redirectUrl,
        authScreenLaunchMode: supabase.LaunchMode.externalApplication,
      );
      return null;
    } catch (e) {
      debugPrint('❌ Apple sign in error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Apple sign in failed: ${e.toString()}')),
        );
      }
      rethrow;
    }
  }

  /// Handle OAuth callback - create profile for new social users
  Future<void> handleOAuthUser(supabase.User user) async {
    try {
      // Check if profile exists
      final existingProfile = await getUserProfile(user.id);
      if (existingProfile != null) return;

      // Create profile for new OAuth user
      final qrCode = const Uuid().v4();
      await SupabaseConfig.client.from('user_profiles').insert({
        'id': user.id,
        'email': user.email ?? '',
        'full_name': user.userMetadata?['full_name'] ??
            user.userMetadata?['name'] ??
            'User',
        'qr_code': qrCode,
        'avatar_url': user.userMetadata?['avatar_url'] ??
            user.userMetadata?['picture'],
      });
      debugPrint('✅ OAuth user profile created');
    } catch (e) {
      debugPrint('❌ Create OAuth profile error: $e');
    }
  }
}
