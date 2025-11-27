
// Premium Color Palette - Modern & Vibrant
export const Palette = {
  // Primary - Rich Purple Gradient
  primary: '#8B5CF6',
  primaryDark: '#7C3AED',
  primaryLight: '#A78BFA',
  primaryGradient: ['#8B5CF6', '#EC4899'], // Purple to Pink

  // Secondary - Vibrant Cyan
  secondary: '#06B6D4',
  secondaryDark: '#0891B2',

  // Background - Clean & Modern
  background: '#FAFAFA',
  backgroundDark: '#F5F5F7',
  surface: '#FFFFFF',
  surfaceElevated: '#FFFFFF',

  // Text
  text: '#0F172A',
  textSecondary: '#475569',
  textTertiary: '#94A3B8',
  textInverse: '#FFFFFF',

  // Borders
  border: '#E2E8F0',
  borderLight: '#F1F5F9',

  // Status Colors - Vibrant & Clear
  success: '#10B981',
  successLight: '#D1FAE5',
  warning: '#F59E0B',
  warningLight: '#FEF3C7',
  error: '#EF4444',
  errorLight: '#FEE2E2',
  info: '#3B82F6',
  infoLight: '#DBEAFE',

  // Accent Colors for Cards
  accent1: '#F59E0B', // Amber
  accent2: '#EC4899', // Pink
  accent3: '#8B5CF6', // Purple
  accent4: '#06B6D4', // Cyan
  accent5: '#10B981', // Emerald
  accent6: '#F97316', // Orange
};

export const Gradients = {
  primary: ['#8B5CF6', '#EC4899'],
  secondary: ['#06B6D4', '#3B82F6'],
  success: ['#10B981', '#34D399'],
  warm: ['#F59E0B', '#F97316'],
  cool: ['#3B82F6', '#8B5CF6'],
  sunset: ['#F97316', '#EC4899'],
};

export const Shadows = {
  sm: {
    shadowColor: '#0F172A',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.06,
    shadowRadius: 3,
    elevation: 2,
  },
  md: {
    shadowColor: '#0F172A',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.08,
    shadowRadius: 8,
    elevation: 4,
  },
  lg: {
    shadowColor: '#0F172A',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.1,
    shadowRadius: 16,
    elevation: 8,
  },
  xl: {
    shadowColor: '#0F172A',
    shadowOffset: { width: 0, height: 12 },
    shadowOpacity: 0.12,
    shadowRadius: 24,
    elevation: 12,
  },
  colored: (color: string, opacity: number = 0.3) => ({
    shadowColor: color,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: opacity,
    shadowRadius: 12,
    elevation: 6,
  }),
};

export const Spacing = {
  xs: 4,
  sm: 8,
  md: 16,
  lg: 24,
  xl: 32,
  xxl: 48,
  xxxl: 64,
};

export const BorderRadius = {
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 20,
  xxl: 24,
  full: 9999,
};

export const Typography = {
  h1: {
    fontSize: 32,
    fontWeight: '800' as const,
    color: Palette.text,
    letterSpacing: -1,
  },
  h2: {
    fontSize: 24,
    fontWeight: '700' as const,
    color: Palette.text,
    letterSpacing: -0.5,
  },
  h3: {
    fontSize: 20,
    fontWeight: '600' as const,
    color: Palette.text,
    letterSpacing: -0.3,
  },
  body: {
    fontSize: 16,
    fontWeight: '400' as const,
    color: Palette.text,
    lineHeight: 24,
  },
  bodyMedium: {
    fontSize: 16,
    fontWeight: '500' as const,
    color: Palette.text,
    lineHeight: 24,
  },
  bodySmall: {
    fontSize: 14,
    fontWeight: '400' as const,
    color: Palette.textSecondary,
    lineHeight: 20,
  },
  caption: {
    fontSize: 12,
    fontWeight: '500' as const,
    color: Palette.textTertiary,
    letterSpacing: 0.5,
  },
  label: {
    fontSize: 11,
    fontWeight: '600' as const,
    color: Palette.textSecondary,
    letterSpacing: 0.8,
    textTransform: 'uppercase' as const,
  },
};

export const Theme = {
  colors: Palette,
  gradients: Gradients,
  shadows: Shadows,
  spacing: Spacing,
  borderRadius: BorderRadius,
  typography: Typography,
};
