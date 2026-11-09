import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/finance_repository.dart';
import '../../../shared/widgets/meemo_mascot.dart';
import '../../../shared/widgets/tactile_button.dart';
import '../widgets/scanner_camera_view.dart';

enum ScanStep {
  camera,
  processing,
  review,
}

class ReceiptItem {
  String name;
  int price;
  int qty;

  ReceiptItem({
    required this.name,
    required this.price,
    required this.qty,
  });
}

class ReceiptScannerScreen extends StatefulWidget {
  final FinanceRepository repository;
  final VoidCallback onSaved;

  const ReceiptScannerScreen({
    super.key,
    required this.repository,
    required this.onSaved,
  });

  @override
  State<ReceiptScannerScreen> createState() => _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends State<ReceiptScannerScreen> {
  ScanStep _currentStep = ScanStep.camera;

  // Extracted mock receipt data (editable)
  String _merchantName = 'Indomaret Point';
  final DateTime _receiptDate = DateTime.now();
  final String _selectedCategory = 'food';
  final List<ReceiptItem> _extractedItems = [
    ReceiptItem(name: 'Susu UHT Cokelat 1L', price: 19500, qty: 1),
    ReceiptItem(name: 'Roti Gandum Toast', price: 16000, qty: 1),
    ReceiptItem(name: 'Air Mineral 600ml', price: 4000, qty: 2),
    ReceiptItem(name: 'Kopi Susu Gula Aren', price: 12500, qty: 1),
  ];

  int get _totalAmount =>
      _extractedItems.fold(0, (sum, item) => sum + (item.price * item.qty));

  void _triggerScan() {
    setState(() => _currentStep = ScanStep.processing);

    // Simulate OCR processing time
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() => _currentStep = ScanStep.review);
      }
    });
  }

  void _confirmAndSave() {
    final now = DateTime.now();
    final tx = TransactionModel(
      id: 'tx_scan_${now.millisecondsSinceEpoch}',
      title: 'Belanja di $_merchantName',
      amount: _totalAmount,
      type: TransactionType.expense,
      categoryId: _selectedCategory,
      walletId: 'main_wallet',
      transactionDate: _receiptDate,
      note: 'Pindai struk otomatis: ${_extractedItems.length} item',
      source: 'receipt',
      createdAt: now,
      updatedAt: now,
    );

    widget.repository.addTransaction(tx);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Transaksi struk berhasil disimpan ke dompet!'),
      ),
    );

    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Pindai Struk Belanja',
                style: AppTypography.displayMedium.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 2),
              Text(
                'Ekstraksi otomatis nama toko, item belanja, dan total struk',
                style: AppTypography.bodySmall,
              ),

              const SizedBox(height: 16),

              // Step-based content
              if (_currentStep == ScanStep.camera) ...[
                ScannerCameraView(
                  onCapture: _triggerScan,
                  onPickGallery: _triggerScan,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppBorders.radiusMedium),
                    border: Border.all(color: AppColors.border, width: 1.0),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: AppColors.primaryDark,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Tekan tombol kamera di atas untuk mensimulasikan pemindaian dan ekstraksi struk.',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.inkLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (_currentStep == ScanStep.processing) ...[
                Container(
                  height: 380,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppBorders.radiusLarge),
                    border: Border.all(
                      color: AppColors.border,
                      width: AppBorders.borderWidth,
                    ),
                    boxShadow: AppShadows.tactileStandard,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const MeemoMascot(
                        size: 72,
                        mood: MeemoMood.scanning,
                        showShadow: true,
                      ),
                      const SizedBox(height: 20),
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Memindai Struk Belanja...',
                        style: AppTypography.headingSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Meemo sedang membaca rincian item dan nominal',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
              ] else if (_currentStep == ScanStep.review) ...[
                // Review & Edit Step
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppBorders.radiusLarge),
                    border: Border.all(
                      color: AppColors.border,
                      width: AppBorders.borderWidth,
                    ),
                    boxShadow: AppShadows.tactileStandard,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.incomeLight,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.border,
                                    width: 1.0,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: AppColors.incomeDark,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Hasil Ekstraksi Struk',
                                style: AppTypography.labelLarge,
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() => _currentStep = ScanStep.camera);
                            },
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Foto Ulang'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.inkMuted,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      const Divider(color: AppColors.border, height: 1),
                      const SizedBox(height: 12),

                      // Merchant Name
                      Text('Nama Merchant / Toko', style: AppTypography.labelSmall),
                      const SizedBox(height: 4),
                      TextFormField(
                        initialValue: _merchantName,
                        style: AppTypography.headingSmall,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        onChanged: (val) => _merchantName = val,
                      ),

                      const SizedBox(height: 14),

                      // Purchased Items List
                      Text('Rincian Item Belanja', style: AppTypography.labelSmall),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(
                            AppBorders.radiusMedium,
                          ),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _extractedItems.length,
                          separatorBuilder: (_, _) => const Divider(
                            height: 1,
                            color: AppColors.borderLight,
                          ),
                          itemBuilder: (context, i) {
                            final item = _extractedItems[i];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: AppTypography.labelMedium,
                                        ),
                                        Text(
                                          '${item.qty}x @ ${CurrencyFormatter.format(item.price)}',
                                          style: AppTypography.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(
                                      item.price * item.qty,
                                    ),
                                    style: AppTypography.labelMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Total Amount Row
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(
                            AppBorders.radiusMedium,
                          ),
                          border: Border.all(
                            color: AppColors.border,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Terdeteksi',
                              style: AppTypography.labelLarge,
                            ),
                            Text(
                              CurrencyFormatter.format(_totalAmount),
                              style: AppTypography.moneyHero.copyWith(
                                fontSize: 18,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Confirmation Buttons
                      Row(
                        children: [
                          Expanded(
                            child: TactileButton(
                              text: 'Pindai Ulang',
                              variant: TactileButtonVariant.secondary,
                              onPressed: () {
                                setState(() => _currentStep = ScanStep.camera);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: TactileButton(
                              text: 'Simpan ke Dompet',
                              variant: TactileButtonVariant.primary,
                              icon: Icons.check_circle_rounded,
                              onPressed: _confirmAndSave,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
