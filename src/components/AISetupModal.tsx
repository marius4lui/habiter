import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  Modal,
  ScrollView,
  StyleSheet,
  Alert,
  ActivityIndicator,
} from 'react-native';
import { AIManager, useAIManager } from '../services/aiManager';

interface AISetupModalProps {
  visible: boolean;
  onClose: () => void;
}

export const AISetupModal: React.FC<AISetupModalProps> = ({ visible, onClose }) => {
  const [apiKey, setApiKey] = useState('');
  const [testing, setTesting] = useState(false);
  const [saving, setSaving] = useState(false);
  const [existingKey, setExistingKey] = useState<string | null>(null);
  const { testConnection, setupApiKey, isConfigured } = useAIManager();

  useEffect(() => {
    const loadExistingKey = async () => {
      const key = await AIManager.getApiKey();
      setExistingKey(key);
      if (key) {
        // Mask the key for display
        setApiKey(key.substring(0, 8) + '...' + key.substring(key.length - 4));
      }
    };

    if (visible) {
      loadExistingKey();
    }
  }, [visible]);

  const handleTestConnection = async () => {
    if (!apiKey.trim()) {
      Alert.alert('Error', 'Please enter your GLM API key');
      return;
    }

    setTesting(true);
    try {
      // Save the key temporarily for testing
      await setupApiKey(apiKey.trim());
      await AIManager.initializeService();

      const isConnected = await testConnection();

      if (isConnected) {
        Alert.alert('Success', 'GLM AI connection successful!');
      } else {
        Alert.alert('Error', 'Failed to connect to GLM AI. Please check your API key.');
      }
    } catch {
      Alert.alert('Error', 'Failed to test connection. Please check your API key.');
    } finally {
      setTesting(false);
    }
  };

  const handleSave = async () => {
    if (!apiKey.trim()) {
      Alert.alert('Error', 'Please enter your GLM API key');
      return;
    }

    setSaving(true);
    try {
      await setupApiKey(apiKey.trim());
      await AIManager.initializeService();
      Alert.alert('Success', 'GLM API key saved successfully!', [
        { text: 'OK', onPress: onClose }
      ]);
    } catch {
      Alert.alert('Error', 'Failed to save API key');
    } finally {
      setSaving(false);
    }
  };

  const handleClearKey = async () => {
    Alert.alert(
      'Clear API Key',
      'Are you sure you want to remove the GLM API key? This will disable AI features.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Clear',
          style: 'destructive',
          onPress: async () => {
            try {
              await AIManager.clearApiKey();
              setApiKey('');
              setExistingKey(null);
              Alert.alert('Success', 'API key cleared');
            } catch {
              Alert.alert('Error', 'Failed to clear API key');
            }
          }
        }
      ]
    );
  };

  // const resetForm = () => {
  //   setApiKey('');
  //   setExistingKey(null);
  // };

  return (
    <Modal
      visible={visible}
      animationType="slide"
      presentationStyle="pageSheet"
      onRequestClose={onClose}
    >
      <View style={styles.container}>
        <View style={styles.header}>
          <TouchableOpacity onPress={onClose}>
            <Text style={styles.cancelButton}>Cancel</Text>
          </TouchableOpacity>
          <Text style={styles.title}>AI Setup</Text>
          <TouchableOpacity onPress={handleSave} disabled={saving}>
            {saving ? (
              <ActivityIndicator size="small" color="#007AFF" />
            ) : (
              <Text style={styles.saveButton}>Save</Text>
            )}
          </TouchableOpacity>
        </View>

        <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
          {/* Introduction */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>🤖 AI-Powered Insights</Text>
            <Text style={styles.description}>
              Connect your GLM AI to get personalized habit recommendations, motivational messages,
              and intelligent insights about your progress.
            </Text>
          </View>

          {/* API Key Input */}
          <View style={styles.section}>
            <Text style={styles.label}>GLM API Key</Text>
            <TextInput
              style={styles.input}
              value={apiKey}
              onChangeText={setApiKey}
              placeholder="Enter your GLM API key"
              secureTextEntry={existingKey ? true : false}
              autoCapitalize="none"
              autoCorrect={false}
            />
            <Text style={styles.helpText}>
              Get your API key from the GLM AI dashboard at open.bigmodel.cn
            </Text>
          </View>

          {/* Test Connection */}
          <View style={styles.section}>
            <TouchableOpacity
              style={[styles.testButton, testing && styles.testButtonDisabled]}
              onPress={handleTestConnection}
              disabled={testing}
            >
              {testing ? (
                <ActivityIndicator size="small" color="#fff" />
              ) : (
                <Text style={styles.testButtonText}>Test Connection</Text>
              )}
            </TouchableOpacity>
          </View>

          {/* Features List */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>AI Features</Text>
            <View style={styles.featuresList}>
              <View style={styles.featureItem}>
                <Text style={styles.featureIcon}>💡</Text>
                <View style={styles.featureContent}>
                  <Text style={styles.featureTitle}>Smart Recommendations</Text>
                  <Text style={styles.featureDescription}>
                    Get personalized habit suggestions based on your current routines
                  </Text>
                </View>
              </View>

              <View style={styles.featureItem}>
                <Text style={styles.featureIcon}>🚀</Text>
                <View style={styles.featureContent}>
                  <Text style={styles.featureTitle}>Motivational Coaching</Text>
                  <Text style={styles.featureDescription}>
                    Receive encouraging messages to maintain your streaks
                  </Text>
                </View>
              </View>

              <View style={styles.featureItem}>
                <Text style={styles.featureIcon}>📊</Text>
                <View style={styles.featureContent}>
                  <Text style={styles.featureTitle}>Pattern Analysis</Text>
                  <Text style={styles.featureDescription}>
                    Understand your habit patterns and identify improvement areas
                  </Text>
                </View>
              </View>

              <View style={styles.featureItem}>
                <Text style={styles.featureIcon}>🔮</Text>
                <View style={styles.featureContent}>
                  <Text style={styles.featureTitle}>Success Predictions</Text>
                  <Text style={styles.featureDescription}>
                    AI-powered predictions about your habit success likelihood
                  </Text>
                </View>
              </View>
            </View>
          </View>

          {/* Clear Key Option */}
          {existingKey && (
            <View style={styles.section}>
              <TouchableOpacity style={styles.clearButton} onPress={handleClearKey}>
                <Text style={styles.clearButtonText}>Clear API Key</Text>
              </TouchableOpacity>
            </View>
          )}

          {/* Status */}
          <View style={styles.section}>
            <View style={[styles.statusCard, isConfigured ? styles.statusSuccess : styles.statusWarning]}>
              <Text style={styles.statusIcon}>{isConfigured ? '✅' : '⚠️'}</Text>
              <Text style={styles.statusText}>
                {isConfigured ? 'AI features are enabled' : 'AI features are disabled'}
              </Text>
            </View>
          </View>
        </ScrollView>
      </View>
    </Modal>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#e1e5e9',
  },
  title: {
    fontSize: 18,
    fontWeight: '600',
    color: '#333',
  },
  cancelButton: {
    fontSize: 16,
    color: '#666',
  },
  saveButton: {
    fontSize: 16,
    color: '#007AFF',
    fontWeight: '600',
  },
  content: {
    flex: 1,
    paddingHorizontal: 16,
  },
  section: {
    marginVertical: 16,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#333',
    marginBottom: 8,
  },
  description: {
    fontSize: 16,
    color: '#666',
    lineHeight: 22,
  },
  label: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
    marginBottom: 8,
  },
  input: {
    borderWidth: 1,
    borderColor: '#e1e5e9',
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 12,
    fontSize: 16,
    backgroundColor: '#f8f9fa',
  },
  helpText: {
    fontSize: 14,
    color: '#666',
    marginTop: 6,
  },
  testButton: {
    backgroundColor: '#007AFF',
    paddingVertical: 12,
    borderRadius: 8,
    alignItems: 'center',
  },
  testButtonDisabled: {
    opacity: 0.6,
  },
  testButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  featuresList: {
    gap: 16,
  },
  featureItem: {
    flexDirection: 'row',
    alignItems: 'flex-start',
  },
  featureIcon: {
    fontSize: 24,
    marginRight: 12,
    marginTop: 2,
  },
  featureContent: {
    flex: 1,
  },
  featureTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
    marginBottom: 4,
  },
  featureDescription: {
    fontSize: 14,
    color: '#666',
    lineHeight: 20,
  },
  clearButton: {
    backgroundColor: '#ff4757',
    paddingVertical: 12,
    borderRadius: 8,
    alignItems: 'center',
  },
  clearButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  statusCard: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 12,
    borderRadius: 8,
  },
  statusSuccess: {
    backgroundColor: '#d4edda',
  },
  statusWarning: {
    backgroundColor: '#fff3cd',
  },
  statusIcon: {
    fontSize: 20,
    marginRight: 8,
  },
  statusText: {
    fontSize: 16,
    fontWeight: '500',
    color: '#333',
  },
});