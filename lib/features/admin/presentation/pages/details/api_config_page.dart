import 'package:flutter/material.dart';
import 'package:madebyhands/core/theme/app_theme.dart';

class ApiConfigPage extends StatelessWidget {
  const ApiConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API Configuration')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _ConfigHeader(title: 'Firebase Project Settings'),
          const _ConfigDetail(label: 'Project ID', value: 'madebyhands-77f87'),
          const _ConfigDetail(label: 'Project Number', value: '745060405583'),
          const _ConfigDetail(label: 'Storage Bucket', value: 'madebyhands-77f87.firebasestorage.app'),
          const SizedBox(height: 30),
          const _ConfigHeader(title: 'Google Auth Configuration'),
          const _ConfigDetail(label: 'OAuth Client ID (Web)', value: '745060405583-fulnte2av4ooagafe1gfdo3rvjkqnpgd.apps.googleusercontent.com'),
          const _ConfigDetail(label: 'People API Status', value: 'Enabled'),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.amber.withAlpha(20), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.amber.withAlpha(50))),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 15),
                Expanded(child: Text('Changes to these values require a new build and deployment.', style: TextStyle(fontSize: 12, color: Colors.brown))),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _ConfigHeader extends StatelessWidget {
  final String title;
  const _ConfigHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
    );
  }
}

class _ConfigDetail extends StatelessWidget {
  final String label;
  final String value;
  const _ConfigDetail({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}
