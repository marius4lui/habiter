import { Theme } from '@/constants/theme';
import React, { useState } from 'react';
import {
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
import { useHabits } from '../contexts/HabitContext';
import { Habit } from '../types/habit';
import { getHabitIconSuggestions, getRandomColor } from '../utils/habitUtils';

interface AddHabitModalProps {
  visible: boolean;
  onClose: () => void;
}

const CATEGORIES = [
  'Health',
  'Learning',
  'Productivity',
  'Social',
  'Creative',
  'Fitness',
  'Mindfulness',
  'Finance',
];

const FREQUENCIES = [
  { label: 'Daily', value: 'daily' as const },
  { label: 'Weekly', value: 'weekly' as const },
  { label: 'Custom', value: 'custom' as const },
];

export const AddHabitModal: React.FC<AddHabitModalProps> = ({ visible, onClose }) => {
  const { addHabit } = useHabits();
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    category: 'Health',
    frequency: 'daily' as 'daily' | 'weekly' | 'custom',
    targetCount: 1,
    color: getRandomColor(),
    icon: '✨',
  });

  const [selectedIconCategory, setSelectedIconCategory] = useState('Health');

  const resetForm = () => {
    setFormData({
      name: '',
      description: '',
      category: 'Health',
      frequency: 'daily',
      targetCount: 1,
      color: getRandomColor(),
      icon: '✨',
    });
    setSelectedIconCategory('Health');
  };

  const handleSubmit = async () => {
    if (!formData.name.trim()) {
      Alert.alert('Error', 'Please enter a habit name');
      return;
    }

    try {
      const newHabit: Omit<Habit, 'id' | 'createdAt'> = {
        name: formData.name.trim(),
        description: formData.description.trim(),
        category: formData.category,
        frequency: formData.frequency,
        targetCount: formData.targetCount,
        color: formData.color,
        icon: formData.icon,
        isActive: true,
      };

      await addHabit(newHabit);
      resetForm();
      onClose();
    } catch {
      Alert.alert('Error', 'Failed to create habit');
    }
  };

  const handleCategoryChange = (category: string) => {
    const icons = getHabitIconSuggestions(category);
    setFormData(prev => ({
      ...prev,
      category,
      icon: icons[0] || '✨',
    }));
    setSelectedIconCategory(category);
  };

  const iconSuggestions = getHabitIconSuggestions(selectedIconCategory);

  return (
    <Modal
      visible={visible}
      animationType="slide"
      presentationStyle="pageSheet"
      onRequestClose={onClose}
    >
      <View style={styles.container}>
        <View style={styles.header}>
          <TouchableOpacity onPress={onClose} hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}>
            <Text style={styles.cancelButton}>Cancel</Text>
          </TouchableOpacity>
          <Text style={styles.title}>New Habit</Text>
          <TouchableOpacity onPress={handleSubmit} hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}>
            <Text style={styles.saveButton}>Save</Text>
          </TouchableOpacity>
        </View>

        <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
          {/* Habit Name */}
          <View style={styles.section}>
            <Text style={styles.label}>Name</Text>
            <TextInput
              style={styles.input}
              value={formData.name}
              onChangeText={(text) => setFormData(prev => ({ ...prev, name: text }))}
              placeholder="e.g., Read 30 mins"
              placeholderTextColor={Theme.colors.textTertiary}
              maxLength={50}
            />
          </View>

          {/* Description */}
          <View style={styles.section}>
            <Text style={styles.label}>Description</Text>
            <TextInput
              style={[styles.input, styles.textArea]}
              value={formData.description}
              onChangeText={(text) => setFormData(prev => ({ ...prev, description: text }))}
              placeholder="Add a description (optional)"
              placeholderTextColor={Theme.colors.textTertiary}
              multiline
              numberOfLines={3}
              maxLength={200}
            />
          </View>

          {/* Category */}
          <View style={styles.section}>
            <Text style={styles.label}>Category</Text>
            <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.categoryScroll}>
              {CATEGORIES.map((category) => (
                <TouchableOpacity
                  key={category}
                  style={[
                    styles.categoryChip,
                    formData.category === category && styles.categoryChipSelected,
                  ]}
                  onPress={() => handleCategoryChange(category)}
                >
                  <Text
                    style={[
                      styles.categoryChipText,
                      formData.category === category && styles.categoryChipTextSelected,
                    ]}
                  >
                    {category}
                  </Text>
                </TouchableOpacity>
              ))}
            </ScrollView>
          </View>

          {/* Icon */}
          <View style={styles.section}>
            <Text style={styles.label}>Icon</Text>
            <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.iconScroll}>
              {iconSuggestions.map((icon, index) => (
                <TouchableOpacity
                  key={index}
                  style={[
                    styles.iconChip,
                    formData.icon === icon && styles.iconChipSelected,
                  ]}
                  onPress={() => setFormData(prev => ({ ...prev, icon }))}
                >
                  <Text style={styles.iconText}>{icon}</Text>
                </TouchableOpacity>
              ))}
            </ScrollView>
          </View>

          {/* Color */}
          <View style={styles.section}>
            <Text style={styles.label}>Color</Text>
            <View style={styles.colorRow}>
              {['#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FECA57', '#FF9FF3', '#54A0FF', '#5F27CD'].map((color) => (
                <TouchableOpacity
                  key={color}
                  style={[
                    styles.colorChip,
                    { backgroundColor: color },
                    formData.color === color && styles.colorChipSelected,
                  ]}
                  onPress={() => setFormData(prev => ({ ...prev, color }))}
                />
              ))}
            </View>
          </View>

          {/* Frequency */}
          <View style={styles.section}>
            <Text style={styles.label}>Frequency</Text>
            <View style={styles.frequencyRow}>
              {FREQUENCIES.map((freq) => (
                <TouchableOpacity
                  key={freq.value}
                  style={[
                    styles.frequencyChip,
                    formData.frequency === freq.value && styles.frequencyChipSelected,
                  ]}
                  onPress={() => setFormData(prev => ({ ...prev, frequency: freq.value }))}
                >
                  <Text
                    style={[
                      styles.frequencyChipText,
                      formData.frequency === freq.value && styles.frequencyChipTextSelected,
                    ]}
                  >
                    {freq.label}
                  </Text>
                </TouchableOpacity>
              ))}
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
    backgroundColor: Theme.colors.surface,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: Theme.spacing.md,
    paddingVertical: Theme.spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: Theme.colors.border,
    backgroundColor: Theme.colors.surface,
  },
  title: {
    ...Theme.typography.h3,
    fontSize: 18,
  },
  cancelButton: {
    fontSize: 16,
    color: Theme.colors.textSecondary,
  },
  saveButton: {
    fontSize: 16,
    color: Theme.colors.primary,
    fontWeight: '600',
  },
  content: {
    flex: 1,
    paddingHorizontal: Theme.spacing.md,
  },
  section: {
    marginTop: Theme.spacing.lg,
  },
  label: {
    ...Theme.typography.body,
    fontWeight: '600',
    marginBottom: Theme.spacing.sm,
    color: Theme.colors.text,
  },
  input: {
    borderWidth: 1,
    borderColor: Theme.colors.border,
    borderRadius: Theme.borderRadius.md,
    paddingHorizontal: Theme.spacing.md,
    paddingVertical: Platform.OS === 'ios' ? 12 : 8,
    fontSize: 16,
    backgroundColor: Theme.colors.background,
    color: Theme.colors.text,
  },
  textArea: {
    height: 100,
    textAlignVertical: 'top',
    paddingTop: 12,
  },
  categoryScroll: {
    flexGrow: 0,
    marginHorizontal: -Theme.spacing.md,
    paddingHorizontal: Theme.spacing.md,
  },
  categoryChip: {
    backgroundColor: Theme.colors.background,
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: Theme.borderRadius.full,
    marginRight: 8,
    borderWidth: 1,
    borderColor: Theme.colors.border,
  },
  categoryChipSelected: {
    backgroundColor: Theme.colors.primary,
    borderColor: Theme.colors.primary,
  },
  categoryChipText: {
    fontSize: 14,
    color: Theme.colors.textSecondary,
    fontWeight: '500',
  },
  categoryChipTextSelected: {
    color: '#fff',
  },
  iconScroll: {
    flexGrow: 0,
    marginHorizontal: -Theme.spacing.md,
    paddingHorizontal: Theme.spacing.md,
  },
  iconChip: {
    width: 50,
    height: 50,
    borderRadius: 25,
    backgroundColor: Theme.colors.background,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 8,
    borderWidth: 1,
    borderColor: Theme.colors.border,
  },
  iconChipSelected: {
    borderColor: Theme.colors.primary,
    backgroundColor: `${Theme.colors.primary}20`, // 20% opacity
  },
  iconText: {
    fontSize: 24,
  },
  colorRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 12,
  },
  colorChip: {
    width: 40,
    height: 40,
    borderRadius: 20,
    borderWidth: 3,
    borderColor: 'transparent',
  },
  colorChipSelected: {
    borderColor: Theme.colors.text,
  },
  frequencyRow: {
    flexDirection: 'row',
    gap: 8,
  },
  frequencyChip: {
    flex: 1,
    backgroundColor: Theme.colors.background,
    paddingVertical: 12,
    borderRadius: Theme.borderRadius.md,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: Theme.colors.border,
  },
  frequencyChipSelected: {
    backgroundColor: Theme.colors.primary,
    borderColor: Theme.colors.primary,
  },
  frequencyChipText: {
    fontSize: 14,
    color: Theme.colors.textSecondary,
    fontWeight: '500',
  },
  frequencyChipTextSelected: {
    color: '#fff',
  },
});