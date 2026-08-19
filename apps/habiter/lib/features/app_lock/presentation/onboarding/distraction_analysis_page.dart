import 'package:flutter/material.dart';

final class DistractionAnalysisPage extends StatelessWidget {
  const DistractionAnalysisPage({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Looking only at this device…'),
          ],
        ),
      ),
    ),
  );
}
