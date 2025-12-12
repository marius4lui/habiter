'use client';

import React from 'react';
import { cn } from '@/lib/cn';

interface CardProps extends React.HTMLAttributes<HTMLDivElement> {
  children: React.ReactNode;
  hover?: boolean;
}

export const Card = React.forwardRef<HTMLDivElement, CardProps>(
  ({ className, hover = false, children, ...props }, ref) => {
    const baseStyles = 'bg-surface rounded-lg border border-border-light shadow-sm p-lg transition-all duration-200';

    const hoverStyles = hover ? 'hover:shadow-md hover:-translate-y-1 cursor-pointer' : '';

    return (
      <div
        ref={ref}
        className={cn(baseStyles, hoverStyles, className)}
        {...props}
      >
        {children}
      </div>
    );
  },
);

Card.displayName = 'Card';
