import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/habit_provider.dart';
import '../l10n/l10n.dart';
import '../services/ai_manager.dart';
import '../theme/app_theme.dart';

class AISetupDialog extends StatefulWidget {
  const AISetupDialog({super.key});

  @override
  State<AISetupDialog> createState() => _AISetupDialogState();
}

class _AISetupDialogState extends State<AISetupDialog> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();
  String _provider = 'openai';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    await AIManager.initialize();
    if (!mounted) return;
    setState(() => _provider = AIManager.provider ?? 'openai');
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final provider = context.read<HabitProvider>();
    await provider.configureAI(
      provider: _provider,
      apiKey: _apiKeyController.text.trim(),
    );
    setState(() => _saving = false);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.experimentalAi),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.remoteAiDisclosure,
              style: AppTextStyles.bodySecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _provider,
              decoration: InputDecoration(
                labelText: context.l10n.providerLabel,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'openai',
                  child: Text('OpenAI compatible'),
                ),
                DropdownMenuItem(value: 'glm', child: Text('GLM / ZhipuAI')),
                DropdownMenuItem(
                  value: 'openrouter',
                  child: Text('OpenRouter'),
                ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _provider = val);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _apiKeyController,
              obscureText: true,
              decoration: InputDecoration(labelText: context.l10n.apiKeyLabel),
              validator: (v) => v == null || v.trim().isEmpty
                  ? context.l10n.apiKeyRequired
                  : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _saving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.l10n.save),
        ),
      ],
    );
  }
}
