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
      name: 'Makan & Minum',
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
      name: 'Tagihan & Listrik',
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
    // Income
    CategoryModel(
      id: 'salary',
      name: 'Gaji Pokok',
      icon: Icons.account_balance_wallet_rounded,
      color: AppColors.catSalary,
      bgColor: AppColors.catSalaryBg,
      type: CategoryType.income,
    ),
    CategoryModel(
      id: 'investment',
      name: 'Investasi & Dividen',
      icon: Icons.trending_up_rounded,
      color: AppColors.catInvestment,
      bgColor: AppColors.catInvestmentBg,
      type: CategoryType.income,
    ),
    CategoryModel(
      id: 'freelance',
      name: 'Proyek Sampingan',
      icon: Icons.laptop_mac_rounded,
      color: AppColors.catTransport,
      bgColor: AppColors.catTransportBg,
      type: CategoryType.income,
    ),
    CategoryModel(
      id: 'bonus',
      name: 'Bonus & Hadiah',
      icon: Icons.card_giftcard_rounded,
      color: AppColors.catEntertainment,
      bgColor: AppColors.catEntertainmentBg,
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
