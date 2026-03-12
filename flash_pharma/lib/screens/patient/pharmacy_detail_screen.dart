import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/pharmacy.dart';
import '../../models/inventory_item.dart';
import '../../models/cart_item.dart';
import '../../services/pharmacy_service.dart';
import '../../services/inventory_service.dart';
import '../../providers/cart_provider.dart';
import 'package:provider/provider.dart';

class PharmacyDetailScreen extends StatefulWidget {
  final String pharmacyId;
  const PharmacyDetailScreen({super.key, required this.pharmacyId});

  @override
  State<PharmacyDetailScreen> createState() => _PharmacyDetailScreenState();
}

class _PharmacyDetailScreenState extends State<PharmacyDetailScreen> {
  final PharmacyService _pharmacyService = PharmacyService();
  final InventoryService _inventoryService = InventoryService();
  Pharmacy? _pharmacy;
  List<InventoryItem> _inventory = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _pharmacyService.getPharmacyDetails(widget.pharmacyId),
        _inventoryService.getInventory(),
      ]);
      _pharmacy = results[0] as Pharmacy;
      _inventory = results[1] as List<InventoryItem>;
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  List<InventoryItem> get _filteredInventory {
    if (_searchQuery.isEmpty) return _inventory;
    return _inventory
        .where((item) => item.medicine.name
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_pharmacy == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Pharmacy not found')),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            leading: IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryGreen, AppTheme.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      const CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.local_pharmacy_rounded,
                            color: Colors.white, size: 36),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _pharmacy!.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _pharmacy!.address,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Info Strip
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _InfoChip(
                    icon: Icons.star_rounded,
                    iconColor: AppTheme.accentOrange,
                    label: _pharmacy!.rating.toStringAsFixed(1),
                    sublabel: '${_pharmacy!.totalRatings} ratings',
                  ),
                  _InfoChip(
                    icon: Icons.access_time_rounded,
                    iconColor: AppTheme.secondaryBlue,
                    label:
                        '${_pharmacy!.openTime} - ${_pharmacy!.closeTime}',
                    sublabel: _pharmacy!.isOpen ? 'Open Now' : 'Closed',
                  ),
                  _InfoChip(
                    icon: Icons.delivery_dining_rounded,
                    iconColor: AppTheme.primaryGreen,
                    label: '₹${_pharmacy!.deliveryFee.toStringAsFixed(0)}',
                    sublabel: 'Delivery fee',
                  ),
                ],
              ),
            ),
          ),

          // Search
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search in this pharmacy...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.divider),
                  ),
                ),
              ),
            ),
          ),

          // Inventory
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Text(
                '${_filteredInventory.length} medicines available',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = _filteredInventory[index];
                return _MedicineItemTile(
                  item: item,
                  pharmacyId: _pharmacy!.id,
                  pharmacyName: _pharmacy!.name,
                );
              },
              childCount: _filteredInventory.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String sublabel;

  const _InfoChip({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        Text(sublabel,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }
}

class _MedicineItemTile extends StatelessWidget {
  final InventoryItem item;
  final String pharmacyId;
  final String pharmacyName;

  const _MedicineItemTile({
    required this.item,
    required this.pharmacyId,
    required this.pharmacyName,
  });

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.medication_rounded,
                color: AppTheme.primaryGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.medicine.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${item.medicine.strength} • ${item.medicine.dosageForm}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${item.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
          if (item.inStock)
            SizedBox(
              height: 36,
              child: ElevatedButton(
                onPressed: () {
                  cart.addItem(CartItem(
                    medicineId: item.medicine.id,
                    medicineName: item.medicine.name,
                    medicineImageUrl: item.medicine.imageUrl,
                    pharmacyId: pharmacyId,
                    pharmacyName: pharmacyName,
                    unitPrice: item.price,
                  ));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${item.medicine.name} added to cart'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  textStyle: const TextStyle(fontSize: 13),
                ),
                child: const Text('Add'),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Out of Stock',
                style: TextStyle(
                  color: AppTheme.errorRed,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
