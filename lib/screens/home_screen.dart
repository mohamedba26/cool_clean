import 'package:flutter/material.dart';
import '../widgets/primary_button.dart';
import '../routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  Widget _hero(BuildContext c) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Boycott Scanner',
                    style: Theme.of(c).textTheme.headlineSmall,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Scan products to check if they should be boycotted. Fast, simple and ethical.',
                    style: Theme.of(c).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            SizedBox(width: 12),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Theme.of(c).colorScheme.secondary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.qr_code_scanner,
                size: 36,
                color: Theme.of(c).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActions(BuildContext c) {
    return Row(
      children: [
        Expanded(
          child: PrimaryButton(
            label: 'Scan',
            onTap: () => Navigator.pushNamed(c, Routes.scan),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pushNamed(c, Routes.result),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14.0),
              child: Text('Photo'),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Boycott Scanner')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _hero(context),
            SizedBox(height: 18),
            _quickActions(context),
            SizedBox(height: 18),
            Expanded(
              child: ListView(
                children: [
                  Text(
                    'Popular brands to check',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(label: Text('Coca Cola')),
                      Chip(label: Text('Nestlé')),
                      Chip(label: Text('Pepsi')),
                      Chip(label: Text('Monoprix')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
