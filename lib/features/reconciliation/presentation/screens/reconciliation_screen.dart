import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:nyatet_pesse/core/theme/app_theme.dart';
import 'package:nyatet_pesse/data/database/app_database.dart';
import 'package:nyatet_pesse/data/repositories/repository_providers.dart';
import 'package:nyatet_pesse/features/transactions/presentation/providers/add_transaction_controller.dart';

class ReconciliationScreen extends ConsumerStatefulWidget {
  final Account? initialAccount;

  const ReconciliationScreen({super.key, this.initialAccount});

  @override
  ConsumerState<ReconciliationScreen> createState() => _ReconciliationScreenState();
}

class _ReconciliationScreenState extends ConsumerState<ReconciliationScreen> {
  final _actualController = TextEditingController();
  Account? _selectedAccount;
  bool _isSaving = false;

  static final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _selectedAccount = widget.initialAccount;
  }

  @override
  void dispose() {
    _actualController.dispose();
    super.dispose();
  }

  double? get _parsedActual {
    final raw = _actualController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  double get _difference =>
      (_parsedActual ?? _selectedAccount!.currentBalance) - _selectedAccount!.currentBalance;

  Future<void> _save() async {
    final actual = _parsedActual;
    final account = _selectedAccount;
    if (account == null || actual == null) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(reconciliationRepositoryProvider).reconcile(
            account: account,
            actualBalance: actual,
          );
      ref.invalidate(accountsStreamProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _difference == 0
                  ? 'Saldo sudah sesuai — rekonsiliasi dicatat.'
                  : 'Saldo disesuaikan (${_currency.format(_difference)}).',
            ),
            backgroundColor: AppTheme.income,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan rekonsiliasi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsStreamProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
              ),
            ),
            title: Text(
              'Rekonsiliasi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: -0.3,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  'Cocokkan saldo aplikasi dengan saldo aktual rekening Anda.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Pilih akun ──────────────────────────────────────────
                accountsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  error: (e, st) => Text('Gagal memuat akun: $e',
                      style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13)),
                  data: (accounts) {
                    if (_selectedAccount == null && accounts.isNotEmpty) {
                      _selectedAccount = accounts.first;
                    }
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Account>(
                          value: accounts.contains(_selectedAccount) ? _selectedAccount : null,
                          hint: const Text('Pilih akun'),
                          isExpanded: true,
                          items: accounts
                              .map((a) => DropdownMenuItem(
                                    value: a,
                                    child: Text(a.name, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
                                  ))
                              .toList(),
                          onChanged: (a) {
                            setState(() {
                              _selectedAccount = a;
                              _actualController.clear();
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                if (_selectedAccount != null) ...[
                  // ── Banner selisih ────────────────────────────────────
                  _buildDifferenceBanner(),

                  const SizedBox(height: 16),

                  // ── Saldo aplikasi ────────────────────────────────────
                  _buildBalanceCard(
                    label: 'Saldo Aplikasi',
                    value: _currency.format(_selectedAccount!.currentBalance),
                    accent: false,
                  ),
                  const SizedBox(height: 12),

                  // ── Input saldo sebenarnya ────────────────────────────
                  _buildActualInput(),
                  const SizedBox(height: 12),

                  // ── Selisih ───────────────────────────────────────────
                  _buildBalanceCard(
                    label: 'Selisih',
                    value: (_difference >= 0 ? '+Rp ' : '-Rp ') +
                        _currency.format(_difference.abs()).replaceFirst('Rp ', ''),
                    accent: true,
                    valueColor: _difference == 0
                        ? AppTheme.income
                        : (_difference > 0 ? AppTheme.transfer : AppTheme.expense),
                  ),

                  const SizedBox(height: 20),

                  // ── Tombol simpan ─────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _parsedActual == null || _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppTheme.primary.withValues(alpha: 0.4),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle_outline_rounded, size: 20),
                      label: Text(
                        _difference == 0 ? 'Catat Rekonsiliasi' : 'Sesuaikan & Catat',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                // ── Riwayat ─────────────────────────────────────────────
                Text(
                  'RIWAYAT REKONSILIASI',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                StreamBuilder<List<Reconciliation>>(
                  stream: ref.read(reconciliationRepositoryProvider).watchRecent(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    final items = snapshot.data!;
                    if (items.isEmpty) {
                      return Text(
                        'Belum ada riwayat rekonsiliasi.',
                        style: TextStyle(fontSize: 13, color: Theme.of(context).hintColor),
                      );
                    }
                    return Column(
                      children: items.map(_buildHistoryTile).toList(),
                    );
                  },
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifferenceBanner() {
    final mismatch = _actualController.text.isNotEmpty && _difference != 0;
    if (!mismatch) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.expense.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.expense.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppTheme.expense, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Saldo tidak sesuai. Periksa kembali transaksi Anda sebelum menyesuaikan.',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppTheme.expense,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard({
    required String label,
    required String value,
    required bool accent,
    Color? valueColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent
            ? AppTheme.primary.withValues(alpha: 0.05)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: accent ? Border.all(color: AppTheme.primary.withValues(alpha: 0.2)) : null,
        boxShadow: accent ? null : AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: valueColor ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActualInput() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(
            color: AppTheme.primary,
            width: 4,
          ),
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: TextField(
        controller: _actualController,
        onChanged: (_) => setState(() {}),
        keyboardType: const TextInputType.numberWithOptions(signed: false),
        inputFormatters: [ThousandsSeparatorInputFormatter()],
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          labelText: 'Saldo Sebenarnya',
          labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          prefixText: 'Rp ',
          prefixStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildHistoryTile(Reconciliation item) {
    final dateFmt = DateFormat('d MMM yyyy, HH:mm', 'id_ID');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: (item.difference == 0 ? AppTheme.income : AppTheme.transfer).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              item.difference == 0 ? Icons.check_rounded : Icons.tune_rounded,
              size: 17,
              color: item.difference == 0 ? AppTheme.income : AppTheme.transfer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.difference == 0
                      ? 'Saldo sudah sesuai'
                      : 'Disesuaikan ${_currency.format(item.difference)}',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateFmt.format(item.reconciledAt),
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Formatter ribuan titik untuk input saldo (mis. 3.250.000).
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final formatted = NumberFormat.decimalPattern('id_ID').format(int.parse(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
