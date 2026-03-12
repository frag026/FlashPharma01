import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/inventory_item.dart';
import '../../services/inventory_service.dart';

class PharmacyInventoryScreen extends StatefulWidget {
  const PharmacyInventoryScreen({super.key});

  @override
  State<PharmacyInventoryScreen> createState() =>
      _PharmacyInventoryScreenState();
}

class _PharmacyInventoryScreenState extends State<PharmacyInventoryScreen> {
  final InventoryService _inventoryService = InventoryService();
  List<InventoryItem> _items = [];
  List<InventoryItem> _filteredItems = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterCategory = 'All';

  final List<String> _categories = [
    'All', 'Tablets', 'Capsules', 'Syrups', 'Injections',
    'Ointments', 'Drops', 'Supplements', 'Devices',
  ];

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    setState(() => _isLoading = true);
    try {
      final items = await _inventoryService.getInventory();
      if (mounted) {
        setState(() {
          _items = items;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    _filteredItems = _items.where((item) {
      final matchesSearch =
          item.medicine.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _filterCategory == 'All' || item.medicine.category == _filterCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  void _showAddEditDialog({InventoryItem? item}) {
    final isEdit = item != null;
    final nameCtrl = TextEditingController(text: item?.medicine.name ?? '');
    final priceCtrl = TextEditingController(
        text: item != null ? item.price.toStringAsFixed(2) : '');
    final stockCtrl = TextEditingController(
        text: item != null ? item.quantity.toString() : '');
    final batchCtrl = TextEditingController(text: item?.batchNumber ?? '');
    final mfgCtrl = TextEditingController(text: item?.medicine.manufacturer ?? '');
    String selectedCategory = item?.medicine.category ?? 'Tablets';
    bool requiresPrescription = item?.medicine.requiresPrescription ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isEdit ? 'Edit Medicine' : 'Add Medicine',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Medicine Name *',
                        prefixIcon: Icon(Icons.medication_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: priceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Price (₹) *',
                              prefixIcon: Icon(Icons.currency_rupee),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: stockCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Stock Qty *',
                              prefixIcon: Icon(Icons.inventory_2_rounded),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      items: _categories
                          .where((c) => c != 'All')
                          .map((c) =>
                              DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) =>
                          setSheetState(() => selectedCategory = val!),
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: batchCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Batch Number',
                        prefixIcon: Icon(Icons.qr_code_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: mfgCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Manufacturer',
                        prefixIcon: Icon(Icons.factory_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: requiresPrescription,
                      onChanged: (val) =>
                          setSheetState(() => requiresPrescription = val),
                      title: const Text('Requires Prescription'),
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppTheme.primaryGreen,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (nameCtrl.text.isEmpty ||
                              priceCtrl.text.isEmpty ||
                              stockCtrl.text.isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                  content: Text('Fill required fields')),
                            );
                            return;
                          }

                          Navigator.pop(ctx);

                          try {
                            if (isEdit) {
                              await _inventoryService.updateItem(
                                item!.id,
                                price: double.tryParse(priceCtrl.text),
                                quantity: int.tryParse(stockCtrl.text),
                                batchNumber: batchCtrl.text.trim(),
                              );
                            } else {
                              await _inventoryService.addItem(
                                medicineName: nameCtrl.text.trim(),
                                genericName: '',
                                manufacturer: mfgCtrl.text.trim(),
                                category: selectedCategory,
                                dosageForm: selectedCategory,
                                strength: '',
                                price: double.tryParse(priceCtrl.text) ?? 0,
                                quantity: int.tryParse(stockCtrl.text) ?? 0,
                                batchNumber: batchCtrl.text.trim(),
                                expiryDate: DateTime.now().add(const Duration(days: 365)),
                                requiresPrescription: requiresPrescription,
                              );
                            }
                            _loadInventory();
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                        child: Text(isEdit ? 'Update' : 'Add Medicine'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteItem(InventoryItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Medicine'),
        content:
            Text('Remove "${item.medicine.name}" from inventory?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _inventoryService.deleteItem(item.id);
        _loadInventory();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lowStock = _items.where((i) => i.quantity < 10).length;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Inventory',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                if (lowStock > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            size: 14, color: AppTheme.accentOrange),
                        const SizedBox(width: 4),
                        Text(
                          '$lowStock low',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.accentOrange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                  _applyFilters();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search medicines...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppTheme.backgroundGrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Category chips
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final cat = _categories[index];
                final isSelected = _filterCategory == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _filterCategory = cat;
                      _applyFilters();
                    });
                  },
                  selectedColor: AppTheme.primaryGreen,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Inventory count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '${_filteredItems.length} medicines',
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13),
            ),
          ),
          const SizedBox(height: 8),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredItems.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                size: 48, color: AppTheme.textHint),
                            SizedBox(height: 12),
                            Text('No medicines found',
                                style: TextStyle(color: AppTheme.textSecondary)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadInventory,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                          itemCount: _filteredItems.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, index) {
                            final item = _filteredItems[index];
                            return _InventoryCard(
                              item: item,
                              onEdit: () => _showAddEditDialog(item: item),
                              onDelete: () => _deleteItem(item),
                              onUpdateStock: (qty) async {
                                await _inventoryService.updateItem(
                                    item.id, quantity: qty);
                                _loadInventory();
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Future<void> Function(int) onUpdateStock;

  const _InventoryCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onUpdateStock,
  });

  @override
  Widget build(BuildContext context) {
    final isLowStock = item.quantity < 10;
    final isOutOfStock = item.quantity == 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOutOfStock
              ? AppTheme.errorRed.withValues(alpha: 0.5)
              : isLowStock
                  ? AppTheme.accentOrange.withValues(alpha: 0.5)
                  : AppTheme.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.medicine.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    if (item.medicine.manufacturer.isNotEmpty)
                      Text(
                        item.medicine.manufacturer,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textHint),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
                onSelected: (val) {
                  if (val == 'edit') onEdit();
                  if (val == 'delete') onDelete();
                },
                icon: const Icon(Icons.more_vert, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _InfoChip(
                icon: Icons.currency_rupee,
                label: '₹${item.price.toStringAsFixed(0)}',
                color: AppTheme.primaryGreen,
              ),
              const SizedBox(width: 8),
              _InfoChip(
                icon: Icons.inventory_2_rounded,
                label: '${item.quantity} in stock',
                color: isOutOfStock
                    ? AppTheme.errorRed
                    : isLowStock
                        ? AppTheme.accentOrange
                        : AppTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              _InfoChip(
                icon: Icons.category_outlined,
                label: item.medicine.category,
                color: AppTheme.secondaryBlue,
              ),
            ],
          ),
          if (item.medicine.requiresPrescription) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Rx Required',
                style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.errorRed,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
          const SizedBox(height: 10),
          // Quick stock adjustment
          Row(
            children: [
              const Text('Stock: ',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              IconButton(
                onPressed: item.quantity > 0
                    ? () => onUpdateStock(item.quantity - 1)
                    : null,
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
                color: AppTheme.errorRed,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '${item.quantity}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              IconButton(
                onPressed: () => onUpdateStock(item.quantity + 1),
                icon: const Icon(Icons.add_circle_outline, size: 20),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
                color: AppTheme.primaryGreen,
              ),
              const Spacer(),
              if (item.batchNumber.isNotEmpty)
                Text(
                  'Batch: ${item.batchNumber}',
                  style:
                      const TextStyle(fontSize: 11, color: AppTheme.textHint),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
