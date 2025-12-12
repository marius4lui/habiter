'use client';

import React from 'react';
import { motion } from 'framer-motion';
import { cn } from '@/lib/cn';

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'ghost';
  size?: 'sm' | 'md' | 'lg';
  isLoading?: boolean;
  children: React.ReactNode;
}

export const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  (
    { className, variant = 'primary', size = 'md', isLoading, children, disabled, onClick, ...props },
    ref,
  ) => {
    const baseStyles =
      'font-medium rounded-lg transition-all duration-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed';

    const variants = {
      primary: 'bg-primary text-white hover:bg-primary-dark shadow-md hover:shadow-lg',
      secondary: 'bg-surface border-2 border-primary text-primary hover:bg-background',
      ghost: 'text-primary hover:bg-background',
    };

    const sizes = {
      sm: 'px-md py-sm text-body-sm',
      md: 'px-lg py-md text-body',
      lg: 'px-xl py-lg text-body font-semibold',
    };

    const buttonClass = cn(baseStyles, variants[variant], sizes[size], className);

    return (
      <motion.button
        ref={ref}
        className={buttonClass}
        whileHover={{ scale: disabled ? 1 : 1.02 }}
        whileTap={{ scale: disabled ? 1 : 0.98 }}
        disabled={disabled || isLoading}
        onClick={onClick}
        {...(props as any)}
      >
        {isLoading ? (
          <span className="flex items-center gap-md">
            <span className="animate-spin">⏳</span>
            Loading...
          </span>
        ) : (
          children
        )}
      </motion.button>
    );
  },
);

Button.displayName = 'Button';
