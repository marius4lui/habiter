import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  Modal,
  ScrollView,
  StyleSheet,
  Alert,
} from 'react-native';
import { Habit } from '../types/habit';
import { useHabits } from '../contexts/HabitContext';
import { getRandomColor, getHabitIconSuggestions } from '../utils/habitUtils';

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
          <TouchableOpacity onPress={onClose}>
            <Text style={styles.cancelButton}>Cancel</Text>
          </TouchableOpacity>
          <Text style={styles.title}>New Habit</Text>
          <TouchableOpacity onPress={handleSubmit}>
            <Text style={styles.saveButton}>Save</Text>
          </TouchableOpacity>
        </View>

        <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
          {/* Habit Name */}
          <View style={styles.section}>
            <Text style={styles.label}>Name *</Text>
            <TextInput
              style={styles.input}
              value={formData.name}
              onChangeText={(text) => setFormData(prev => ({ ...prev, name: text }))}
              placeholder="Enter habit name"
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
  textArea: {
    height: 80,
    textAlignVertical: 'top',
  },
  categoryScroll: {
    flexGrow: 0,
  },
  categoryChip: {
    backgroundColor: '#f8f9fa',
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 20,
    marginRight: 8,
    borderWidth: 1,
    borderColor: '#e1e5e9',
  },
  categoryChipSelected: {
    backgroundColor: '#007AFF',
    borderColor: '#007AFF',
  },
  categoryChipText: {
    fontSize: 14,
    color: '#666',
    fontWeight: '500',
  },
  categoryChipTextSelected: {
    color: '#fff',
  },
  iconScroll: {
    flexGrow: 0,
  },
  iconChip: {
    width: 50,
    height: 50,
    borderRadius: 25,
    backgroundColor: '#f8f9fa',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 8,
    borderWidth: 2,
    borderColor: '#e1e5e9',
  },
  iconChipSelected: {
    borderColor: '#007AFF',
    backgroundColor: '#e3f2fd',
  },
  iconText: {
    fontSize: 24,
  },
  colorRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
  },
  colorChip: {
    width: 40,
    height: 40,
    borderRadius: 20,
    marginRight: 12,
    marginBottom: 8,
    borderWidth: 3,
    borderColor: 'transparent',
  },
  colorChipSelected: {
    borderColor: '#333',
  },
  frequencyRow: {
    flexDirection: 'row',
  },
  frequencyChip: {
    flex: 1,
    backgroundColor: '#f8f9fa',
    paddingVertical: 12,
    borderRadius: 8,
    alignItems: 'center',
    marginRight: 8,
    borderWidth: 1,
    borderColor: '#e1e5e9',
  },
  frequencyChipSelected: {
    backgroundColor: '#007AFF',
    borderColor: '#007AFF',
  },
  frequencyChipText: {
    fontSize: 14,
    color: '#666',
    fontWeight: '500',
  },
  frequencyChipTextSelected: {
    color: '#fff',
  },
});