import { Theme } from '@/constants/theme';
import { LinearGradient } from 'expo-linear-gradient';
import React, { useEffect, useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  Modal,
  Platform,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native';
import { AIManager, AIProvider, getAvailableModels, getDefaultModel, StoredAIConfig, useAIManager } from '../services/aiManager';

interface AISetupModalProps {
  visible: boolean;
  onClose: () => void;
}

const PROVIDERS = [
  { id: 'glm' as AIProvider, name: 'GLM (ZhipuAI)', description: 'Chinese AI, affordable', emoji: '🇨🇳' },
  { id: 'openai' as AIProvider, name: 'OpenAI', description: 'Industry leader, GPT models', emoji: '🤖' },
  { id: 'openrouter' as AIProvider, name: 'OpenRouter', description: 'Access 100+ models', emoji: '🌐' },
];

const PROVIDER_HELP = {
  glm: {
    url: 'https://open.bigmodel.cn',
    howTo: 'Sign up at open.bigmodel.cn and get your API key from the dashboard.',
  },
  openai: {
    url: 'https://platform.openai.com/api-keys',
    howTo: 'Go to platform.openai.com, navigate to API keys, and create a new key.',
  },
  openrouter: {
    url: 'https://openrouter.ai/keys',
    howTo: 'Visit openrouter.ai, sign in, and generate an API key.',
  },
};

export const AISetupModal: React.FC<AISetupModalProps> = ({ visible, onClose }) => {
  const [provider, setProvider] = useState<AIProvider>('openai');
  const [apiKey, setApiKey] = useState('');
  const [selectedModel, setSelectedModel] = useState('');
  const [testing, setTesting] = useState(false);
  const [saving, setSaving] = useState(false);
  const [existingConfig, setExistingConfig] = useState<StoredAIConfig | null>(null);
  const { testConnection, setupAI, getCurrentConfig, isConfigured } = useAIManager();

  useEffect(() => {
    const loadConfig = async () => {
      const config = await getCurrentConfig();
      setExistingConfig(config);
      if (config) {
        setProvider(config.provider);
        setSelectedModel(config.model);
        // Mask the API key
        setApiKey(config.apiKey.substring(0, 8) + '...' + config.apiKey.substring(config.apiKey.length - 4));
      } else {
        setSelectedModel(getDefaultModel('openai'));
      }
    };

    if (visible) {
      loadConfig();
    }
  }, [visible]);

  useEffect(() => {
    // Update model when provider changes
    if (!existingConfig || existingConfig.provider !== provider) {
      setSelectedModel(getDefaultModel(provider));
    }
  }, [provider]);

  const handleTest = async () => {
    if (!apiKey.trim()) {
      Alert.alert('Error', 'Please enter your API key');
      return;
    }

    setTesting(true);
    try {
      await setupAI({ provider, apiKey: apiKey.trim(), model: selectedModel });
      await AIManager.initializeService();

      const isConnected = await testConnection();

      if (isConnected) {
        Alert.alert('Success! ✨', 'AI connection successful! Your insights will be powered by cutting-edge AI.');
      } else {
        Alert.alert('Connection Failed', 'Please check your API key and try again.');
      }
    } catch (error: any) {
      Alert.alert('Error', error.message || 'Failed to test connection');
    } finally {
      setTesting(false);
    }
  };

  const handleSave = async () => {
    if (!apiKey.trim()) {
      Alert.alert('Error', 'Please enter your API key');
      return;
    }

    setSaving(true);
    try {
      await setupAI({ provider, apiKey: apiKey.trim(), model: selectedModel });
      await AIManager.initializeService();
      Alert.alert('Saved! 🎉', 'Your AI settings have been saved successfully.', [
        { text: 'OK', onPress: onClose }
      ]);
    } catch (error: any) {
      Alert.alert('Error', error.message || 'Failed to save settings');
    } finally {
      setSaving(false);
    }
  };

  const handleClear = async () => {
    Alert.alert(
      'Clear AI Settings?',
      'This will remove your API key and disable AI features.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Clear',
          style: 'destructive',
          onPress: async () => {
            try {
              await AIManager.clearConfig();
              setApiKey('');
              setExistingConfig(null);
              setProvider('openai');
              setSelectedModel(getDefaultModel('openai'));
              Alert.alert('Cleared', 'AI settings have been removed.');
            } catch (error) {
              Alert.alert('Error', 'Failed to clear settings');
            }
          }
        }
      ]
    );
  };

  const availableModels = getAvailableModels(provider);

  return (
    <Modal
      visible={visible}
      animationType="slide"
      presentationStyle="pageSheet"
      onRequestClose={onClose}
    >
      <View style={styles.container}>
        {/* Header */}
        <View style={styles.header}>
          <TouchableOpacity onPress={onClose} hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}>
            <Text style={styles.cancelButton}>Cancel</Text>
          </TouchableOpacity>
          <Text style={styles.title}>AI Setup</Text>
          <TouchableOpacity onPress={handleSave} disabled={saving} hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}>
            {saving ? (
              <ActivityIndicator size="small" color={Theme.colors.primary} />
            ) : (
              <Text style={styles.saveButton}>Save</Text>
            )}
          </TouchableOpacity>
        </View>

        <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
          {/* Introduction */}
          <View style={styles.section}>
            <LinearGradient
              colors={Theme.gradients.primary}
              start={{ x: 0, y: 0 }}
              end={{ x: 1, y: 1 }}
              style={styles.headerGradient}
            >
              <Text style={styles.headerEmoji}>✨</Text>
              <Text style={styles.headerTitle}>AI-Powered Insights</Text>
              <Text style={styles.headerSubtitle}>
                Get personalized recommendations, motivation, and pattern analysis
              </Text>
            </LinearGradient>
          </View>

          {/* Provider Selection */}
          <View style={styles.section}>
            <Text style={styles.label}>AI Provider</Text>
            <View style={styles.providersContainer}>
              {PROVIDERS.map((p) => (
                <TouchableOpacity
                  key={p.id}
                  style={[
                    styles.providerCard,
                    provider === p.id && styles.providerCardSelected,
                  ]}
                  onPress={() => setProvider(p.id)}
                >
                  <Text style={styles.providerEmoji}>{p.emoji}</Text>
                  <Text style={[styles.providerName, provider === p.id && styles.providerNameSelected]}>
                    {p.name}
                  </Text>
                  <Text style={styles.providerDescription}>{p.description}</Text>
                  {provider === p.id && (
                    <View style={styles.selectedBadge}>
                      <Text style={styles.selectedBadgeText}>✓</Text>
                    </View>
                  )}
                </TouchableOpacity>
              ))}
            </View>
          </View>

          {/* Model Selection */}
          <View style={styles.section}>
            <Text style={styles.label}>Model</Text>
            <View style={styles.modelsContainer}>
              {availableModels.map((model) => (
                <TouchableOpacity
                  key={model}
                  style={[
                    styles.modelChip,
                    selectedModel === model && styles.modelChipSelected,
                  ]}
                  onPress={() => setSelectedModel(model)}
                >
                  <Text style={[
                    styles.modelChipText,
                    selectedModel === model && styles.modelChipTextSelected,
                  ]}>
                    {model}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
            <Text style={styles.helpText}>
              Recommended: {provider === 'glm' ? 'glm-4-flash' : provider === 'openai' ? 'gpt-4o-mini' : 'claude-3.5-sonnet'} (best balance of quality and speed)
            </Text>
          </View>

          {/* API Key Input */}
          <View style={styles.section}>
            <Text style={styles.label}>API Key</Text>
            <TextInput
              style={styles.input}
              value={apiKey}
              onChangeText={setApiKey}
              placeholder={`Enter your ${PROVIDERS.find(p => p.id === provider)?.name} API key`}
              placeholderTextColor={Theme.colors.textTertiary}
              secureTextEntry={existingConfig ? true : false}
              autoCapitalize="none"
              autoCorrect={false}
            />
            <TouchableOpacity onPress={() => Alert.alert('Get API Key', PROVIDER_HELP[provider].howTo)}>
              <Text style={styles.helpLink}>How to get API key? →</Text>
            </TouchableOpacity>
          </View>

          {/* Test Button */}
          <View style={styles.section}>
            <TouchableOpacity
              style={styles.testButton}
              onPress={handleTest}
              disabled={testing}
            >
              <LinearGradient
                colors={testing ? [Theme.colors.textSecondary, Theme.colors.textSecondary] : Theme.gradients.secondary}
                style={styles.testButtonGradient}
              >
                {testing ? (
                  <ActivityIndicator size="small" color="#fff" />
                ) : (
                  <Text style={styles.testButtonText}>Test Connection</Text>
                )}
              </LinearGradient>
            </TouchableOpacity>
          </View>

          {/* What You Get */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>What You'll Get</Text>
            <View style={styles.featuresList}>
              {[
                { emoji: '💡', title: 'Smart Recommendations', desc: 'Personalized habit suggestions based on your routine' },
                { emoji: '🔥', title: 'Streak Motivation', desc: 'Encouraging messages to keep you going' },
                { emoji: '📊', title: 'Pattern Analysis', desc: 'Deep insights into your habit performance' },
                { emoji: '🔮', title: 'Success Predictions', desc: 'AI-powered forecasts for long-term success' },
              ].map((feat, i) => (
                <View key={i} style={styles.featureItem}>
                  <View style={styles.featureIconContainer}>
                    <Text style={styles.featureEmoji}>{feat.emoji}</Text>
                  </View>
                  <View style={styles.featureContent}>
                    <Text style={styles.featureTitle}>{feat.title}</Text>
                    <Text style={styles.featureDescription}>{feat.desc}</Text>
                  </View>
                </View>
              ))}
            </View>
          </View>

          {/* Clear Button */}
          {existingConfig && (
            <View style={styles.section}>
              <TouchableOpacity style={styles.clearButton} onPress={handleClear}>
                <Text style={styles.clearButtonText}>Clear AI Settings</Text>
              </TouchableOpacity>
            </View>
          )}

          {/* Status */}
          <View style={styles.section}>
            <View style={[styles.statusCard, isConfigured ? styles.statusSuccess : styles.statusWarning]}>
              <Text style={styles.statusIcon}>{isConfigured ? '✅' : '⚠️'}</Text>
              <Text style={[styles.statusText, isConfigured ? styles.statusTextSuccess : styles.statusTextWarning]}>
                {isConfigured ? `AI enabled with ${existingConfig?.provider.toUpperCase()}` : 'AI features are disabled'}
              </Text>
            </View>
          </View>

          <View style={{ height: 40 }} />
        </ScrollView>
      </View>
    </Modal>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Theme.colors.background,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: Theme.spacing.md,
    paddingVertical: Theme.spacing.md,
    backgroundColor: Theme.colors.surface,
    borderBottomWidth: 1,
    borderBottomColor: Theme.colors.border,
    ...Theme.shadows.sm,
  },
  title: {
    ...Theme.typography.h2,
    fontSize: 20,
  },
  cancelButton: {
    fontSize: 16,
    color: Theme.colors.textSecondary,
  },
  saveButton: {
    fontSize: 16,
    color: Theme.colors.primary,
    fontWeight: '700',
  },
  content: {
    flex: 1,
    paddingHorizontal: Theme.spacing.md,
  },
  section: {
    marginTop: Theme.spacing.lg,
  },
  headerGradient: {
    padding: Theme.spacing.xl,
    borderRadius: Theme.borderRadius.xl,
    alignItems: 'center',
  },
  headerEmoji: {
    fontSize: 48,
    marginBottom: 12,
  },
  headerTitle: {
    fontSize: 24,
    fontWeight: '800',
    color: '#fff',
    marginBottom: 8,
  },
  headerSubtitle: {
    fontSize: 15,
    color: 'rgba(255,255,255,0.9)',
    textAlign: 'center',
  },
  sectionTitle: {
    ...Theme.typography.h3,
    marginBottom: Theme.spacing.md,
  },
  label: {
    ...Theme.typography.bodyMedium,
    fontWeight: '700',
    marginBottom: Theme.spacing.sm,
  },
  providersContainer: {
    gap: 12,
  },
  providerCard: {
    padding: Theme.spacing.md,
    borderRadius: Theme.borderRadius.lg,
    borderWidth: 2,
    borderColor: Theme.colors.border,
    backgroundColor: Theme.colors.surface,
  },
  providerCardSelected: {
    borderColor: Theme.colors.primary,
    backgroundColor: Theme.colors.primaryLight + '10',
  },
  providerEmoji: {
    fontSize: 28,
    marginBottom: 8,
  },
  providerName: {
    ...Theme.typography.h3,
    fontSize: 17,
    marginBottom: 4,
  },
  providerNameSelected: {
    color: Theme.colors.primary,
  },
  providerDescription: {
    ...Theme.typography.bodySmall,
    color: Theme.colors.textSecondary,
  },
  selectedBadge: {
    position: 'absolute',
    top: 12,
    right: 12,
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: Theme.colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
  },
  selectedBadgeText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: 'bold',
  },
  modelsContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
    marginBottom: 8,
  },
  modelChip: {
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderRadius: Theme.borderRadius.full,
    backgroundColor: Theme.colors.backgroundDark,
    borderWidth: 1.5,
    borderColor: Theme.colors.border,
  },
  modelChipSelected: {
    backgroundColor: Theme.colors.primary,
    borderColor: Theme.colors.primary,
  },
  modelChipText: {
    fontSize: 13,
    fontWeight: '600',
    color: Theme.colors.text,
  },
  modelChipTextSelected: {
    color: '#fff',
  },
  input: {
    borderWidth: 1,
    borderColor: Theme.colors.border,
    borderRadius: Theme.borderRadius.lg,
    paddingHorizontal: Theme.spacing.md,
    paddingVertical: Platform.OS === 'ios' ? 14 : 12,
    fontSize: 15,
    backgroundColor: Theme.colors.surface,
    color: Theme.colors.text,
    ...Theme.shadows.sm,
  },
  helpText: {
    ...Theme.typography.caption,
    marginTop: 6,
  },
  helpLink: {
    ...Theme.typography.caption,
    color: Theme.colors.primary,
    fontWeight: '600',
    marginTop: 8,
  },
  testButton: {
    borderRadius: Theme.borderRadius.lg,
    overflow: 'hidden',
    ...Theme.shadows.md,
  },
  testButtonGradient: {
    paddingVertical: 14,
    alignItems: 'center',
  },
  testButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '700',
  },
  featuresList: {
    gap: 12,
  },
  featureItem: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    backgroundColor: Theme.colors.surface,
    padding: Theme.spacing.md,
    borderRadius: Theme.borderRadius.lg,
    ...Theme.shadows.sm,
  },
  featureIconContainer: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: Theme.colors.backgroundDark,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  },
  featureEmoji: {
    fontSize: 20,
  },
  featureContent: {
    flex: 1,
  },
  featureTitle: {
    fontSize: 16,
    fontWeight: '700',
    color: Theme.colors.text,
    marginBottom: 2,
  },
  featureDescription: {
    fontSize: 14,
    color: Theme.colors.textSecondary,
    lineHeight: 19,
  },
  clearButton: {
    backgroundColor: Theme.colors.errorLight,
    paddingVertical: 14,
    borderRadius: Theme.borderRadius.lg,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: Theme.colors.error,
  },
  clearButtonText: {
    color: Theme.colors.error,
    fontSize: 16,
    fontWeight: '700',
  },
  statusCard: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 16,
    borderRadius: Theme.borderRadius.lg,
    borderWidth: 1.5,
  },
  statusSuccess: {
    backgroundColor: Theme.colors.successLight,
    borderColor: Theme.colors.success,
  },
  statusWarning: {
    backgroundColor: Theme.colors.warningLight,
    borderColor: Theme.colors.warning,
  },
  statusIcon: {
    fontSize: 20,
    marginRight: 12,
  },
  statusText: {
    fontSize: 15,
    fontWeight: '600',
  },
  statusTextSuccess: {
    color: Theme.colors.success,
  },
  statusTextWarning: {
    color: Theme.colors.warning,
  },
});