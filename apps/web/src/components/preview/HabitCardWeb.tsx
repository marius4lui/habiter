'use client';

import React from 'react';
import { motion } from 'framer-motion';

interface HabitCardWebProps {
  id: string;
  name: string;
  description?: string;
  icon: string;
  color: string;
  category: string;
  isCompleted: boolean;
  streak: number;
  onToggle: () => void;
}

export const HabitCardWeb: React.FC<HabitCardWebProps> = ({
  id,
  name,
  description,
  icon,
  color,
  category,
  isCompleted,
  streak,
  onToggle,
}) => {
  return (
    <motion.div
      key={id}
      whileHover={{ scale: 1.02 }}
      whileTap={{ scale: 0.98 }}
      className="bg-surface rounded-lg p-lg shadow-sm border border-border-light"
    >
      <div className="flex items-center justify-between mb-md">
        <div className="flex items-center gap-md flex-1">
          {/* Icon Container */}
          <div
            className="w-11 h-11 rounded-full flex items-center justify-center flex-shrink-0"
            style={{ backgroundColor: `${color}15` }}
          >
            <span className="text-2xl">{icon}</span>
          </div>

          {/* Text Content */}
          <div className="flex-1 min-w-0">
            <h3 className="text-body font-semibold text-text truncate">{name}</h3>
            {description && (
              <p className="text-caption text-text-tertiary truncate">{description}</p>
            )}
          </div>
        </div>

        {/* Checkbox Button */}
        <motion.button
          onClick={onToggle}
          whileHover={{ scale: 1.1 }}
          whileTap={{ scale: 0.9 }}
          className="w-7 h-7 rounded-full border-2 flex items-center justify-center flex-shrink-0 transition-all"
          style={{
            borderColor: isCompleted ? color : '#E5E7EB',
            backgroundColor: isCompleted ? color : 'transparent',
          }}
        >
          {isCompleted && (
            <span className="text-white text-sm font-bold">✓</span>
          )}
        </motion.button>
      </div>

      {/* Footer */}
      <div className="flex items-center justify-between">
        {streak > 0 && (
          <div
            className="flex items-center gap-1 px-sm py-1 rounded-full"
            style={{ backgroundColor: `${color}15` }}
          >
            <span className="text-sm">🔥</span>
            <span
              className="text-caption font-semibold"
              style={{ color }}
            >
              {streak} day{streak !== 1 ? 's' : ''}
            </span>
          </div>
        )}

        <div className="bg-background-dark px-sm py-1 rounded-sm ml-auto">
          <span className="text-label text-text-tertiary">{category}</span>
        </div>
      </div>
    </motion.div>
  );
};
