import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyatet_pesse/features/transactions/presentation/providers/add_transaction_controller.dart';
import 'package:nyatet_pesse/features/categories/presentation/widgets/add_category_bottom_sheet.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Kategori', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pengeluaran'),
            Tab(text: 'Pemasukan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoryList('EXPENSE'),
          _buildCategoryList('INCOME'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final isIncome = _tabController.index == 1;
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => AddCategoryBottomSheet(type: isIncome ? 'INCOME' : 'EXPENSE'),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryList(String type) {
    return Consumer(
      builder: (context, ref, child) {
        final categoriesAsync = ref.watch(categoriesStreamProvider(type));
        
        return categoriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text(e.toString())),
          data: (categories) {
            if (categories.isEmpty) {
              return const Center(child: Text('Belum ada kategori'));
            }
            
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: categories.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final cat = categories[index];
                
                IconData iconData = Icons.category;
                if (cat.icon == 'restaurant') iconData = Icons.restaurant;
                if (cat.icon == 'directions_car') iconData = Icons.directions_car;
                if (cat.icon == 'shopping_bag') iconData = Icons.shopping_bag;
                if (cat.icon == 'payments') iconData = Icons.payments;
                if (cat.icon == 'arrow_upward') iconData = Icons.arrow_upward;
                if (cat.icon == 'arrow_downward') iconData = Icons.arrow_downward;
                
                Color iconColor = Colors.grey;
                try {
                   iconColor = Color(int.parse(cat.color ?? 'FF9E9E9E', radix: 16));
                } catch (e) {
                   // fallback
                }
                
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  leading: CircleAvatar(
                    backgroundColor: iconColor.withValues(alpha: 0.1),
                    child: Icon(iconData, color: iconColor),
                  ),
                  title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                  trailing: cat.isCustom 
                      ? IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () {
                            // Delete logic later
                          },
                        )
                      : const SizedBox.shrink(),
                );
              },
            );
          },
        );
      },
    );
  }
}
