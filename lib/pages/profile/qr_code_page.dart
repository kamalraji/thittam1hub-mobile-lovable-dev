import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:thittam1hub/services/profile_service.dart';
import 'package:thittam1hub/supabase/supabase_config.dart';
import 'package:thittam1hub/theme.dart';
import 'package:thittam1hub/utils/animations.dart';

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
  bool _isBright = false;

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
      HapticFeedback.lightImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('QR code copied to clipboard'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _shareQrCode() async {
    if (_qrCode != null) {
      HapticFeedback.lightImpact();
      await Share.share(
        'Check me in at events with this code: $_qrCode\n\nName: $_fullName',
        subject: 'My Event Check-in QR Code',
      );
    }
  }

  void _toggleBrightness() {
    HapticFeedback.lightImpact();
    setState(() => _isBright = !_isBright);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Check-in QR'),
        actions: [
          if (_qrCode != null) ...[
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareQrCode,
              tooltip: 'Share QR Code',
            ),
            IconButton(
              icon: Icon(_isBright ? Icons.brightness_high : Icons.brightness_medium),
              onPressed: _toggleBrightness,
              tooltip: _isBright ? 'Normal brightness' : 'Boost brightness',
            ),
          ],
        ],
      ),
      body: _isLoading
          ? Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: const QrCodeSkeleton(),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    
                    // QR Code with brightness boost
                    if (_qrCode != null)
                      FadeSlideTransition(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: _isBright ? Colors.white : cs.surface,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            boxShadow: [
                              BoxShadow(
                                color: _isBright 
                                    ? Colors.black.withValues(alpha: 0.2)
                                    : Colors.black.withValues(alpha: 0.1),
                                blurRadius: _isBright ? 30 : 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: QrImageView(
                            data: _qrCode!,
                            version: QrVersions.auto,
                            size: 250,
                            backgroundColor: Colors.white,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.roundedOuter,
                              color: Colors.black,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.roundedSq,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.qr_code_2,
                              size: 80,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'No QR code available',
                              style: context.textStyles.bodyLarge?.withColor(cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: AppSpacing.lg),
                    
                    // User name
                    FadeSlideTransition(
                      delay: const Duration(milliseconds: 100),
                      child: Text(
                        _fullName,
                        style: context.textStyles.headlineSmall?.bold,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                    const SizedBox(height: AppSpacing.sm),
                    
                    // Instruction text
                    FadeSlideTransition(
                      delay: const Duration(milliseconds: 200),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.qr_code_scanner,
                              size: 16,
                              color: cs.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Show this QR at event check-in',
                              style: context.textStyles.labelMedium?.withColor(cs.primary),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Action buttons
                    if (_qrCode != null)
                      FadeSlideTransition(
                        delay: const Duration(milliseconds: 300),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _copyToClipboard,
                                icon: const Icon(Icons.copy),
                                label: const Text('Copy Code'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _shareQrCode,
                                icon: const Icon(Icons.share),
                                label: const Text('Share'),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
