import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/category_model.dart';
import '../../../data/repositories/finance_repository.dart';
import '../../../shared/widgets/tactile_button.dart';

class AddTransactionScreen extends StatefulWidget {
  final FinanceRepository repository;
  final TransactionType initialType;
  final TransactionModel? transactionToEdit;
  final VoidCallback onSaved;
  final VoidCallback? onCancel;

  const AddTransactionScreen({
    super.key,
    required this.repository,
    this.initialType = TransactionType.expense,
    this.transactionToEdit,
    required this.onSaved,
    this.onCancel,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TransactionType _type;
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;

  late String _selectedCategoryId;
  late String _selectedWalletId;
  late DateTime _selectedDate;
  bool _isRecurring = false;
  bool _isSaving = false;

  String _defaultCategoryIdFor(TransactionType type) {
    final preferredId = type == TransactionType.income ? 'salary' : 'food';
    final matching = _categoriesForType(type);
    if (matching.any((c) => c.id == preferredId)) {
      return preferredId;
    }
    return matching.isNotEmpty ? matching.first.id : preferredId;
  }

  List<CategoryModel> _categoriesForType(TransactionType type) {
    final source = widget.repository.categories.isNotEmpty
        ? widget.repository.categories
        : CategoryModel.defaultCategories;
    return source.where((c) {
      if (type == TransactionType.income) {
        return c.type == CategoryType.income || c.type == CategoryType.both;
      }
      return c.type == CategoryType.expense || c.type == CategoryType.both;
    }).toList();
  }

  String _defaultWalletId() {
    final wallets = widget.repository.wallets;
    final selected = widget.repository.selectedWalletId;
    if (selected != 'all' && wallets.any((w) => w.id == selected)) {
      return selected;
    }
    if (wallets.any((w) => w.id == 'main_wallet')) {
      return 'main_wallet';
    }
    return wallets.isNotEmpty ? wallets.first.id : 'main_wallet';
  }

  @override
  void initState() {
    super.initState();
    final edit = widget.transactionToEdit;
    _type = edit?.type ?? widget.initialType;
    _titleController = TextEditingController(text: edit?.title ?? '');
    _amountController = TextEditingController(
      text: edit != null ? edit.amount.round().toString() : '',
    );
    _notesController = TextEditingController(text: edit?.notes ?? '');
    _selectedCategoryId = edit?.categoryId ?? _defaultCategoryIdFor(_type);
    _selectedWalletId = edit?.walletId ?? _defaultWalletId();
    _selectedDate = edit?.date ?? DateTime.now();
    _isRecurring = edit?.isRecurring ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addQuickAmount(int delta) {
    final current = int.tryParse(_amountController.text) ?? 0;
    final next = current + delta;
    _amountController.text = next.toString();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveTransaction() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    final amount = int.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('Nominal harus lebih besar dari 0')),
        );
      return;
    }

    final availableWallets = widget.repository.wallets;
    final availableCategories = _categoriesForType(_type);
    if (availableWallets.isEmpty || availableCategories.isEmpty) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.expense,
            content: Text('Data dompet atau kategori belum siap.'),
          ),
        );
      return;
    }

    final validWalletId = availableWallets.any((w) => w.id == _selectedWalletId)
        ? _selectedWalletId
        : availableWallets.first.id;
    final validCategoryId =
        availableCategories.any((c) => c.id == _selectedCategoryId)
            ? _selectedCategoryId
            : availableCategories.first.id;

    final isEditing = widget.transactionToEdit != null;
    final now = DateTime.now();
    final transaction = TransactionModel(
      id: isEditing
          ? widget.transactionToEdit!.id
          : 'tx_${now.microsecondsSinceEpoch}',
      title: _titleController.text.trim(),
      amount: amount,
      type: _type,
      categoryId: validCategoryId,
      walletId: validWalletId,
      transactionDate: _selectedDate,
      note: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      source: isEditing ? widget.transactionToEdit!.source : 'manual',
      createdAt: isEditing ? widget.transactionToEdit!.createdAt : now,
      updatedAt: now,
      isRecurring: _isRecurring,
    );

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSaving = true);

    try {
      if (isEditing) {
        await widget.repository.updateTransaction(transaction);
      } else {
        await widget.repository.addTransaction(transaction);
      }
      if (!mounted) return;
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Transaksi berhasil diperbarui!'
                  : 'Transaksi berhasil disimpan!',
            ),
          ),
        );
      widget.onSaved();
    } catch (_) {
      if (!mounted) return;
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.expense,
            content: Text('Gagal menyimpan transaksi. Coba lagi.'),
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.transactionToEdit != null;
    final availableCategories = _categoriesForType(_type);
    final availableWallets = widget.repository.wallets;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Ubah Transaksi' : 'Catat Transaksi',
          style: AppTypography.headingLarge,
        ),
        leading: widget.onCancel != null
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: _isSaving ? null : widget.onCancel,
              )
            : null,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Income vs Expense Segment Selector
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppBorders.radiusMedium),
                    border: Border.all(
                      color: AppColors.border,
                      width: AppBorders.borderWidth,
                    ),
                    boxShadow: AppShadows.tactileSmall,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _isSaving
                              ? null
                              : () {
                                  setState(() {
                                    _type = TransactionType.expense;
                                    _selectedCategoryId = _defaultCategoryIdFor(
                                      TransactionType.expense,
                                    );
                                  });
                                },
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _type == TransactionType.expense
                                  ? AppColors.expenseLight
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(
                                AppBorders.radiusSmall,
                              ),
                              border: _type == TransactionType.expense
                                  ? Border.all(color: AppColors.border, width: 1.5)
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.north_east_rounded,
                                  size: 16,
                                  color: AppColors.expenseDark,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Pengeluaran',
                                  style: AppTypography.labelLarge.copyWith(
                                    color: _type == TransactionType.expense
                                        ? AppColors.expenseDark
                                        : AppColors.inkMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: GestureDetector(
                          onTap: _isSaving
                              ? null
                              : () {
                                  setState(() {
                                    _type = TransactionType.income;
                                    _selectedCategoryId = _defaultCategoryIdFor(
                                      TransactionType.income,
                                    );
                                  });
                                },
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _type == TransactionType.income
                                  ? AppColors.incomeLight
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(
                                AppBorders.radiusSmall,
                              ),
                              border: _type == TransactionType.income
                                  ? Border.all(color: AppColors.border, width: 1.5)
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.south_west_rounded,
                                  size: 16,
                                  color: AppColors.incomeDark,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Pemasukan',
                                  style: AppTypography.labelLarge.copyWith(
                                    color: _type == TransactionType.income
                                        ? AppColors.incomeDark
                                        : AppColors.inkMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Amount Input Box
                Text(
                  'Nominal Transaksi (Rp)',
                  style: AppTypography.labelLarge,
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppBorders.radiusMedium),
                    border: Border.all(
                      color: AppColors.border,
                      width: AppBorders.borderWidth,
                    ),
                    boxShadow: AppShadows.tactileSmall,
                  ),
                  child: TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: AppTypography.moneyHero.copyWith(
                      color: _type == TransactionType.income
                          ? AppColors.incomeDark
                          : AppColors.expenseDark,
                      fontSize: 24,
                    ),
                    decoration: InputDecoration(
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 14, right: 8),
                        child: Text(
                          'Rp',
                          style: AppTypography.labelLarge.copyWith(
                            fontSize: 18,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ),
                      prefixIconConstraints:
                          const BoxConstraints(minWidth: 0, minHeight: 0),
                      hintText: '0',
                      hintStyle: AppTypography.moneyHero.copyWith(
                        color: AppColors.inkMuted,
                        fontSize: 24,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Masukkan nominal transaksi';
                      }
                      if (int.tryParse(val) == null) {
                        return 'Nominal tidak valid';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 8),

                // Quick Denomination Chips
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildQuickChip('+10rb', 10000),
                    _buildQuickChip('+25rb', 25000),
                    _buildQuickChip('+50rb', 50000),
                    _buildQuickChip('+100rb', 100000),
                    _buildQuickChip('+500rb', 500000),
                  ],
                ),

                const SizedBox(height: 18),

                // Title Input
                Text('Judul / Keterangan', style: AppTypography.labelLarge),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _titleController,
                  style: AppTypography.bodyLarge,
                  decoration: const InputDecoration(
                    hintText: 'Contoh: Makan siang, Gaji kantor, Belanja',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Judul transaksi wajib diisi';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // Category Selector
                Text('Pilih Kategori', style: AppTypography.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableCategories.map((cat) {
                    final isSelected = _selectedCategoryId == cat.id;
                    return GestureDetector(
                      onTap: _isSaving
                          ? null
                          : () => setState(() => _selectedCategoryId = cat.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? cat.bgColor : AppColors.surface,
                          borderRadius: BorderRadius.circular(
                            AppBorders.radiusMedium,
                          ),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.border
                                : AppColors.borderLight,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                          boxShadow: isSelected ? AppShadows.tactileSmall : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(cat.icon, size: 16, color: cat.color),
                            const SizedBox(width: 6),
                            Text(
                              cat.name,
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.ink,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 18),

                // Wallet / Account Selector
                Text('Pilih Dompet / Akun', style: AppTypography.labelLarge),
                const SizedBox(height: 8),
                if (availableWallets.isEmpty)
                  Text(
                    'Belum ada dompet tersedia.',
                    style: AppTypography.bodySmall,
                  )
                else
                  Row(
                    children: availableWallets.map((wallet) {
                      final isSelected = _selectedWalletId == wallet.id;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: GestureDetector(
                            onTap: _isSaving
                                ? null
                                : () =>
                                    setState(() => _selectedWalletId = wallet.id),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 10,
                              ),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryLight
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(
                                  AppBorders.radiusMedium,
                                ),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.border
                                      : AppColors.borderLight,
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                                boxShadow:
                                    isSelected ? AppShadows.tactileSmall : null,
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    wallet.icon,
                                    size: 18,
                                    color: isSelected
                                        ? AppColors.primaryDark
                                        : AppColors.inkMuted,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    wallet.name,
                                    style: AppTypography.labelSmall.copyWith(
                                      fontSize: 11,
                                      color: AppColors.ink,
                                    ),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 18),

                // Date Picker Tile
                Text('Tanggal Transaksi', style: AppTypography.labelLarge),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _isSaving ? null : _pickDate,
                  borderRadius: BorderRadius.circular(AppBorders.radiusMedium),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(
                        AppBorders.radiusMedium,
                      ),
                      border: Border.all(
                        color: AppColors.border,
                        width: AppBorders.borderWidth,
                      ),
                      boxShadow: AppShadows.tactileSmall,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 18,
                          color: AppColors.primaryDark,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          AppDateFormatter.formatGroupDate(_selectedDate),
                          style: AppTypography.bodyLarge,
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.arrow_drop_down_rounded,
                          color: AppColors.ink,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Notes / Catatan Tambahan
                Text('Catatan Tambahan (Opsional)', style: AppTypography.labelLarge),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  style: AppTypography.bodyMedium,
                  decoration: const InputDecoration(
                    hintText: 'Tuliskan catatan tambahan mengenai transaksi ini...',
                  ),
                ),

                const SizedBox(height: 14),

                // Recurring switch
                Row(
                  children: [
                    Checkbox(
                      value: _isRecurring,
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: _isSaving
                          ? null
                          : (val) {
                              setState(() => _isRecurring = val ?? false);
                            },
                    ),
                    Expanded(
                      child: Text(
                        'Tandai sebagai pengeluaran/pemasukan rutin',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Save Action Button
                TactileButton(
                  text: _isSaving
                      ? 'Menyimpan...'
                      : (isEditing
                          ? 'Simpan Perubahan'
                          : 'Catat Transaksi Ini'),
                  onPressed: _isSaving ? null : _saveTransaction,
                  isLoading: _isSaving,
                  isFullWidth: true,
                  height: 52,
                  variant: _type == TransactionType.income
                      ? TactileButtonVariant.primary
                      : TactileButtonVariant.accent,
                  icon: isEditing ? Icons.check_rounded : Icons.save_rounded,
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label, int amount) {
    return GestureDetector(
      onTap: () => _addQuickAmount(amount),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppBorders.radiusSmall),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
