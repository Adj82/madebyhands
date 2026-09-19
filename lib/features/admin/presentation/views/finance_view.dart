import 'package:flutter/material.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/admin/presentation/widgets/small_stat.dart';

class FinanceView extends StatelessWidget {
  const FinanceView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Financial Summary', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(25),
            width: double.infinity,
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(25)),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Platform Balance', style: TextStyle(color: Colors.white70)),
                Text('₹1,42,850.00', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                SizedBox(height: 20),
                Row(
                  children: [
                    SmallStat(label: 'Total Fees', value: '₹12,400'),
                    SizedBox(width: 40),
                    SmallStat(label: 'Pending Payouts', value: '₹5,200'),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Text('Pending Creator Payouts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            itemBuilder: (context, index) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    title: Text('Artisan $index', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Request Date: 17 Sep 2026', style: TextStyle(fontSize: 12)),
                    trailing: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('₹4,500', style: TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(
                          'Release Payout',
                          style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    onTap: () {
                      // Trigger payout logic
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
