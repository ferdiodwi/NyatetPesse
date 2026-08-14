import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _merchantController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // Type config
  static const _types = [
    _TxType('EXPENSE', 'Pengeluaran', Icons.arrow_upward_rounded, Color(0xFFEF4444)),
    _TxType('INCOME', 'Pemasukan', Icons.arrow_downward_rounded, Color(0xFF22C55E)),
    _TxType('TRANSFER', 'Transfer', Icons.swap_horiz_rounded, Color(0xFF3B82F6)),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    if (widget.initialAmount != null) {
      _amountController.text = widget.initialAmount! % 1 == 0
          ? widget.initialAmount!.toInt().toString()
          : widget.initialAmount!.toString();
    }
    if (widget.initialNote != null) _noteController.text = widget.initialNote!;
    if (widget.initialMerchant != null) _merchantController.text = widget.initialMerchant!;

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
    _animController.dispose();
    super.dispose();
  }

  _TxType get _currentTypeConfig {
    final t = ref.read(transactionTypeProvider);
    return _types.firstWhere((e) => e.key == t, orElse: () => _types.first);
  }

  @override
  Widget build(BuildContext context) {
    final transactionType = ref.watch(transactionTypeProvider);
    final selectedAccount = ref.watch(selectedAccountProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final typeConfig = _types.firstWhere((e) => e.key == transactionType, orElse: () => _types.first);

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
      backgroundColor: const Color(0xFFF5F5F7),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          children: [
            // ── Header (Colored) ──────────────────────────────────────
            _buildHeader(typeConfig, selectedDate),

            // ── Scrollable form ───────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTypeSelector(transactionType),
                    const SizedBox(height: 20),
                    _buildFormCard(transactionType, selectedAccount, selectedCategory),
                  ],
                ),
              ),
            ),

            // ── Save Button ───────────────────────────────────────────
            _buildBottomAction(typeConfig),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Header with colored gradient + amount input
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildHeader(_TxType typeConfig, DateTime date) {
    final dateFormat = DateFormat('EEE, dd MMM yyyy', 'id_ID');
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: typeConfig.color,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── AppBar row ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Tambah Transaksi',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  // Date chip
                  GestureDetector(
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            dateFormat.format(date),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Amount ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                children: [
                  Text(
                    typeConfig.label.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'Rp',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IntrinsicWidth(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: const TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.1,
                          ),
                          cursorColor: Colors.white,
                          decoration: InputDecoration(
                            hintText: '0',
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 44,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Type selector pills
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildTypeSelector(String currentType) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: _types.map((t) {
          final isSelected = t.key == currentType;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(transactionTypeProvider.notifier).state = t.key;
                ref.read(selectedCategoryProvider.notifier).state = null;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? t.color : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      t.icon,
                      size: 15,
                      color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      t.label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? Colors.white : const Color(0xFF6B7280),
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Form card
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildFormCard(String type, Account? account, Category? category) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildField(
            icon: Icons.account_balance_wallet_rounded,
            iconColor: const Color(0xFF6366F1),
            label: 'Akun',
            value: account?.name ?? 'Pilih akun...',
            hasValue: account != null,
            onTap: _showAccountPicker,
            isFirst: true,
          ),
          _buildDivider(),
          if (type != 'TRANSFER') ...[
            _buildField(
              icon: Icons.grid_view_rounded,
              iconColor: const Color(0xFFF59E0B),
              label: 'Kategori',
              value: category?.name ?? 'Pilih kategori...',
              hasValue: category != null,
              onTap: _showCategoryPicker,
            ),
            _buildDivider(),
          ],
          _buildTextInputField(
            icon: Icons.storefront_rounded,
            iconColor: const Color(0xFF10B981),
            controller: _merchantController,
            label: 'Merchant',
            hint: 'Nama toko / penerima (opsional)',
          ),
          _buildDivider(),
          _buildTextInputField(
            icon: Icons.notes_rounded,
            iconColor: const Color(0xFF8B5CF6),
            controller: _noteController,
            label: 'Catatan',
            hint: 'Tambahkan catatan...',
            maxLines: 2,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 68),
      child: Divider(height: 1, color: Colors.grey.withValues(alpha: 0.12)),
    );
  }

  Widget _buildField({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool hasValue,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(20) : Radius.zero,
        bottom: isLast ? const Radius.circular(20) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF9CA3AF),
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: hasValue ? const Color(0xFF111827) : const Color(0xFFD1D5DB),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.withValues(alpha: 0.4),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextInputField({
    required IconData icon,
    required Color iconColor,
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: maxLines > 1 ? 4.0 : 0),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF9CA3AF),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                TextField(
                  controller: controller,
                  maxLines: maxLines,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111827),
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFFD1D5DB),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Bottom save button
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildBottomAction(_TxType typeConfig) {
    final state = ref.watch(addTransactionControllerProvider);

    return Container(
      color: const Color(0xFFF5F5F7),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: state.isLoading
              ? null
              : () async {
                  final amount = double.tryParse(_amountController.text);
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Masukkan nominal yang valid')),
                    );
                    return;
                  }
                  HapticFeedback.mediumImpact();
                  final success = await ref
                      .read(addTransactionControllerProvider.notifier)
                      .saveTransaction(
                        amount: amount,
                        merchant: _merchantController.text.isEmpty ? null : _merchantController.text,
                        note: _noteController.text.isEmpty ? null : _noteController.text,
                      );
                  if (success && mounted) {
                    if (widget.onSaved != null) widget.onSaved!();
                    Navigator.pop(context);
                  } else if (mounted) {
                    final err = ref.read(addTransactionControllerProvider).error;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal menyimpan: $err')),
                    );
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: typeConfig.color,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: state.isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(typeConfig.icon, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'Simpan Transaksi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Pickers
  // ─────────────────────────────────────────────────────────────────────────────
  void _showAccountPicker() {
    _showPicker(
      title: 'Pilih Akun',
      child: Consumer(builder: (context, ref, _) {
        return ref.watch(accountsStreamProvider).when(
          data: (accounts) => _PickerList(
            items: accounts.map((a) => _PickerItem(a.name, Icons.account_balance_wallet_rounded)).toList(),
            onSelected: (i) {
              ref.read(selectedAccountProvider.notifier).state = accounts[i];
              Navigator.pop(context);
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
        );
      }),
    );
  }

  void _showCategoryPicker() {
    final type = ref.read(transactionTypeProvider);
    _showPicker(
      title: 'Pilih Kategori',
      child: Consumer(builder: (context, ref, _) {
        return ref.watch(categoriesStreamProvider(type)).when(
          data: (cats) => _PickerList(
            items: cats.map((c) => _PickerItem(c.name, Icons.label_rounded)).toList(),
            onSelected: (i) {
              ref.read(selectedCategoryProvider.notifier).state = cats[i];
              Navigator.pop(context);
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
        );
      }),
    );
  }

  void _showPicker({required String title, required Widget child}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
            ),
          ),
          Flexible(child: child),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper data classes & widgets
// ─────────────────────────────────────────────────────────────────────────────

class _TxType {
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  const _TxType(this.key, this.label, this.icon, this.color);
}

class _PickerItem {
  final String name;
  final IconData icon;
  const _PickerItem(this.name, this.icon);
}

class _PickerList extends StatelessWidget {
  final List<_PickerItem> items;
  final void Function(int index) onSelected;

  const _PickerList({required this.items, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: items.length,
      itemBuilder: (_, i) {
        return ListTile(
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(items[i].icon, color: const Color(0xFF6366F1), size: 18),
          ),
          title: Text(
            items[i].name,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          onTap: () => onSelected(i),
        );
      },
    );
  }
}
