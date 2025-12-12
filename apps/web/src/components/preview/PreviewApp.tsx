'use client';

import React, { useState } from 'react';
import { HabitCardWeb } from './HabitCardWeb';
import { mockHabits, mockStreaks, initialCompletionState } from '@/lib/mockData';

export const PreviewApp: React.FC = () => {
  const [completions, setCompletions] = useState(initialCompletionState);

  const handleToggle = (habitId: string) => {
    setCompletions((prev) => ({
      ...prev,
      [habitId]: !prev[habitId],
    }));
  };

  const completedCount = Object.values(completions).filter(Boolean).length;

  return (
    <div className="bg-background min-h-full px-md py-lg flex flex-col">
      {/* Header */}
      <div className="mb-lg sticky top-0 bg-background z-10">
        <h1 className="text-h2 font-bold text-text">Today's Habits</h1>
        <p className="text-body-sm text-text-secondary mt-1">
          {completedCount} of {mockHabits.length} completed
        </p>
      </div>

      {/* Habit List */}
      <div className="space-y-sm flex-1">
        {mockHabits.map((habit) => (
          <HabitCardWeb
            key={habit.id}
            id={habit.id}
            name={habit.name}
            description={habit.description}
            icon={habit.icon}
            color={habit.color}
            category={habit.category}
            isCompleted={completions[habit.id]}
            streak={mockStreaks[habit.id]}
            onToggle={() => handleToggle(habit.id)}
          />
        ))}
      </div>
    </div>
  );
};
