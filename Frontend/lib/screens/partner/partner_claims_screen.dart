import 'package:flutter/material.dart';
import '../../models/warranty.dart';
import '../../services/warranty_service.dart';
import '../../theme/app_theme.dart';

/// Partner warranty claims: review and resolve (approve/reject/resolve).
class PartnerClaimsScreen extends StatefulWidget {
  const PartnerClaimsScreen({super.key});

  @override
  State<PartnerClaimsScreen> createState() => _PartnerClaimsScreenState();
}

class _PartnerClaimsScreenState extends State<PartnerClaimsScreen> {
  final _service = WarrantyService();
  late Future<List<WarrantyClaim>> _future;
  int? _busyClaimId;

  @override
  void initState() {
    super.initState();
    _future = _service.partnerClaims();
  }

  Future<void> _reload() async {
    setState(() => _future = _service.partnerClaims());
    await _future;
  }

  Future<void> _resolve(WarrantyClaim c, String status) async {
    final noteCtrl = TextEditingController();
    final payoutCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('$status claim', style: AppTypography.heading2),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: 'Resolution note'),
              maxLines: 2,
            ),
            if (status != 'REJECTED') ...[
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: payoutCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Payout amount (optional)',
                  prefixText: 'Rp ',
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(dctx, true),
              child: const Text('Confirm')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busyClaimId = c.id);
    try {
      await _service.resolveClaim(
        c.id,
        status: status,
        note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
        payoutAmount:
            status == 'REJECTED' ? null : double.tryParse(payoutCtrl.text.trim()),
      );
      if (!mounted) return;
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'.replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _busyClaimId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Warranty Claims')),
      body: FutureBuilder<List<WarrantyClaim>>(
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
          final claims = snapshot.data!;
          if (claims.isEmpty) {
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(child: Text('No claims.', style: AppTypography.body)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: claims.length,
              itemBuilder: (context, i) => _claimCard(claims[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _claimCard(WarrantyClaim c) {
    final busy = _busyClaimId == c.id;
    final open = c.status == 'SUBMITTED';
    return Card(
      elevation: 0,
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Order #${c.orderId}',
                      style: AppTypography.heading2),
                ),
                Text(c.status, style: AppTypography.caption),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(c.declaredItem?.label ?? 'Item #${c.declaredItemId}',
                style: AppTypography.subheading),
            const SizedBox(height: AppSpacing.xs),
            Text(c.description, style: AppTypography.body),
            if (c.photoUrls.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text('${c.photoUrls.length} photo(s) attached',
                    style: AppTypography.caption),
              ),
            if (open) ...[
              const SizedBox(height: AppSpacing.md),
              if (busy)
                const Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _resolve(c, 'REJECTED'),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _resolve(c, 'APPROVED'),
                        child: const Text('Approve'),
                      ),
                    ),
                  ],
                ),
            ] else if (c.resolutionNote != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text('Resolution: ${c.resolutionNote}',
                    style: AppTypography.caption),
              ),
          ],
        ),
      ),
    );
  }
}
