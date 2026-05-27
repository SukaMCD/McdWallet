import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/transactions/presentation/transactions_screen.dart';
import '../../features/budgets/presentation/budgets_screen.dart';
import '../../features/auth/presentation/profile_screen.dart';
import '../constants/colors.dart';
import '../providers/navigation_provider.dart';

class MainLayout extends ConsumerWidget {
  const MainLayout({super.key});

  static const List<Widget> _screens = [
    DashboardScreen(),
    TransactionsScreen(),
    BudgetsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navigationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 64,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              // 4 tab: unselected = 10 flex, selected = 20 flex
              // Total = 10 * 3 + 20 = 50
              final unitWidth = totalWidth / 50;
              final pillWidth = 20 * unitWidth - 8;
              final leftOffset = selectedIndex * 10 * unitWidth + 4;

              return Stack(
                children: [
                  // Pill sliding aktif
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.fastOutSlowIn,
                    left: leftOffset,
                    top: (constraints.maxHeight - 38) / 2,
                    height: 38,
                    width: pillWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  // Baris nav item
                  Row(
                    children: [
                      _buildNavItem(0, LucideIcons.layoutDashboard, 'Dasbor', selectedIndex, ref),
                      _buildNavItem(1, LucideIcons.arrowLeftRight, 'Transaksi', selectedIndex, ref),
                      _buildNavItem(2, LucideIcons.target, 'Anggaran', selectedIndex, ref),
                      _buildNavItem(3, LucideIcons.userCircle, 'Profil', selectedIndex, ref),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    int selectedIndex,
    WidgetRef ref,
  ) {
    final isSelected = index == selectedIndex;
    return Expanded(
      flex: isSelected ? 20 : 10,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          ref.read(navigationProvider.notifier).setTab(index);
        },
        child: Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                  size: 20,
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: Row(
                    children: [
                      if (isSelected) ...[
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Outfit',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
