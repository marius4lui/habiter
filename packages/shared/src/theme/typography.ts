import { colors } from './colors';

export const typography = {
  h1: {
    fontSize: 32,
    fontWeight: '800' as const,
    color: colors.text,
    letterSpacing: -1,
  },
  h2: {
    fontSize: 24,
    fontWeight: '700' as const,
    color: colors.text,
    letterSpacing: -0.5,
  },
  h3: {
    fontSize: 20,
    fontWeight: '600' as const,
    color: colors.text,
    letterSpacing: -0.3,
  },
  body: {
    fontSize: 16,
    fontWeight: '400' as const,
    color: colors.text,
    lineHeight: 24,
  },
  bodyMedium: {
    fontSize: 16,
    fontWeight: '500' as const,
    color: colors.text,
    lineHeight: 24,
  },
  bodySmall: {
    fontSize: 14,
    fontWeight: '400' as const,
    color: colors.textSecondary,
    lineHeight: 20,
  },
  caption: {
    fontSize: 12,
    fontWeight: '500' as const,
    color: colors.textTertiary,
    letterSpacing: 0.5,
  },
  label: {
    fontSize: 11,
    fontWeight: '600' as const,
    color: colors.textSecondary,
    letterSpacing: 0.8,
    textTransform: 'uppercase' as const,
  },
} as const;
