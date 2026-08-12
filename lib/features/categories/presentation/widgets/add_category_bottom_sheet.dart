import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyatet_pesse/features/categories/presentation/providers/categories_controller.dart';

class AddCategoryBottomSheet extends ConsumerStatefulWidget {
  final String type; // 'INCOME' or 'EXPENSE'
  
  const AddCategoryBottomSheet({super.key, required this.type});

  @override
  ConsumerState<AddCategoryBottomSheet> createState() => _AddCategoryBottomSheetState();
}

class _AddCategoryBottomSheetState extends ConsumerState<AddCategoryBottomSheet> {
  final _nameController = TextEditingController();
  
  // Hardcoded for MVP, user can pick from a list in the future
  String _selectedIcon = 'category';
  String _selectedColor = 'FF2196F3';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoriesControllerProvider);
    final isIncome = widget.type == 'INCOME';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tambah Kategori ${isIncome ? 'Pemasukan' : 'Pengeluaran'}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nama Kategori',
              hintText: 'Contoh: Bonus, Sedekah, Hiburan',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Simple icon/color selector for MVP
          Text('Ikon & Warna (Otomatis untuk saat ini)', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 8),
          Row(
            children: [
               CircleAvatar(
                 backgroundColor: isIncome ? Colors.green.shade100 : Colors.red.shade100,
                 child: Icon(Icons.category, color: isIncome ? Colors.green : Colors.red),
               ),
               const SizedBox(width: 16),
               Expanded(
                 child: Text('Di versi mendatang, Anda bisa memilih ikon dan warna sendiri.', style: Theme.of(context).textTheme.bodySmall),
               ),
            ],
          ),
          
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: state.isLoading ? null : () async {
                final name = _nameController.text.trim();
                
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama kategori wajib diisi')));
                  return;
                }
                
                _selectedColor = isIncome ? 'FF4CAF50' : 'FFF44336';
                
                final success = await ref.read(categoriesControllerProvider.notifier).saveCategory(
                  name: name,
                  type: widget.type,
                  icon: _selectedIcon,
                  color: _selectedColor,
                );
                
                if (!context.mounted) return;
                
                if (success) {
                  Navigator.pop(context);
                } else {
                  final err = ref.read(categoriesControllerProvider).error;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $err')));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: state.isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Simpan Kategori', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
