import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/category_model.dart';
import '../../../shared/widgets/tactile_chip.dart';

class TransactionFilterBar extends StatelessWidget {
  final TransactionType? selectedType;
  final Function(TransactionType?) onTypeSelected;
  final String selectedCategory;
  final Function(String) onCategorySelected;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final List<CategoryModel> categories;

  const TransactionFilterBar({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    this.categories = CategoryModel.defaultCategories,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorders.radiusMedium),
        border: Border.all(
          color: AppColors.border,
          width: AppBorders.borderWidth,
        ),
        boxShadow: AppShadows.tactileSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Field
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            textAlignVertical: TextAlignVertical.center,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
            decoration: InputDecoration(
              hintText: 'Cari catatan transaksi...',
              hintStyle: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkMuted,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 20,
                color: AppColors.inkMuted,
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 44,
                minHeight: 44,
              ),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear_rounded,
                        size: 18,
                        color: AppColors.inkMuted,
                      ),
                      tooltip: 'Hapus pencarian',
                      onPressed: onClearSearch,
                    )
                  : null,
              suffixIconConstraints: const BoxConstraints(
                minWidth: 44,
                minHeight: 44,
              ),
              filled: true,
              fillColor: AppColors.background,
              isDense: true,
              constraints: const BoxConstraints(minHeight: 46),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 13,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorders.radiusMedium),
                borderSide: const BorderSide(
                  color: AppColors.border,
                  width: 1.0,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorders.radiusMedium),
                borderSide: const BorderSide(
                  color: AppColors.border,
                  width: 1.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorders.radiusMedium),
                borderSide: const BorderSide(
                  color: AppColors.primaryDark,
                  width: AppBorders.borderWidthThick,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Type Segment Filter
          Row(
            children: [
              Expanded(
                child: _buildTypeButton(
                  label: 'Semua',
                  isSelected: selectedType == null,
                  onTap: () => onTypeSelected(null),
                  activeColor: AppColors.ink,
                  activeTextColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTypeButton(
                  label: 'Masuk',
                  isSelected: selectedType == TransactionType.income,
                  onTap: () => onTypeSelected(TransactionType.income),
                  activeColor: AppColors.incomeLight,
                  activeTextColor: AppColors.incomeDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTypeButton(
                  label: 'Keluar',
                  isSelected: selectedType == TransactionType.expense,
                  onTap: () => onTypeSelected(TransactionType.expense),
                  activeColor: AppColors.expenseLight,
                  activeTextColor: AppColors.expenseDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: AppColors.borderLight, height: 1),
          const SizedBox(height: 10),

          // Category Horizontal Scroll
          Text(
            'Kategori',
            style: AppTypography.labelSmall.copyWith(color: AppColors.inkLight),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                TactileChip(
                  label: 'Semua Kategori',
                  icon: Icons.grid_view_rounded,
                  isSelected: selectedCategory == 'all',
                  onTap: () => onCategorySelected('all'),
                ),
                ...categories.map(
                  (cat) => TactileChip(
                    label: cat.name,
                    icon: cat.icon,
                    isSelected: selectedCategory == cat.id,
                    onTap: () => onCategorySelected(cat.id),
                    activeColor: cat.bgColor,
                    activeTextColor: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color activeColor,
    required Color activeTextColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? activeColor : AppColors.surface,
          borderRadius: BorderRadius.circular(AppBorders.radiusSmall),
          border: Border.all(
            color: isSelected ? AppColors.border : AppColors.borderLight,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: isSelected ? activeTextColor : AppColors.inkMuted,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
