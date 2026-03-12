import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/search_result.dart';
import '../../services/search_service.dart';
import '../../services/location_service.dart';

class MedicineSearchDelegate extends SearchDelegate<String> {
  final SearchService _searchService = SearchService();
  final LocationService _locationService = LocationService();

  MedicineSearchDelegate()
      : super(
          searchFieldLabel: 'Search medicines...',
          searchFieldStyle: const TextStyle(
            fontSize: 16,
            color: AppTheme.textPrimary,
          ),
        );

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: AppTheme.textHint),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear_rounded),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) return const SizedBox.shrink();
    return _SearchResults(
      query: query,
      searchService: _searchService,
      locationService: _locationService,
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _buildTrendingSuggestions();
    }
    return FutureBuilder<List<String>>(
      future: _searchService.getSuggestions(query),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final suggestion = snapshot.data![index];
            return ListTile(
              leading: const Icon(Icons.search_rounded,
                  color: AppTheme.textHint, size: 20),
              title: Text(suggestion),
              onTap: () {
                query = suggestion;
                showResults(context);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTrendingSuggestions() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Popular Searches',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Dolo 650',
              'Crocin',
              'Vitamin C',
              'Azithromycin',
              'Pantoprazole',
              'Cetirizine',
            ].map((name) {
              return ActionChip(
                label: Text(name, style: const TextStyle(fontSize: 13)),
                onPressed: () {
                  query = name;
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  final String query;
  final SearchService searchService;
  final LocationService locationService;

  const _SearchResults({
    required this.query,
    required this.searchService,
    required this.locationService,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SearchResult>>(
      future: searchService.searchMedicines(
        query: query,
        latitude: locationService.latitude,
        longitude: locationService.longitude,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppTheme.textHint),
                const SizedBox(height: 12),
                const Text('Something went wrong'),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    (context as Element).markNeedsBuild();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final results = snapshot.data ?? [];
        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off_rounded,
                    size: 64, color: AppTheme.textHint),
                const SizedBox(height: 16),
                Text(
                  'No results for "$query"',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Try a different search term',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: results.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final result = results[index];
            return _SearchResultCard(result: result);
          },
        );
      },
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final SearchResult result;
  const _SearchResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
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
                        result.medicineName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '${result.genericName} • ${result.manufacturer}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (result.requiresPrescription)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.warningYellow.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Rx',
                      style: TextStyle(
                        color: AppTheme.warningYellow,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            if (result.pharmacies.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Text(
                'Available at ${result.pharmacies.length} pharmacies nearby',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              ...result.pharmacies.take(3).map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.storefront_rounded,
                            size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            p.pharmacyName,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(
                          '₹${p.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${p.distance.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
