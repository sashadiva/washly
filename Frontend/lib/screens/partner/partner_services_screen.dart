import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../l10n/app_localizations.dart';
import '../../models/partner_profile.dart';
import '../../services/partner_service.dart';
import '../../theme/app_theme.dart';

/// Partner services editor: list, add, edit, and delete services. The listing
/// mirrors the customer-facing service cards (image thumbnail + name +
/// description + price) so partners preview exactly what shoppers see.
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
    setState(() {
      _future = _service.services();
    });
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
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l10n.partnerServicesDeleteTitle,
            style: AppTypography.heading2),
        content: Text(l10n.partnerServicesDeleteBody(s.name),
            style: AppTypography.body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx, false),
              child: Text(l10n.commonCancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(dctx, true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _service.deleteService(s.id);
      _snack(l10n.partnerServicesDeleted);
      _reload();
    } catch (e) {
      _snack('$e'.replaceFirst('Exception: ', ''), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.partnerServicesTitle)),
      // Lift the FAB clear of the floating bottom nav (72 tall + 12 margin).
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 88),
        child: FloatingActionButton.extended(
          onPressed: () => _openEditor(),
          icon: const Icon(Icons.add_rounded),
          label: Text(
            l10n.partnerServicesAdd,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
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
              child: Text(l10n.partnerServicesEmpty,
                  style: AppTypography.body),
            );
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 100),
              itemCount: services.length,
              itemBuilder: (context, i) =>
                  _serviceCard(services[i], l10n),
            ),
          );
        },
      ),
    );
  }

  // Card styled like the customer-facing service row: image thumbnail, name,
  // description, and price, with edit/delete actions.
  Widget _serviceCard(ShopService s, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openEditor(existing: s),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: _thumb(s.imageUrl),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name, style: AppTypography.heading2),
                    if (s.description != null &&
                        s.description!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        s.description!,
                        style: AppTypography.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.partnerServicesPricePerUnit(
                          s.price.toStringAsFixed(0),
                          s.isKilo
                              ? l10n.partnerServicesUnitKg
                              : l10n.partnerServicesUnitItem),
                      style: AppTypography.price,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                color: AppColors.primary,
                tooltip: l10n.partnerServicesEditTooltip,
                onPressed: () => _openEditor(existing: s),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: AppColors.error,
                tooltip: l10n.partnerServicesDeleteTooltip,
                onPressed: () => _delete(s),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumb(String? imageUrl) {
    const size = 80.0;
    if (imageUrl == null || imageUrl.isEmpty) return _thumbPlaceholder();
    // Supports both remote URLs and base64 data URIs (uploaded photos).
    if (imageUrl.startsWith('data:')) {
      final bytes = _decodeDataUri(imageUrl);
      if (bytes == null) return _thumbPlaceholder();
      return Image.memory(bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _thumbPlaceholder());
    }
    return Image.network(imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _thumbPlaceholder());
  }

  Widget _thumbPlaceholder() => Container(
        width: 80,
        height: 80,
        color: AppColors.primaryLight,
        child: const Icon(Icons.local_laundry_service_outlined,
            color: AppColors.primary),
      );
}

/// Decode a 'data:image/...;base64,...' URI to bytes, or null.
Uint8List? _decodeDataUri(String dataUri) {
  final comma = dataUri.indexOf(',');
  final b64 = comma >= 0 ? dataUri.substring(comma + 1) : dataUri;
  try {
    return base64Decode(b64);
  } catch (_) {
    return null;
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
  final _picker = ImagePicker();
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _price;
  late String _unit;
  String? _imageUrl; // remote URL or base64 data URI
  bool _imageTouched = false; // whether the image changed this session
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _desc = TextEditingController(text: e?.description ?? '');
    _price =
        TextEditingController(text: e != null ? e.price.toStringAsFixed(0) : '');
    _unit = e?.unit ?? 'PER_ITEM';
    _imageUrl = e?.imageUrl;
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 80,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _imageUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      _imageTouched = true;
    });
  }

  void _removeImage() {
    setState(() {
      _imageUrl = null;
      _imageTouched = true;
    });
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final price = double.tryParse(_price.text.trim());
    if (name.isEmpty || price == null || price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                AppLocalizations.of(context).partnerServicesEnterNameAndPrice)),
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
          imageUrl: _imageUrl,
        );
      } else {
        await widget.service.updateService(
          widget.existing!.id,
          name: name,
          description: _desc.text.trim(),
          price: price,
          unit: _unit,
          // Only send image if it changed: '' clears it, a value sets it.
          imageUrl: _imageTouched ? (_imageUrl ?? '') : null,
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
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: AppSpacing.lg + bottomInset,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                widget.existing == null
                    ? l10n.partnerServicesAdd
                    : l10n.partnerServicesEdit,
                style: AppTypography.heading2),
            const SizedBox(height: AppSpacing.lg),
            _imageField(l10n),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _name,
              decoration:
                  InputDecoration(labelText: l10n.partnerServicesNameLabel),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _desc,
              maxLines: 2,
              decoration: InputDecoration(
                  labelText: l10n.partnerServicesDescriptionLabel),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _price,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l10n.partnerServicesPriceLabel,
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                    value: 'PER_ITEM',
                    label: Text(l10n.partnerServicesPerItem)),
                ButtonSegment(
                    value: 'PER_KG', label: Text(l10n.partnerServicesPerKg)),
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
                    : Text(l10n.commonSave),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Product image upload: tappable preview that opens the gallery, with a
  // remove action once an image is set.
  Widget _imageField(AppLocalizations l10n) {
    final hasImage = _imageUrl != null && _imageUrl!.isNotEmpty;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: SizedBox(
              width: 88,
              height: 88,
              child: hasImage
                  ? _preview(_imageUrl!)
                  : Container(
                      color: AppColors.surfaceMuted,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_a_photo_outlined,
                              color: AppColors.primary),
                          const SizedBox(height: AppSpacing.xs),
                          Text(l10n.partnerServicesAddPhoto,
                              style: AppTypography.caption),
                        ],
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.partnerServicesProductImage,
                  style: AppTypography.subheading),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.partnerServicesProductImageHint,
                style: AppTypography.caption,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: Text(hasImage
                        ? l10n.partnerServicesChange
                        : l10n.partnerServicesUpload),
                  ),
                  if (hasImage) ...[
                    const SizedBox(width: AppSpacing.sm),
                    TextButton(
                      onPressed: _removeImage,
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.error),
                      child: Text(l10n.commonRemove),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _preview(String imageUrl) {
    if (imageUrl.startsWith('data:')) {
      final bytes = _decodeDataUri(imageUrl);
      if (bytes == null) return Container(color: AppColors.surfaceMuted);
      return Image.memory(bytes, fit: BoxFit.cover);
    }
    return Image.network(imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: AppColors.surfaceMuted));
  }
}
