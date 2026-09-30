import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../services/driver_service.dart';
import '../../theme/app_theme.dart';

/// Driver History tab: completed deliveries.
class DriverHistoryScreen extends StatefulWidget {
  const DriverHistoryScreen({super.key});

  @override
  State<DriverHistoryScreen> createState() => _DriverHistoryScreenState();
}

class _DriverHistoryScreenState extends State<DriverHistoryScreen> {
  final _service = DriverService();
  late Future<List<Order>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.history();
  }

  Future<void> _reload() async {
    setState(() => _future = _service.history());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: FutureBuilder<List<Order>>(
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
          final orders = snapshot.data!;
          if (orders.isEmpty) {
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(
                      child: Text('No completed deliveries yet.',
                          style: AppTypography.body)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: orders.length,
              itemBuilder: (context, i) {
                final o = orders[i];
                return Card(
                  elevation: 0,
                  color: AppColors.surface,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.check_circle,
                        color: AppColors.success),
                    title: Text('Order #${o.id}',
                        style: AppTypography.subheading),
                    subtitle: Text(o.laundromat?.name ?? 'Laundromat',
                        style: AppTypography.caption),
                    trailing: Text('Deliver to\n${o.deliveryAddress}',
                        textAlign: TextAlign.right,
                        style: AppTypography.caption),
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
