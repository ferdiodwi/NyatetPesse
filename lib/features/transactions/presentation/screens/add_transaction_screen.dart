import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nyatet_pesse/data/database/app_database.dart';
import 'package:nyatet_pesse/features/transactions/presentation/providers/add_transaction_controller.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final double? initialAmount;
  final String? initialType;
  final String? initialNote;
  final String? initialMerchant;
  final DateTime? initialDate;
  final VoidCallback? onSaved;

  const AddTransactionScreen({
    super.key,
    this.initialAmount,
    this.initialType,
    this.initialNote,
    this.initialMerchant,
    this.initialDate,
    this.onSaved,
  });

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _merchantController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialAmount != null) {
      // Remove decimals for display if they are zero
      _amountController.text = widget.initialAmount! % 1 == 0 
          ? widget.initialAmount!.toInt().toString() 
          : widget.initialAmount!.toString();
    }
    if (widget.initialNote != null) {
      _noteController.text = widget.initialNote!;
    }
    if (widget.initialMerchant != null) {
      _merchantController.text = widget.initialMerchant!;
    }
    
    if (widget.initialType != null) {
       Future.microtask(() => ref.read(transactionTypeProvider.notifier).state = widget.initialType!);
    }
    if (widget.initialDate != null) {
       Future.microtask(() => ref.read(selectedDateProvider.notifier).state = widget.initialDate!);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactionType = ref.watch(transactionTypeProvider);
    final selectedAccount = ref.watch(selectedAccountProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    
    // Default select first account/category if null
    ref.listen(accountsStreamProvider, (prev, next) {
      if (next.hasValue && next.value!.isNotEmpty && ref.read(selectedAccountProvider) == null) {
        Future.microtask(() => ref.read(selectedAccountProvider.notifier).state = next.value!.first);
      }
    });
    ref.listen(categoriesStreamProvider(transactionType), (prev, next) {
      if (next.hasValue && next.value!.isNotEmpty && ref.read(selectedCategoryProvider) == null) {
        Future.microtask(() => ref.read(selectedCategoryProvider.notifier).state = next.value!.first);
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Tambah Transaksi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: [
                  _buildSegmentedControl(transactionType),
                  const SizedBox(height: 24),
                  _buildAmountInput(),
                  const SizedBox(height: 24),
                  _buildFormFields(transactionType, selectedAccount, selectedCategory, selectedDate),
                ],
              ),
            ),
          ),
          _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl(String currentType) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildSegmentButton(
            title: 'Pengeluaran',
            isSelected: currentType == 'EXPENSE',
            onTap: () {
              ref.read(transactionTypeProvider.notifier).state = 'EXPENSE';
              ref.read(selectedCategoryProvider.notifier).state = null; // reset category
            },
          ),
          _buildSegmentButton(
            title: 'Pemasukan',
            isSelected: currentType == 'INCOME',
            onTap: () {
              ref.read(transactionTypeProvider.notifier).state = 'INCOME';
              ref.read(selectedCategoryProvider.notifier).state = null; // reset category
            },
          ),
          _buildSegmentButton(
            title: 'Transfer',
            isSelected: currentType == 'TRANSFER',
            onTap: () {
              ref.read(transactionTypeProvider.notifier).state = 'TRANSFER';
              ref.read(selectedCategoryProvider.notifier).state = null; // reset category
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({required String title, required bool isSelected, required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountInput() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Rp ',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            IntrinsicWidth(
              child: TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 1,
          width: 128,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ],
    );
  }

  Widget _buildFormFields(String type, Account? account, Category? category, DateTime date) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildClickableField(
            icon: Icons.account_balance,
            iconBgColor: Theme.of(context).colorScheme.primaryContainer,
            iconColor: Theme.of(context).colorScheme.onPrimaryContainer,
            label: 'Akun',
            value: account?.name ?? 'Pilih Akun',
            onTap: _showAccountPicker,
          ),
          if (type != 'TRANSFER') const Divider(height: 1),
          if (type != 'TRANSFER') _buildClickableField(
            icon: Icons.category,
            iconBgColor: Theme.of(context).colorScheme.errorContainer,
            iconColor: Theme.of(context).colorScheme.onErrorContainer,
            label: 'Kategori',
            value: category?.name ?? 'Pilih Kategori',
            onTap: _showCategoryPicker,
          ),
          const Divider(height: 1),
          _buildClickableField(
            icon: Icons.calendar_today,
            iconBgColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
            label: 'Tanggal & Waktu',
            value: dateFormat.format(date),
            onTap: () async {
               final selected = await showDatePicker(
                 context: context,
                 initialDate: date,
                 firstDate: DateTime(2000),
                 lastDate: DateTime(2100),
               );
               if (selected != null) {
                 ref.read(selectedDateProvider.notifier).state = selected;
               }
            },
          ),
          const Divider(height: 1),
          _buildInputField(
            icon: Icons.storefront,
            controller: _merchantController,
            hint: 'Merchant (Opsional)',
          ),
          const Divider(height: 1),
          _buildInputField(
            icon: Icons.edit_note,
            controller: _noteController,
            hint: 'Catatan (Opsional)',
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  void _showAccountPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final accountsAsync = ref.watch(accountsStreamProvider);
            return accountsAsync.when(
              data: (accounts) => ListView.builder(
                itemCount: accounts.length,
                itemBuilder: (context, index) {
                  final acc = accounts[index];
                  return ListTile(
                    title: Text(acc.name),
                    onTap: () {
                      ref.read(selectedAccountProvider.notifier).state = acc;
                      Navigator.pop(context);
                    },
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text(e.toString())),
            );
          },
        );
      },
    );
  }

  void _showCategoryPicker() {
     final type = ref.read(transactionTypeProvider);
     showModalBottomSheet(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final categoriesAsync = ref.watch(categoriesStreamProvider(type));
            return categoriesAsync.when(
              data: (categories) => ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  return ListTile(
                    title: Text(cat.name),
                    onTap: () {
                      ref.read(selectedCategoryProvider.notifier).state = cat;
                      Navigator.pop(context);
                    },
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text(e.toString())),
            );
          },
        );
      },
    );
  }

  Widget _buildClickableField({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.outlineVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required IconData icon,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: maxLines > 1 ? 8.0 : 0),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(icon, color: Theme.of(context).colorScheme.outline),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    final state = ref.watch(addTransactionControllerProvider);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: ElevatedButton(
        onPressed: state.isLoading ? null : () async {
          final amount = double.tryParse(_amountController.text);
          if (amount == null || amount <= 0) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Masukkan nominal yang valid')));
             return;
          }
          final success = await ref.read(addTransactionControllerProvider.notifier).saveTransaction(
            amount: amount,
            merchant: _merchantController.text.isEmpty ? null : _merchantController.text,
            note: _noteController.text.isEmpty ? null : _noteController.text,
          );
          
          if (success && mounted) {
             if (widget.onSaved != null) {
               widget.onSaved!();
             }
             Navigator.pop(context);
          } else if (mounted) {
             final err = ref.read(addTransactionControllerProvider).error;
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $err')));
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (state.isLoading)
              const SizedBox(width: 24, height: 24, child: CircularProgressIndicator())
            else
              const Icon(Icons.check_circle),
            const SizedBox(width: 8),
            Text(
              'Simpan Transaksi',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
