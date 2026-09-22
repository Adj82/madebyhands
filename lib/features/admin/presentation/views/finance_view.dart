import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:madebyhands/features/admin/presentation/widgets/small_stat.dart';
import 'package:madebyhands/features/orders/domain/entities/marketplace_order.dart';
import 'package:madebyhands/features/orders/domain/repositories/order_repository.dart';
import 'package:madebyhands/init_dependencies.dart';

class FinanceView extends StatelessWidget {
  const FinanceView({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = serviceLocator<OrderRepository>();
    return BlocBuilder<AdminBloc, AdminState>(
      builder: (context, adminState) {
        return StreamBuilder<List<MarketplaceOrder>>(
          stream: repository.watchAllOrders(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Could not load finance data: ${snapshot.error}'),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final validOrders = snapshot.data!
                .where((order) => order.payoutStatus != 'cancelled')
                .toList();
            final platformBalance = validOrders.fold<int>(
              0,
              (sum, order) => sum + order.platformFee,
            );
            final payouts = _groupPayouts(
              validOrders.where((order) => order.payoutStatus == 'pending'),
            );

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Financial Summary',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Platform Balance',
                        style: TextStyle(color: Colors.white70),
                      ),
                      Text(
                        '₹$platformBalance',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          SmallStat(
                            label: 'Flat Fee',
                            value: '₹${adminState.flatFee}',
                          ),
                          const SizedBox(width: 40),
                          SmallStat(
                            label: 'Comm.',
                            value: '${adminState.percentFee}%',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Pending Creator Payouts',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (payouts.isEmpty)
                  const Card(
                    child: ListTile(title: Text('No pending payouts.')),
                  )
                else
                  ...payouts.map(
                    (payout) => Card(
                      child: ListTile(
                        title: Text(
                          payout.creatorName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('${payout.orderIds.length} order(s)'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${payout.amount}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            InkWell(
                              onTap: () =>
                                  _release(context, repository, payout),
                              child: const Text(
                                'Release Payout',
                                style: TextStyle(color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  List<_CreatorPayout> _groupPayouts(Iterable<MarketplaceOrder> orders) {
    final grouped = <String, _CreatorPayout>{};
    for (final order in orders) {
      final payout = grouped.putIfAbsent(
        order.creatorId,
        () => _CreatorPayout(order.creatorName),
      );
      payout.amount += order.creatorNetAmount;
      payout.orderIds.add(order.id);
    }
    return grouped.values.toList();
  }

  Future<void> _release(
    BuildContext context,
    OrderRepository repository,
    _CreatorPayout payout,
  ) async {
    for (final orderId in payout.orderIds) {
      await repository.releasePayout(orderId);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('₹${payout.amount} marked as paid.')),
      );
    }
  }
}

class _CreatorPayout {
  final String creatorName;
  int amount = 0;
  final List<String> orderIds = [];

  _CreatorPayout(this.creatorName);
}
