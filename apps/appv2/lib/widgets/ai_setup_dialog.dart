import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/habit_provider.dart';
import '../services/ai_manager.dart';
import '../services/storage_service.dart';
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
    final config = await StorageService.getAIConfig();
    if (config != null) {
      setState(() {
        _provider = config['provider'] ?? 'openai';
        _apiKeyController.text = config['apiKey'] ?? '';
      });
    }
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
    await provider.configureAI(provider: _provider, apiKey: _apiKeyController.text.trim());
    setState(() => _saving = false);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('AI Setup'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Store your API key locally to enable AI-generated insights.',
              style: AppTextStyles.bodySecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              value: _provider,
              decoration: const InputDecoration(labelText: 'Provider'),
              items: const [
                DropdownMenuItem(value: 'openai', child: Text('OpenAI compatible')),
                DropdownMenuItem(value: 'glm', child: Text('GLM / ZhipuAI')),
                DropdownMenuItem(value: 'openrouter', child: Text('OpenRouter')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _provider = val);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _apiKeyController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'API key'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'API key is required to enable AI' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
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
              : const Text('Save'),
        ),
      ],
    );
  }
}
