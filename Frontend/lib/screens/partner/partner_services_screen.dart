import 'package:flutter/material.dart';
import '../../models/partner_profile.dart';
import '../../services/partner_service.dart';
import '../../theme/app_theme.dart';

/// Partner services editor: list, add, edit, and delete services.
class PartnerServicesScreen extends StatefulWidget {
  const PartnerServicesScreen({super.key});

  @override
  State<PartnerServicesScreen> createState() => _PartnerServicesScreenState();
}

class _PartnerServicesScreenState extends State<PartnerServicesScreen> {
  final _service = PartnerService();
  late Future<List<ShopService>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.services();
  }

  Future<void> _reload() async {
    setState(() => _future = _service.services());
    await _future;
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.error : null,
    ));
  }

  Future<void> _openEditor({ShopService? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => _ServiceEditorSheet(service: _service, existing: existing),
    );
    if (saved == true) _reload();
  }

  Future<void> _delete(ShopService s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete service?', style: AppTypography.heading2),
        content: Text('Remove "${s.name}"? This cannot be undone.',
            style: AppTypography.body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(dctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _service.deleteService(s.id);
      _snack('Service deleted.');
      _reload();
    } catch (e) {
      _snack('$e'.replaceFirst('Exception: ', ''), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Services')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('Add service'),
      ),
      body: FutureBuilder<List<ShopService>>(
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
          final services = snapshot.data!;
          if (services.isEmpty) {
            return Center(
              child: Text('No services yet. Add your first one.',
                  style: AppTypography.body),
            );
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: services.length,
              itemBuilder: (context, i) {
                final s = services[i];
                return Card(
                  elevation: 0,
                  color: AppColors.surface,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: ListTile(
                    title: Text(s.name, style: AppTypography.subheading),
                    subtitle: Text(
                      'Rp ${s.price.toStringAsFixed(0)} · ${s.isKilo ? 'per kg' : 'per item'}',
                      style: AppTypography.caption,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          color: AppColors.primary,
                          onPressed: () => _openEditor(existing: s),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          color: AppColors.error,
                          onPressed: () => _delete(s),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ServiceEditorSheet extends StatefulWidget {
  final PartnerService service;
  final ShopService? existing;
  const _ServiceEditorSheet({required this.service, this.existing});

  @override
  State<_ServiceEditorSheet> createState() => _ServiceEditorSheetState();
}

class _ServiceEditorSheetState extends State<_ServiceEditorSheet> {
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _price;
  late String _unit;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _desc = TextEditingController(text: e?.description ?? '');
    _price = TextEditingController(text: e != null ? e.price.toStringAsFixed(0) : '');
    _unit = e?.unit ?? 'PER_ITEM';
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final price = double.tryParse(_price.text.trim());
    if (name.isEmpty || price == null || price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a name and a valid price.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      if (widget.existing == null) {
        await widget.service.createService(
          name: name,
          description: _desc.text.trim(),
          price: price,
          unit: _unit,
        );
      } else {
        await widget.service.updateService(
          widget.existing!.id,
          name: name,
          description: _desc.text.trim(),
          price: price,
          unit: _unit,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'.replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: AppSpacing.lg + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.existing == null ? 'Add service' : 'Edit service',
              style: AppTypography.heading2),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Service name'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _desc,
            decoration:
                const InputDecoration(labelText: 'Description (optional)'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Price',
              prefixText: 'Rp ',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'PER_ITEM', label: Text('Per item')),
              ButtonSegment(value: 'PER_KG', label: Text('Per kg')),
            ],
            selected: {_unit},
            onSelectionChanged: (s) => setState(() => _unit = s.first),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
