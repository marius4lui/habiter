'use client';

import React from 'react';
import { cn } from '@/lib/cn';

interface SectionProps {
  children: React.ReactNode;
  className?: string;
  id?: string;
  fullWidth?: boolean;
  background?: 'default' | 'light' | 'dark' | 'gradient';
}

export const Section: React.FC<SectionProps> = ({
  children,
  className,
  id,
  fullWidth = false,
  background = 'default',
}) => {
  const backgrounds = {
    default: 'bg-surface',
    light: 'bg-background',
    dark: 'bg-background-dark',
    gradient: 'bg-gradient-to-br from-primary/5 to-secondary/5',
  };

  return (
    <section id={id} className={cn(backgrounds[background], 'py-xxxl')}>
      <div className={cn(!fullWidth && 'max-w-content mx-auto px-lg', className)}>
        {children}
      </div>
    </section>
  );
};
