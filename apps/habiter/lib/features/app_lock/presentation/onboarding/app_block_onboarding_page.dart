import 'package:flutter/material.dart';

final class AppBlockOnboardingPage extends StatelessWidget {
  const AppBlockOnboardingPage({
    required this.title,
    required this.body,
    required this.primary,
    this.subtitle,
    this.secondary,
    this.onBack,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final Widget primary;
  final Widget? secondary;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: false,
      leading: onBack == null
          ? null
          : IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            if (subtitle != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(subtitle!, style: Theme.of(context).textTheme.bodyLarge),
            ],
            const SizedBox(height: 24),
            Expanded(child: SingleChildScrollView(child: body)),
            const SizedBox(height: 16),
            primary,
            if (secondary != null) ...<Widget>[
              const SizedBox(height: 8),
              secondary!,
            ],
          ],
        ),
      ),
    ),
  );
}
