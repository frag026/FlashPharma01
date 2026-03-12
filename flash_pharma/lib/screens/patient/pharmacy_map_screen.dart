import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/pharmacy.dart';
import '../../services/location_service.dart';

class PharmacyMapScreen extends StatefulWidget {
  const PharmacyMapScreen({super.key});

  @override
  State<PharmacyMapScreen> createState() => _PharmacyMapScreenState();
}

class _PharmacyMapScreenState extends State<PharmacyMapScreen> {
  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();
  List<Pharmacy> _pharmacies = [];
  bool _isLoading = true;
  Pharmacy? _selectedPharmacy;
  LatLng _userLocation = const LatLng(19.0760, 72.8777); // Default: Mumbai

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final pos = await _locationService.getCurrentLocation();
      if (pos != null) {
        _userLocation = LatLng(pos.latitude, pos.longitude);
      }
    } catch (_) {}

    // Demo pharmacies near user location
    _pharmacies = _generateDemoPharmacies(_userLocation);

    if (mounted) setState(() => _isLoading = false);
  }

  List<Pharmacy> _generateDemoPharmacies(LatLng center) {
    final offsets = [
      [0.005, 0.003, 'MedPlus Pharmacy', '4.5', true, 0.4],
      [-0.003, 0.006, 'Apollo Pharmacy', '4.2', true, 0.7],
      [0.007, -0.004, 'Wellness Forever', '4.7', true, 0.8],
      [-0.006, -0.005, 'Netmeds Store', '3.9', false, 1.1],
      [0.002, -0.008, 'PharmEasy Hub', '4.1', true, 0.9],
      [-0.008, 0.002, 'HealthKart Pharmacy', '4.3', true, 1.3],
    ];

    return offsets.asMap().entries.map((entry) {
      final i = entry.key;
      final o = entry.value;
      return Pharmacy(
        id: 'demo_$i',
        name: o[2] as String,
        ownerName: 'Owner $i',
        email: 'pharmacy$i@demo.com',
        phone: '+91 98765 ${43210 + i}',
        address: '${i + 1}, Demo Street, Near Main Road',
        latitude: center.latitude + (o[0] as double),
        longitude: center.longitude + (o[1] as double),
        licenseNumber: 'LIC-DEMO-$i',
        rating: double.parse(o[3] as String),
        isOpen: o[4] as bool,
        distance: o[5] as double,
      );
    }).toList();
  }

  void _centerOnUser() {
    _mapController.move(_userLocation, 15.0);
  }

  void _selectPharmacy(Pharmacy pharmacy) {
    setState(() => _selectedPharmacy = pharmacy);
    _mapController.move(
      LatLng(pharmacy.latitude, pharmacy.longitude),
      16.0,
    );
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
          // Real Map
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _userLocation,
                    initialZoom: 14.0,
                    onTap: (_, __) {
                      setState(() => _selectedPharmacy = null);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.flash_pharma',
                      maxZoom: 19,
                    ),
                    // User location marker
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _userLocation,
                          width: 30,
                          height: 30,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Pharmacy markers
                    MarkerLayer(
                      markers: _pharmacies.map((pharmacy) {
                        final isSelected = _selectedPharmacy == pharmacy;
                        return Marker(
                          point: LatLng(pharmacy.latitude, pharmacy.longitude),
                          width: isSelected ? 50 : 40,
                          height: isSelected ? 50 : 40,
                          child: GestureDetector(
                            onTap: () => _selectPharmacy(pharmacy),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryGreen
                                    : pharmacy.isOpen
                                        ? Colors.white
                                        : Colors.grey[300],
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.primaryGreen,
                                  width: isSelected ? 3 : 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.local_pharmacy_rounded,
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.primaryGreen,
                                size: isSelected ? 24 : 20,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
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
              onPressed: _centerOnUser,
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
