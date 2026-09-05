import 'package:flutter/material.dart';

import '../../core/constants/environment.dart';

class StartupConfigGate extends StatelessWidget {
  const StartupConfigGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (Environment.hasRequiredRuntimeConfig) {
      return child;
    }

    final missing = Environment.missingRuntimeConfigKeys;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CineTrekker is not configured yet',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Set the required runtime environment variables before running the app on your Samsung device. Placeholder values like example.com are treated as missing.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Missing values',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ...missing.map(
                        (value) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text('• $value'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Copy android/local.properties.example to android/local.properties and pass the CineTrekker env values when running Flutter.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
