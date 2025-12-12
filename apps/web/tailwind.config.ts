import type { Config } from 'tailwindcss';

// Theme values (matching shared/theme)
const colors = {
  primary: '#0066FF',
  primaryDark: '#0052CC',
  primaryLight: '#3385FF',
  secondary: '#00C7BE',
  secondaryDark: '#00A399',
  background: '#F8F9FA',
  backgroundDark: '#ECEFF1',
  surface: '#FFFFFF',
  surfaceElevated: '#FFFFFF',
  text: '#1A1A1A',
  textSecondary: '#6B7280',
  textTertiary: '#9CA3AF',
  textInverse: '#FFFFFF',
  border: '#E5E7EB',
  borderLight: '#F3F4F6',
  success: '#00C896',
  successLight: '#E6F9F4',
  warning: '#FFB020',
  warningLight: '#FFF4E5',
  error: '#FF4757',
  errorLight: '#FFE8EB',
  info: '#0066FF',
  infoLight: '#E5F0FF',
  accent1: '#00C896',
  accent2: '#FF6B9D',
  accent3: '#8B5CF6',
  accent4: '#00C7BE',
  accent5: '#FFB020',
  accent6: '#FF4757',
};

const spacing = {
  xs: 4,
  sm: 8,
  md: 16,
  lg: 24,
  xl: 32,
  xxl: 48,
  xxxl: 64,
};

const borderRadius = {
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 20,
  xxl: 24,
  full: 9999,
};

const typography = {
  h1: { fontSize: 32, fontWeight: '800', letterSpacing: -1 },
  h2: { fontSize: 24, fontWeight: '700', letterSpacing: -0.5 },
  h3: { fontSize: 20, fontWeight: '600', letterSpacing: -0.3 },
  body: { fontSize: 16, fontWeight: '400', lineHeight: 24 },
  bodySmall: { fontSize: 14, fontWeight: '400', lineHeight: 20 },
  caption: { fontSize: 12, fontWeight: '500', letterSpacing: 0.5 },
  label: { fontSize: 11, fontWeight: '600', letterSpacing: 0.8 },
};

const config: Config = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        // Primary palette
        primary: {
          DEFAULT: colors.primary,
          dark: colors.primaryDark,
          light: colors.primaryLight,
        },
        secondary: {
          DEFAULT: colors.secondary,
          dark: colors.secondaryDark,
        },
        // Backgrounds
        background: colors.background,
        'background-dark': colors.backgroundDark,
        surface: colors.surface,
        'surface-elevated': colors.surfaceElevated,
        // Text
        text: colors.text,
        'text-secondary': colors.textSecondary,
        'text-tertiary': colors.textTertiary,
        'text-inverse': colors.textInverse,
        // Borders
        border: colors.border,
        'border-light': colors.borderLight,
        // Status
        success: colors.success,
        'success-light': colors.successLight,
        warning: colors.warning,
        'warning-light': colors.warningLight,
        error: colors.error,
        'error-light': colors.errorLight,
        info: colors.info,
        'info-light': colors.infoLight,
        // Accents
        accent1: colors.accent1,
        accent2: colors.accent2,
        accent3: colors.accent3,
        accent4: colors.accent4,
        accent5: colors.accent5,
        accent6: colors.accent6,
      },
      spacing: {
        xs: `${spacing.xs}px`,
        sm: `${spacing.sm}px`,
        md: `${spacing.md}px`,
        lg: `${spacing.lg}px`,
        xl: `${spacing.xl}px`,
        xxl: `${spacing.xxl}px`,
        xxxl: `${spacing.xxxl}px`,
      },
      borderRadius: {
        xs: `${borderRadius.xs}px`,
        sm: `${borderRadius.sm}px`,
        md: `${borderRadius.md}px`,
        lg: `${borderRadius.lg}px`,
        xl: `${borderRadius.xl}px`,
        xxl: `${borderRadius.xxl}px`,
      },
      fontSize: {
        h1: [`${typography.h1.fontSize}px`, {
          fontWeight: typography.h1.fontWeight,
          letterSpacing: `${typography.h1.letterSpacing}px`,
        }],
        h2: [`${typography.h2.fontSize}px`, {
          fontWeight: typography.h2.fontWeight,
          letterSpacing: `${typography.h2.letterSpacing}px`,
        }],
        h3: [`${typography.h3.fontSize}px`, {
          fontWeight: typography.h3.fontWeight,
          letterSpacing: `${typography.h3.letterSpacing}px`,
        }],
        body: [`${typography.body.fontSize}px`, {
          lineHeight: `${typography.body.lineHeight}px`,
        }],
        'body-sm': [`${typography.bodySmall.fontSize}px`, {
          lineHeight: `${typography.bodySmall.lineHeight}px`,
        }],
        caption: [`${typography.caption.fontSize}px`, {
          letterSpacing: `${typography.caption.letterSpacing}px`,
        }],
        label: [`${typography.label.fontSize}px`, {
          letterSpacing: `${typography.label.letterSpacing}px`,
        }],
      },
      fontWeight: {
        regular: '400',
        medium: '500',
        semibold: '600',
        bold: '700',
        extrabold: '800',
      },
      boxShadow: {
        sm: '0 1px 2px 0 rgba(0, 0, 0, 0.05)',
        md: '0 2px 4px 0 rgba(0, 0, 0, 0.06)',
        lg: '0 4px 8px 0 rgba(0, 0, 0, 0.08)',
        xl: '0 8px 16px 0 rgba(0, 0, 0, 0.1)',
      },
      animation: {
        'fade-in': 'fadeIn 0.5s ease-in-out',
        'slide-up': 'slideUp 0.5s ease-out',
        float: 'float 3s ease-in-out infinite',
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        slideUp: {
          '0%': { transform: 'translateY(20px)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' },
        },
        float: {
          '0%, 100%': { transform: 'translateY(0px)' },
          '50%': { transform: 'translateY(-10px)' },
        },
      },
      maxWidth: {
        content: '1280px',
      },
    },
  },
  plugins: [],
};

export default config;
