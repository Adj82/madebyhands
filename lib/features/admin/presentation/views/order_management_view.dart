import 'package:flutter/material.dart';

class OrderManagementView extends StatelessWidget {
  const OrderManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 15),
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
              expansionTileTheme: const ExpansionTileThemeData(
                shape: Border(),
                collapsedShape: Border(),
              ),
            ),
            child: ExpansionTile(
              shape: const Border(),
              collapsedShape: const Border(),
              title: Text('Order #MBH-102$index',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Status: ${index % 2 == 0 ? 'Processing' : 'Shipped'} • Total: ₹2,450'),
              children: [
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Order Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    const Text('• Blue Ceramic Vase x 1'),
                    const Text('• Handmade Soap Set x 2'),
                    const Divider(),
                    const Text('Timeline:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Text('18 Sep: Order Confirmed'),
                    if (index % 2 != 0) const Text('19 Sep: Shipped by Creator'),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        const Spacer(),
                        OutlinedButton(onPressed: () {}, child: const Text('Contact Buyer')),
                        const SizedBox(width: 10),
                        OutlinedButton(onPressed: () {}, child: const Text('Contact Creator')),
                      ],
                    )
                  ],
                ),
              )
            ],
            ),
          ),
        );
      },
    );
  }
}
