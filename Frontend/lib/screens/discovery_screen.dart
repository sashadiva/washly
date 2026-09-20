import 'package:flutter/material.dart';
import '../models/laundromat.dart';
import '../services/laundromat_service.dart';
import '../theme/app_theme.dart';
import 'laundromat_detail_screen.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final _service = LaundromatService();
  final _selectedTags = <String>{};
  String _currentSort = 'rating';
  late Future<List<Laundromat>> _laundromatsFuture;

  static const _allTags = [
    'Shoes',
    'Bags',
    'Dolls',
    'Costumes',
    'Express',
    'Ironing',
    'Kiloan',
    'Dry Clean',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _laundromatsFuture = _service.fetchLaundromats(
        selectedTags: _selectedTags.map((e) => e.toLowerCase()).toList(),
        sortBy: _currentSort,
        lat: -6.200000,
        lng: 106.780000,
      );
    });
  }

  void _showFilterModal() {
    final tempSelected = Set<String>.from(_selectedTags);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.pill)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Filter Services', style: AppTypography.heading2),
                  TextButton(
                    onPressed: () => setSheetState(() => tempSelected.clear()),
                    child: Text(
                      'Reset',
                      style: AppTypography.subheading.copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              const Divider(color: AppColors.border),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _allTags.map((tag) {
                  final isSelected = tempSelected.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    selectedColor: AppColors.primaryLight,
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                    onSelected: (val) {
                      setSheetState(() {
                        val ? tempSelected.add(tag) : tempSelected.remove(tag);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedTags
                        ..clear()
                        ..addAll(tempSelected);
                      _loadData();
                    });
                    Navigator.pop(ctx);
                  },
                  child: Text('Apply Filters (${tempSelected.length})'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Washly', style: AppTypography.heading1),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _showFilterModal,
                  icon: const Icon(Icons.tune, size: 18),
                  label: Text(
                    _selectedTags.isEmpty
                        ? 'Filter Services'
                        : 'Services (${_selectedTags.length})',
                  ),
                ),
                const Spacer(),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _currentSort,
                    style: AppTypography.subheading,
                    items: const [
                      DropdownMenuItem(value: 'rating', child: Text('Top Rated')),
                      DropdownMenuItem(value: 'distance', child: Text('Nearest')),
                    ],
                    onChanged: (val) {
                      if (val == null) return;
                      _currentSort = val;
                      _loadData();
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Laundromat>>(
              future: _laundromatsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}', style: AppTypography.body),
                  );
                }
                final stores = snapshot.data ?? [];
                if (stores.isEmpty) {
                  return const Center(
                    child: Text('No laundromats found.', style: AppTypography.body),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                  itemCount: stores.length,
                  itemBuilder: (_, i) => LaundromatListingCard(store: stores[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class LaundromatListingCard extends StatelessWidget {
  final Laundromat store;
  const LaundromatListingCard({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LaundromatDetailScreen(laundromatId: store.id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 160,
              width: double.infinity,
              child: store.imageUrl != null && store.imageUrl!.isNotEmpty
                  ? Image.network(
                      store.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(store.name, style: AppTypography.heading2),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: AppColors.ratingStar),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        store.rating.toStringAsFixed(1),
                        style: AppTypography.subheading,
                      ),
                      Text(' (${store.reviewCount})', style: AppTypography.caption),
                      if (store.distanceKm != null) ...[
                        Text(
                          '  •  ',
                          style: TextStyle(
                            color: AppColors.border,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${store.distanceKm} km',
                          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    store.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: store.tags.map((tag) => _buildTagPill(tag)).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() => Container(
        color: AppColors.primaryLight,
        child: const Center(
          child: Icon(Icons.local_laundry_service, size: 50, color: AppColors.primary),
        ),
      );

  Widget _buildTagPill(String tag) => Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          tag.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
      );
}