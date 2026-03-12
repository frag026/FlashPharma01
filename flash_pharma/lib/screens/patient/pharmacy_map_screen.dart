import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/pharmacy.dart';
import '../../services/pharmacy_service.dart';
import '../../services/location_service.dart';

class PharmacyMapScreen extends StatefulWidget {
  const PharmacyMapScreen({super.key});

  @override
  State<PharmacyMapScreen> createState() => _PharmacyMapScreenState();
}

class _PharmacyMapScreenState extends State<PharmacyMapScreen> {
  final PharmacyService _pharmacyService = PharmacyService();
  final LocationService _locationService = LocationService();
  List<Pharmacy> _pharmacies = [];
  bool _isLoading = true;
  Pharmacy? _selectedPharmacy;

  @override
  void initState() {
    super.initState();
    _loadPharmacies();
  }

  Future<void> _loadPharmacies() async {
    setState(() => _isLoading = true);
    try {
      final pos = await _locationService.getCurrentLocation();
      if (pos != null) {
        _pharmacies = await _pharmacyService.getNearbyPharmacies(
          latitude: pos.latitude,
          longitude: pos.longitude,
        );
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Pharmacies'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_rounded),
            onPressed: () => _showListView(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map placeholder (Mapbox integration)
          Container(
            color: AppTheme.bgLight,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map_rounded,
                          size: 80,
                          color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Map View',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_pharmacies.length} pharmacies nearby',
                          style: const TextStyle(color: AppTheme.textHint),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Mapbox map integration goes here.\nPharmacy markers will be displayed on the map.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),

          // Bottom pharmacy cards
          if (_pharmacies.isNotEmpty && !_isLoading)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 180,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _pharmacies.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    return _PharmacyMapCard(
                      pharmacy: _pharmacies[index],
                      isSelected: _selectedPharmacy == _pharmacies[index],
                      onTap: () {
                        setState(() => _selectedPharmacy = _pharmacies[index]);
                      },
                    );
                  },
                ),
              ),
            ),

          // Re-center button
          Positioned(
            right: 16,
            bottom: 200,
            child: FloatingActionButton.small(
              heroTag: 'recenter',
              onPressed: _loadPharmacies,
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location_rounded,
                  color: AppTheme.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  void _showListView(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.3,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Row(
                    children: [
                      const Text(
                        'All Pharmacies',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_pharmacies.length} found',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _pharmacies.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final p = _pharmacies[index];
                      return _PharmacyListTile(pharmacy: p);
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _PharmacyMapCard extends StatelessWidget {
  final Pharmacy pharmacy;
  final bool isSelected;
  final VoidCallback onTap;

  const _PharmacyMapCard({
    required this.pharmacy,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : AppTheme.divider,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.local_pharmacy_rounded,
                      color: AppTheme.primaryGreen, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pharmacy.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${pharmacy.distance.toStringAsFixed(1)} km away',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              pharmacy.address,
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star_rounded,
                    size: 16, color: AppTheme.accentOrange),
                const SizedBox(width: 4),
                Text(
                  pharmacy.rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: pharmacy.isOpen
                        ? AppTheme.successGreen.withValues(alpha: 0.1)
                        : AppTheme.errorRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    pharmacy.isOpen ? 'Open' : 'Closed',
                    style: TextStyle(
                      color: pharmacy.isOpen
                          ? AppTheme.successGreen
                          : AppTheme.errorRed,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PharmacyListTile extends StatelessWidget {
  final Pharmacy pharmacy;
  const _PharmacyListTile({required this.pharmacy});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.local_pharmacy_rounded,
            color: AppTheme.primaryGreen),
      ),
      title: Text(
        pharmacy.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${pharmacy.distance.toStringAsFixed(1)} km • ${pharmacy.address}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded,
                  size: 14, color: AppTheme.accentOrange),
              const SizedBox(width: 2),
              Text(
                pharmacy.rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            pharmacy.isOpen ? 'Open' : 'Closed',
            style: TextStyle(
              fontSize: 11,
              color:
                  pharmacy.isOpen ? AppTheme.successGreen : AppTheme.errorRed,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      onTap: () {
        Navigator.pushNamed(context, '/pharmacy-details',
            arguments: pharmacy.id);
      },
    );
  }
}
