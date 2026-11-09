import 'package:flutter/material.dart';

class WalletModel {
  final String id;
  final String name;
  final IconData icon;
  final double balance;

  const WalletModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.balance,
  });

  static const List<WalletModel> defaultWallets = [
    WalletModel(
      id: 'main_wallet',
      name: 'Dompet Utama',
      icon: Icons.account_balance_wallet_rounded,
      balance: 13082900,
    ),
    WalletModel(
      id: 'bank_bca',
      name: 'Rekening Bank',
      icon: Icons.account_balance_rounded,
      balance: 25400000,
    ),
    WalletModel(
      id: 'ewallet',
      name: 'E-Wallet',
      icon: Icons.phone_android_rounded,
      balance: 850000,
    ),
  ];

  static WalletModel getById(String id) {
    return defaultWallets.firstWhere(
      (w) => w.id == id,
      orElse: () => defaultWallets.first,
    );
  }
}
