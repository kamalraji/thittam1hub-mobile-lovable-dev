import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:thittam1hub/services/profile_service.dart';
import 'package:thittam1hub/supabase/supabase_config.dart';
import 'package:thittam1hub/theme.dart';

/// My QR Code screen - Display user's check-in QR code
class QrCodePage extends StatefulWidget {
  const QrCodePage({super.key});

  @override
  State<QrCodePage> createState() => _QrCodePageState();
}

class _QrCodePageState extends State<QrCodePage> {
  final _profileService = ProfileService();
  String? _qrCode;
  String _fullName = 'User';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQrCode();
  }

  Future<void> _loadQrCode() async {
    final userId = SupabaseConfig.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final profile = await _profileService.getUserProfile(userId);
      if (profile != null && mounted) {
        setState(() {
          _qrCode = profile.qrCode;
          _fullName = profile.fullName ?? 'User';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load QR code: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _copyToClipboard() async {
    if (_qrCode != null) {
      await Clipboard.setData(ClipboardData(text: _qrCode!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QR code copied to clipboard'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Check-in QR'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    
                    // QR Code
                    if (_qrCode != null)
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: _qrCode!,
                          version: QrVersions.auto,
                          size: 250,
                          backgroundColor: Colors.white,
                        ),
                      )
                    else
                      const Text('No QR code available'),
                    
                    const SizedBox(height: AppSpacing.lg),
                    
                    // User name
                    Text(
                      _fullName,
                      style: context.textStyles.headlineSmall?.bold,
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: AppSpacing.sm),
                    
                    // Instruction text
                    Text(
                      'Show this QR at event check-in',
                      style: context.textStyles.bodyMedium?.withColor(AppColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                    
                    const Spacer(),
                    
                    // Copy button
                    OutlinedButton.icon(
                      onPressed: _copyToClipboard,
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy Code'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
