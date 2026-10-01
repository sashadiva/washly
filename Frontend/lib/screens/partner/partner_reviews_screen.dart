import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/partner_profile.dart';
import '../../services/partner_service.dart';
import '../../theme/app_theme.dart';

/// A list of the partner's customer reviews, with a tap-to-view detail sheet.
class PartnerReviewsScreen extends StatefulWidget {
  const PartnerReviewsScreen({super.key});

  @override
  State<PartnerReviewsScreen> createState() => _PartnerReviewsScreenState();
}

class _PartnerReviewsScreenState extends State<PartnerReviewsScreen> {
  final _service = PartnerService();
  late Future<List<PartnerReview>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.reviews();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _service.reviews();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.partnerReviewsTitle)),
      body: FutureBuilder<List<PartnerReview>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('${snapshot.error}'.replaceFirst('Exception: ', ''),
                  style: AppTypography.body),
            );
          }
          final reviews = snapshot.data ?? [];
          if (reviews.isEmpty) {
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(
                      child: Text(l10n.partnerReviewsEmpty,
                          style: AppTypography.body)),
                ],
              ),
            );
          }
          final avg =
              reviews.map((r) => r.rating).reduce((a, b) => a + b) /
                  reviews.length;
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, color: AppColors.ratingStar),
                    const SizedBox(width: AppSpacing.xs),
                    Text(avg.toStringAsFixed(1),
                        style: AppTypography.heading2),
                    Text(l10n.partnerReviewsCount(reviews.length),
                        style: AppTypography.caption),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                ...reviews.map(_reviewCard),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _reviewCard(PartnerReview r) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () => _openReview(r),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryLight,
              child: Text(
                r.userName.isNotEmpty ? r.userName[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: AppColors.primaryDark, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(r.userName,
                            style: AppTypography.subheading,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      _stars(r.rating),
                    ],
                  ),
                  if (r.comment != null && r.comment!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(r.comment!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  void _openReview(PartnerReview r) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    r.userName.isNotEmpty ? r.userName[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.userName, style: AppTypography.heading2),
                      Text(_formatDate(r.createdAt),
                          style: AppTypography.caption),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _stars(r.rating, size: 22),
            const SizedBox(height: AppSpacing.md),
            Text(
              (r.comment != null && r.comment!.isNotEmpty)
                  ? r.comment!
                  : l10n.partnerReviewsNoComment,
              style: AppTypography.body,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _stars(int rating, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          i < rating ? Icons.star : Icons.star_border,
          size: size,
          color: AppColors.ratingStar,
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final local = d.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }
}
