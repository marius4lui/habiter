import { useWindowDimensions } from 'react-native';

export const BREAKPOINTS = {
  TABLET: 768,
  DESKTOP: 1024,
  WIDE: 1280,
};

export const useResponsive = () => {
  const { width, height } = useWindowDimensions();

  const isMobile = width < BREAKPOINTS.TABLET;
  const isTablet = width >= BREAKPOINTS.TABLET && width < BREAKPOINTS.DESKTOP;
  const isDesktop = width >= BREAKPOINTS.DESKTOP;
  const isWide = width >= BREAKPOINTS.WIDE;

  // Calculate number of columns for grid layouts
  let numColumns = 1;
  if (width >= BREAKPOINTS.WIDE) {
    numColumns = 4;
  } else if (width >= BREAKPOINTS.DESKTOP) {
    numColumns = 3;
  } else if (width >= BREAKPOINTS.TABLET) {
    numColumns = 2;
  }

  // Calculate max content width for centering on large screens
  const maxContentWidth = isDesktop ? 1200 : '100%';

  // Dynamic spacing
  const spacing = {
    xs: isMobile ? 4 : 6,
    sm: isMobile ? 8 : 12,
    md: isMobile ? 16 : 24,
    lg: isMobile ? 24 : 32,
    xl: isMobile ? 32 : 48,
  };

  // Dynamic font sizes
  const fontSizes = {
    xs: isMobile ? 12 : 14,
    sm: isMobile ? 14 : 16,
    md: isMobile ? 16 : 18,
    lg: isMobile ? 20 : 24,
    xl: isMobile ? 24 : 32,
    xxl: isMobile ? 32 : 48,
  };

  return {
    isMobile,
    isTablet,
    isDesktop,
    isWide,
    width,
    height,
    numColumns,
    maxContentWidth,
    spacing,
    fontSizes,
    BREAKPOINTS,
  };
};
