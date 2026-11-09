import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum CategoryType {
  expense,
  income,
  both,
}

class CategoryModel {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final CategoryType type;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.type,
  });

  static const List<CategoryModel> defaultCategories = [
    // Expenses
    CategoryModel(
      id: 'food',
      name: 'Makanan & Minuman',
      icon: Icons.restaurant_rounded,
      color: AppColors.catFood,
      bgColor: AppColors.catFoodBg,
      type: CategoryType.expense,
    ),
    CategoryModel(
      id: 'transport',
      name: 'Transportasi',
      icon: Icons.directions_subway_filled_rounded,
      color: AppColors.catTransport,
      bgColor: AppColors.catTransportBg,
      type: CategoryType.expense,
    ),
    CategoryModel(
      id: 'shopping',
      name: 'Belanja',
      icon: Icons.shopping_bag_rounded,
      color: AppColors.catShopping,
      bgColor: AppColors.catShoppingBg,
      type: CategoryType.expense,
    ),
    CategoryModel(
      id: 'entertainment',
      name: 'Hiburan',
      icon: Icons.sports_esports_rounded,
      color: AppColors.catEntertainment,
      bgColor: AppColors.catEntertainmentBg,
      type: CategoryType.expense,
    ),
    CategoryModel(
      id: 'bills',
      name: 'Tagihan',
      icon: Icons.receipt_long_rounded,
      color: AppColors.catBills,
      bgColor: AppColors.catBillsBg,
      type: CategoryType.expense,
    ),
    CategoryModel(
      id: 'health',
      name: 'Kesehatan',
      icon: Icons.local_hospital_rounded,
      color: AppColors.catHealth,
      bgColor: AppColors.catHealthBg,
      type: CategoryType.expense,
    ),
    CategoryModel(
      id: 'other_expense',
      name: 'Pengeluaran Lainnya',
      icon: Icons.more_horiz_rounded,
      color: AppColors.inkLight,
      bgColor: AppColors.surfaceMuted,
      type: CategoryType.expense,
    ),

    // Income
    CategoryModel(
      id: 'salary',
      name: 'Gaji',
      icon: Icons.account_balance_wallet_rounded,
      color: AppColors.catSalary,
      bgColor: AppColors.catSalaryBg,
      type: CategoryType.income,
    ),
    CategoryModel(
      id: 'bonus',
      name: 'Bonus',
      icon: Icons.card_giftcard_rounded,
      color: AppColors.catEntertainment,
      bgColor: AppColors.catEntertainmentBg,
      type: CategoryType.income,
    ),
    CategoryModel(
      id: 'business',
      name: 'Bisnis',
      icon: Icons.storefront_rounded,
      color: AppColors.catTransport,
      bgColor: AppColors.catTransportBg,
      type: CategoryType.income,
    ),
    CategoryModel(
      id: 'investment',
      name: 'Investasi',
      icon: Icons.trending_up_rounded,
      color: AppColors.catInvestment,
      bgColor: AppColors.catInvestmentBg,
      type: CategoryType.income,
    ),
    CategoryModel(
      id: 'other_income',
      name: 'Pemasukan Lainnya',
      icon: Icons.savings_rounded,
      color: AppColors.catSalary,
      bgColor: AppColors.catSalaryBg,
      type: CategoryType.income,
    ),
  ];

  static CategoryModel getById(String id) {
    return defaultCategories.firstWhere(
      (c) => c.id == id,
      orElse: () => defaultCategories.first,
    );
  }
}
