import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_typography.dart';

class DompetkuBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const DompetkuBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          top: BorderSide(
            color: AppColors.border,
            width: AppBorders.borderWidth,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.08),
            offset: const Offset(0, -2),
            blurRadius: 0,
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 6,
        bottom: MediaQuery.of(context).padding.bottom > 0
            ? MediaQuery.of(context).padding.bottom
            : 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            index: 0,
            icon: Icons.home_rounded,
            label: 'Home',
          ),
          _buildNavItem(
            index: 1,
            icon: Icons.document_scanner_rounded,
            label: 'Scan Struk',
          ),
          _buildCenterButton(),
          _buildNavItem(
            index: 3,
            icon: Icons.receipt_long_rounded,
            label: 'Transaksi',
          ),
          _buildNavItem(
            index: 4,
            icon: Icons.insights_rounded,
            label: 'Report',
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = currentIndex == index;

    return InkWell(
      onTap: () => onTabSelected(index),
      borderRadius: BorderRadius.circular(AppBorders.radiusMedium),
      child: Container(
        constraints: const BoxConstraints(minWidth: 60, minHeight: 48), // >= 44px
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? AppColors.ink : AppColors.inkMuted,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                fontSize: 10,
                color: isSelected ? AppColors.ink : AppColors.inkMuted,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterButton() {
    final isSelected = currentIndex == 2;

    return GestureDetector(
      onTap: () => onTabSelected(2),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.ink,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.border,
            width: AppBorders.borderWidth,
          ),
          boxShadow: AppShadows.tactileSmall,
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }
}
