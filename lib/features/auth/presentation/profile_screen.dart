import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/app_card.dart';
import '../providers/auth_provider.dart';

final appVersionProvider = FutureProvider<String>((ref) async {
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    return 'v${packageInfo.version}';
  } catch (_) {
    return 'v1.0.0';
  }
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final versionAsync = ref.watch(appVersionProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
        child: Column(
          children: [
            profileAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ),
                error: (err, _) => Text('Error: $err', style: const TextStyle(color: AppColors.danger)),
                data: (profile) {
                  if (profile == null) return const Text('Profil tidak ditemukan', style: TextStyle(color: AppColors.textSecondary));

                  // Get initials from name
                  final initials = profile.fullName
                      .split(' ')
                      .take(2)
                      .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
                      .join();

                  return Column(
                    children: [
                      // ── App Logo as Profile Avatar ──
                      Image.asset(
                        'assets/images/logo.png',
                        width: 110,
                        height: 80,
                        fit: BoxFit.contain,
                      ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), duration: 400.ms),

                      const SizedBox(height: 16),

                      Text(
                        profile.fullName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

                      const SizedBox(height: 4),

                      Text(
                        '@${profile.username}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ).animate().fadeIn(delay: 150.ms, duration: 300.ms),

                      const SizedBox(height: 36),

                      // ── Info Card ──
                      AppCard(
                        child: Column(
                          children: [
                            _buildInfoRow(
                              LucideIcons.mail,
                              'EMAIL',
                              ref.watch(authStateProvider).value?.email ?? '',
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Divider(color: AppColors.border, height: 1, thickness: 0.5),
                            ),
                            _buildInfoRow(
                              LucideIcons.coins,
                              'MATA UANG',
                              profile.currency,
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Divider(color: AppColors.border, height: 1, thickness: 0.5),
                            ),
                            _buildInfoRow(
                              LucideIcons.calendar,
                              'TERDAFTAR',
                              '${profile.createdAt.day}/${profile.createdAt.month}/${profile.createdAt.year}',
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 250.ms, duration: 400.ms).slideY(begin: 0.05, end: 0, duration: 400.ms),

                      const SizedBox(height: 16),

                      // ── App Info Card ──
                      AppCard(
                        child: Column(
                          children: [
                            _buildInfoRow(
                              LucideIcons.info,
                              'VERSI APLIKASI',
                              versionAsync.maybeWhen(
                                data: (version) => version,
                                orElse: () => 'v1.0.0',
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Divider(color: AppColors.border, height: 1, thickness: 0.5),
                            ),
                            _buildInfoRow(
                              LucideIcons.code2,
                              'TENTANG',
                              'McdWallet — Finance Manager',
                              onTap: () async {
                                final uri = Uri.parse('https://github.com/SukaMCD/McdWallet');
                                try {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                } catch (_) {
                                  await launchUrl(uri, mode: LaunchMode.platformDefault);
                                }
                              },
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 350.ms, duration: 400.ms).slideY(begin: 0.05, end: 0, duration: 400.ms),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // ── Support Me ──
              Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  'DUKUNG PENGEMBANG',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ).animate().fadeIn(delay: 450.ms, duration: 300.ms),

              const SizedBox(height: 8),

              AppCard(
                child: Column(
                  children: [
                    _buildInfoRow(
                      LucideIcons.creditCard,
                      'PAYPAL',
                      'Donasi via PayPal',
                      onTap: () async {
                        final uri = Uri.parse('https://paypal.me/sukamcd?country.x=ID&locale.x=id_ID');
                        try {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } catch (_) {
                          await launchUrl(uri, mode: LaunchMode.platformDefault);
                        }
                      },
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(color: AppColors.border, height: 1, thickness: 0.5),
                    ),
                    _buildInfoRow(
                      LucideIcons.coffee,
                      'KO-FI',
                      'Traktir Kopi',
                      onTap: () async {
                        final uri = Uri.parse('https://ko-fi.com/SukaMCD');
                        try {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } catch (_) {
                          await launchUrl(uri, mode: LaunchMode.platformDefault);
                        }
                      },
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 500.ms, duration: 400.ms).slideY(begin: 0.05, end: 0, duration: 400.ms),

              const SizedBox(height: 24),

              // ── Sign Out ──
              CustomButton(
                text: 'Keluar',
                color: AppColors.expense,
                icon: LucideIcons.logOut,
                onPressed: () {
                  ref.read(authServiceProvider).signOut();
                },
              ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

              const SizedBox(height: 24),
            ],
          ),
        ),
      );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {VoidCallback? onTap}) {
    final row = Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.textSecondary, size: 16),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  color: onTap != null ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        if (onTap != null)
          const Icon(LucideIcons.externalLink, size: 14, color: AppColors.primary),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: row,
      );
    }
    return row;
  }
}
