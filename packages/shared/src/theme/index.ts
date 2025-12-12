export { colors } from './colors';
export { spacing } from './spacing';
export { borderRadius } from './borderRadius';
export { typography } from './typography';
export { gradients } from './gradients';
export { shadows, coloredShadow } from './shadows';

// Combined theme object
export const theme = {
  colors,
  spacing,
  borderRadius,
  typography,
  gradients,
  shadows,
} as const;

export * from './colors';
export * from './spacing';
export * from './borderRadius';
export * from './typography';
export * from './gradients';
export * from './shadows';
