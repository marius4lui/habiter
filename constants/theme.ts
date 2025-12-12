
// Clean & Minimal Color Palette
export const Palette = {
  // Primary - Modern Blue
  primary: '#0066FF',
  primaryDark: '#0052CC',
  primaryLight: '#3385FF',
  primaryGradient: ['#0066FF', '#0052CC'],

  // Secondary - Subtle Accent
  secondary: '#00C7BE',
  secondaryDark: '#00A399',

  // Background - Ultra Clean
  background: '#F8F9FA',
  backgroundDark: '#ECEFF1',
  surface: '#FFFFFF',
  surfaceElevated: '#FFFFFF',

  // Text
  text: '#1A1A1A',
  textSecondary: '#6B7280',
  textTertiary: '#9CA3AF',
  textInverse: '#FFFFFF',

  // Borders - Subtle
  border: '#E5E7EB',
  borderLight: '#F3F4F6',

  // Status Colors - Clean & Clear
  success: '#00C896',
  successLight: '#E6F9F4',
  warning: '#FFB020',
  warningLight: '#FFF4E5',
  error: '#FF4757',
  errorLight: '#FFE8EB',
  info: '#0066FF',
  infoLight: '#E5F0FF',

  // Accent Colors for Cards - Refined
  accent1: '#00C896', // Teal
  accent2: '#FF6B9D', // Pink
  accent3: '#8B5CF6', // Purple
  accent4: '#00C7BE', // Cyan
  accent5: '#FFB020', // Amber
  accent6: '#FF4757', // Red
};

export const Gradients = {
  primary: ['#0066FF', '#0052CC'],
  secondary: ['#00C7BE', '#00A399'],
  success: ['#00C896', '#00A077'],
  warm: ['#FFB020', '#FF9500'],
  cool: ['#0066FF', '#8B5CF6'],
  sunset: ['#FF6B9D', '#FF4757'],
};

export const Shadows = {
  sm: {
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 2,
    elevation: 1,
  },
  md: {
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.06,
    shadowRadius: 4,
    elevation: 2,
  },
  lg: {
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.08,
    shadowRadius: 8,
    elevation: 4,
  },
  xl: {
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.1,
    shadowRadius: 16,
    elevation: 6,
  },
  colored: (color: string, opacity: number = 0.15) => ({
    shadowColor: color,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: opacity,
    shadowRadius: 8,
    elevation: 3,
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
