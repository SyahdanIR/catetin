import 'package:flutter/material.dart';

class WalletModel {
  final String id;
  final String name;
  final int initialBalance;
  final DateTime createdAt;
  final IconData icon;

  const WalletModel({
    required this.id,
    required this.name,
    required this.initialBalance,
    required this.createdAt,
    this.icon = Icons.account_balance_wallet_rounded,
  });

  static final List<WalletModel> defaultWallets = [
    WalletModel(
      id: 'main_wallet',
      name: 'Dompet Utama',
      initialBalance: 0,
      createdAt: DateTime(2026, 1, 1),
      icon: Icons.account_balance_wallet_rounded,
    ),
    WalletModel(
      id: 'bank_bca',
      name: 'Rekening Bank',
      initialBalance: 0,
      createdAt: DateTime(2026, 1, 1),
      icon: Icons.account_balance_rounded,
    ),
    WalletModel(
      id: 'ewallet',
      name: 'E-Wallet',
      initialBalance: 0,
      createdAt: DateTime(2026, 1, 1),
      icon: Icons.phone_android_rounded,
    ),
  ];

  static WalletModel getById(String id) {
    return defaultWallets.firstWhere(
      (w) => w.id == id,
      orElse: () => defaultWallets.first,
    );
  }
}
