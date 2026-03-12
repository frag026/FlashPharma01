import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/pharmacy.dart';
import '../../services/pharmacy_service.dart';
import '../../services/location_service.dart';

class NearbyPharmaciesScreen extends StatefulWidget {
  const NearbyPharmaciesScreen({super.key});

  @override
  State<NearbyPharmaciesScreen> createState() => _NearbyPharmaciesScreenState();
}

class _NearbyPharmaciesScreenState extends State<NearbyPharmaciesScreen> {
  final PharmacyService _pharmacyService = PharmacyService();
  final LocationService _locationService = LocationService();
  List<Pharmacy>? _pharmacies;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPharmacies();
  }

  Future<void> _loadPharmacies() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _locationService.getCurrentLocation();
      final pharmacies = await _pharmacyService.getNearbyPharmacies(
        latitude: _locationService.latitude,
        longitude: _locationService.longitude,
      );
      if (mounted) {
        setState(() {
          _pharmacies = pharmacies;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load pharmacies';
          _isLoading = false;
        });
      }
    }
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
            icon: const Icon(Icons.map_outlined),
            onPressed: () => Navigator.pushNamed(context, '/pharmacy-map'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppTheme.textHint),
                      const SizedBox(height: 12),
                      Text(_error!),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _loadPharmacies,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPharmacies,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _pharmacies?.length ?? 0,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final pharmacy = _pharmacies![index];
                      return _PharmacyListItem(
                        pharmacy: pharmacy,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/pharmacy-details',
                            arguments: pharmacy.id,
                          );
                        },
                      );
                    },
                  ),
                ),
    );
  }
}

class _PharmacyListItem extends StatelessWidget {
  final Pharmacy pharmacy;
  final VoidCallback onTap;

  const _PharmacyListItem({required this.pharmacy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: pharmacy.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(pharmacy.imageUrl!, fit: BoxFit.cover),
                    )
                  : const Icon(Icons.local_pharmacy_rounded,
                      color: AppTheme.primaryGreen, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          pharmacy.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
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
                  const SizedBox(height: 4),
                  Text(
                    pharmacy.address,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 16, color: AppTheme.accentOrange),
                      const SizedBox(width: 4),
                      Text(
                        '${pharmacy.rating}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        ' (${pharmacy.totalRatings})',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.location_on,
                          size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 2),
                      Text(
                        '${pharmacy.distance.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.delivery_dining_rounded,
                          size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 2),
                      Text(
                        pharmacy.deliveryFee > 0
                            ? '₹${pharmacy.deliveryFee.toStringAsFixed(0)}'
                            : 'Free',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w600,
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
}
