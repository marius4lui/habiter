export interface MockHabit {
  id: string;
  name: string;
  description: string;
  icon: string;
  color: string;
  category: string;
}

export const mockHabits: MockHabit[] = [
  {
    id: 'habit-1',
    name: 'Morning Meditation',
    description: '10 minutes of mindfulness',
    icon: '🧘',
    color: '#4ECDC4',
    category: 'Mindfulness',
  },
  {
    id: 'habit-2',
    name: 'Read 30 Pages',
    description: 'Daily reading habit',
    icon: '📚',
    color: '#5F27CD',
    category: 'Learning',
  },
  {
    id: 'habit-3',
    name: 'Drink Water',
    description: 'Stay hydrated',
    icon: '💧',
    color: '#45B7D1',
    category: 'Health',
  },
  {
    id: 'habit-4',
    name: 'Exercise',
    description: '30 min workout',
    icon: '💪',
    color: '#FF6B6B',
    category: 'Fitness',
  },
];

export const mockStreaks: Record<string, number> = {
  'habit-1': 7,
  'habit-2': 3,
  'habit-3': 14,
  'habit-4': 5,
};

export const initialCompletionState: Record<string, boolean> = {
  'habit-1': false,
  'habit-2': false,
  'habit-3': false,
  'habit-4': true, // Pre-completed to show completed state
};
