import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/laundromat.dart';
import '../../services/laundromat_service.dart';
import '../../theme/app_theme.dart';
import '../discovery_screen.dart';

/// A focused search screen. Opens with the keyboard up. The user types a query
/// and submits it; only then do the filter + sort controls and the matching
/// results appear. Matches by name, attributes (tags), or area.
class LaundromatSearchScreen extends StatefulWidget {
  const LaundromatSearchScreen({super.key});

  @override
  State<LaundromatSearchScreen> createState() => _LaundromatSearchScreenState();
}

class _LaundromatSearchScreenState extends State<LaundromatSearchScreen> {
  final _service = LaundromatService();
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  late Future<List<Laundromat>> _future;
  List<Laundromat> _all = [];

  /// The query that has actually been submitted (drives results + controls).
  String _submittedQuery = '';

  /// Active service/tag filters and current sort, applied post-submit.
  final _selectedTags = <String>{};
  String _sort = 'rating'; // 'rating' or 'distance'

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
    _future = _service.fetchLaundromats(
      sortBy: 'rating',
      lat: -6.200000,
      lng: 106.780000,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _hasSubmitted => _submittedQuery.trim().isNotEmpty;

  void _submit(String value) {
    setState(() => _submittedQuery = value);
    _focusNode.unfocus();
  }

  /// Filter by the submitted text (name / tags / area) and any selected tag
  /// filters, then sort.
  List<Laundromat> _results() {
    final q = _submittedQuery.trim().toLowerCase();
    var list = _all.where((s) {
      final name = s.name.toLowerCase();
      final area = (s.areaLabel ?? '').toLowerCase();
      final tags = s.tags.map((t) => t.toLowerCase());
      final matchesQuery = q.isEmpty ||
          name.contains(q) ||
          area.contains(q) ||
          tags.any((t) => t.contains(q));
      final matchesTags = _selectedTags.isEmpty ||
          _selectedTags.every(
            (sel) => tags.any((t) => t == sel.toLowerCase()),
          );
      return matchesQuery && matchesTags;
    }).toList();

    if (_sort == 'rating') {
      list.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_sort == 'distance') {
      list.sort((a, b) => (a.distanceKm ?? 1e9).compareTo(b.distanceKm ?? 1e9));
    }
    return list;
  }

  void _showFilterModal() {
    final l10n = AppLocalizations.of(context);
    final temp = Set<String>.from(_selectedTags);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.pill)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
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
                  Text(l10n.filterServices, style: AppTypography.heading2),
                  TextButton(
                    onPressed: () => setSheet(() => temp.clear()),
                    child: Text(l10n.filterReset,
                        style: AppTypography.subheading
                            .copyWith(color: AppColors.primary)),
                  ),
                ],
              ),
              const Divider(color: AppColors.border),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _allTags.map((tag) {
                  final selected = temp.contains(tag);
                  return FilterChip(
                    label: Text(serviceTagLabel(l10n, tag)),
                    selected: selected,
                    selectedColor: AppColors.primaryLight,
                    checkmarkColor: AppColors.primary,
                    side: BorderSide(
                      color: selected ? AppColors.primary : AppColors.border,
                    ),
                    onSelected: (v) => setSheet(
                        () => v ? temp.add(tag) : temp.remove(tag)),
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
                        ..addAll(temp);
                    });
                    Navigator.pop(ctx);
                  },
                  child: Text(l10n.filterApplyCount(temp.length)),
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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: AppSpacing.lg),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            textInputAction: TextInputAction.search,
            onSubmitted: _submit,
            // Rebuild for the clear button only; results wait for submit.
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: l10n.searchHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _controller.clear();
                        setState(() => _submittedQuery = '');
                        _focusNode.requestFocus();
                      },
                    ),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Laundromat>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  '${snapshot.error}'.replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: AppTypography.body,
                ),
              ),
            );
          }

          _all = snapshot.data ?? [];

          // Before submitting: prompt only, no filter/sort controls.
          if (!_hasSubmitted) {
            return _hint(l10n.searchPrompt);
          }

          final results = _results();
          return Column(
            children: [
              _filterSortBar(l10n),
              const Divider(height: 1, color: AppColors.border),
              Expanded(
                child: results.isEmpty
                    ? _hint(l10n.searchNoMatches)
                    : ListView.builder(
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        itemCount: results.length,
                        itemBuilder: (_, i) =>
                            LaundromatListingCard(store: results[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Filter + sort controls — only rendered after a search is submitted.
  Widget _filterSortBar(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Flexible(
            child: OutlinedButton.icon(
              onPressed: _showFilterModal,
              icon: const Icon(Icons.tune, size: 18),
              label: Text(
                _selectedTags.isEmpty
                    ? l10n.filterServices
                    : l10n.filterServicesCount(_selectedTags.length),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const Spacer(),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _sort,
              style: AppTypography.subheading,
              items: [
                DropdownMenuItem(
                    value: 'rating', child: Text(l10n.sortTopRated)),
                DropdownMenuItem(
                    value: 'distance', child: Text(l10n.sortNearest)),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _sort = v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _hint(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search, size: 40, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.md),
            Text(text,
                textAlign: TextAlign.center, style: AppTypography.body),
          ],
        ),
      ),
    );
  }
}
