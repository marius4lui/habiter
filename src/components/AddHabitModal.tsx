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
    backgroundColor: Theme.colors.background,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: Theme.spacing.lg,
    paddingVertical: Theme.spacing.lg,
    borderBottomWidth: 1,
    borderBottomColor: Theme.colors.borderLight,
    backgroundColor: Theme.colors.background,
  },
  title: {
    fontSize: 20,
    fontWeight: '700',
    color: Theme.colors.text,
  },
  cancelButton: {
    fontSize: 16,
    color: Theme.colors.textSecondary,
    fontWeight: '500',
  },
  saveButton: {
    fontSize: 16,
    color: Theme.colors.primary,
    fontWeight: '700',
  },
  content: {
    flex: 1,
    paddingHorizontal: Theme.spacing.lg,
  },
  section: {
    marginTop: Theme.spacing.lg,
  },
  label: {
    fontSize: 15,
    fontWeight: '600',
    marginBottom: Theme.spacing.sm,
    color: Theme.colors.text,
  },
  input: {
    borderWidth: 1,
    borderColor: Theme.colors.borderLight,
    borderRadius: Theme.borderRadius.sm,
    paddingHorizontal: Theme.spacing.md,
    paddingVertical: Platform.OS === 'ios' ? 14 : 10,
    fontSize: 16,
    backgroundColor: Theme.colors.surface,
    color: Theme.colors.text,
  },
  textArea: {
    height: 90,
    textAlignVertical: 'top',
    paddingTop: 14,
  },
  categoryScroll: {
    flexGrow: 0,
    marginHorizontal: -Theme.spacing.lg,
    paddingHorizontal: Theme.spacing.lg,
  },
  categoryChip: {
    backgroundColor: Theme.colors.surface,
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderRadius: Theme.borderRadius.full,
    marginRight: 8,
    borderWidth: 1.5,
    borderColor: Theme.colors.borderLight,
  },
  categoryChipSelected: {
    backgroundColor: Theme.colors.primary,
    borderColor: Theme.colors.primary,
  },
  categoryChipText: {
    fontSize: 14,
    color: Theme.colors.text,
    fontWeight: '600',
  },
  categoryChipTextSelected: {
    color: '#fff',
    fontWeight: '600',
  },
  iconScroll: {
    flexGrow: 0,
    marginHorizontal: -Theme.spacing.lg,
    paddingHorizontal: Theme.spacing.lg,
  },
  iconChip: {
    width: 52,
    height: 52,
    borderRadius: 26,
    backgroundColor: Theme.colors.surface,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 10,
    borderWidth: 1.5,
    borderColor: Theme.colors.borderLight,
  },
  iconChipSelected: {
    borderColor: Theme.colors.primary,
    backgroundColor: `${Theme.colors.primary}15`,
    borderWidth: 2,
  },
  iconText: {
    fontSize: 26,
  },
  colorRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 14,
  },
  colorChip: {
    width: 44,
    height: 44,
    borderRadius: 22,
    borderWidth: 3,
    borderColor: 'transparent',
  },
  colorChipSelected: {
    borderColor: Theme.colors.text,
    borderWidth: 4,
  },
  frequencyRow: {
    flexDirection: 'row',
    gap: 10,
  },
  frequencyChip: {
    flex: 1,
    backgroundColor: Theme.colors.surface,
    paddingVertical: 14,
    borderRadius: Theme.borderRadius.sm,
    alignItems: 'center',
    borderWidth: 1.5,
    borderColor: Theme.colors.borderLight,
  },
  frequencyChipSelected: {
    backgroundColor: Theme.colors.primary,
    borderColor: Theme.colors.primary,
    borderWidth: 1.5,
  },
  frequencyChipText: {
    fontSize: 14,
    color: Theme.colors.text,
    fontWeight: '600',
  },
  frequencyChipTextSelected: {
    color: '#fff',
    fontWeight: '600',
  },
});