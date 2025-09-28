# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **Habiter**, a React Native habit-tracking application built with Expo Router. The app helps users build and maintain daily habits with AI-powered insights and analytics.

## Development Commands

**IMPORTANT**: Always use `pnpm` instead of `npm` for this project.

### Core Development
- `pnpm install` - Install dependencies
- `pnpm start` - Start the Expo development server
- `pnpm android` - Start Android development build
- `pnpm ios` - Start iOS development build
- `pnpm web` - Start web development build
- `pnpm lint` - Run ESLint for code quality checks

**Do NOT run**: `npm install`, `npm run build`, `npm run dev`

### Project Maintenance
- `pnpm run reset-project` - Reset the project to initial state (moves existing code to `app-example`)

## Architecture Overview

### Core Structure
- **Expo Router** for file-based routing in `app/` directory
- **React Context API** for state management via `HabitContext`
- **AsyncStorage** for local data persistence
- **TypeScript** for type safety
- **React Native** with cross-platform components

### Key Components

#### State Management
- **HabitContext** (`src/contexts/HabitContext.tsx`): Central state management for habits, entries, and AI insights
- Uses `useReducer` pattern with comprehensive action types
- Handles all CRUD operations for habits, entries, and preferences

#### Data Models
- **Habit**: Core habit entity with properties like frequency, target count, category
- **HabitEntry**: Daily completion tracking with date stamps
- **AIInsight**: AI-generated insights with confidence scores and types
- **UserPreferences**: App settings for theme, notifications, etc.

#### AI Integration
- **AIManager** (`src/services/aiManager.ts`): Singleton service for AI features
- **GLMService** (`src/services/glm.ts`): Integration with GLM AI API
- Generates personalized insights, recommendations, and motivational messages
- Supports habit analysis, pattern recognition, and success predictions

#### UI Architecture
- **Tabs Layout**: Home (index) and Analytics (explore) screens
- **Modal System**: AddHabitModal and AISetupModal for user interactions
- **Component Library**: Reusable components in `src/components/`
- **Chart Integration**: React Native Chart Kit for analytics visualization

### File Organization
```
src/
├── components/     # Reusable UI components
├── contexts/       # React contexts for state management
├── services/       # External service integrations (AI, storage)
├── types/          # TypeScript type definitions
└── utils/          # Utility functions and helpers
```

### Key Features
1. **Habit Tracking**: Create, update, and track daily habits with completion status
2. **AI Insights**: GLM-powered personalized recommendations and analysis
3. **Analytics**: Visual charts and statistics for habit progress
4. **Streak Tracking**: Current and longest streak calculations
5. **Cross-platform**: Works on iOS, Android, and Web

### Data Persistence
- All data stored locally using AsyncStorage
- No external database dependencies
- Automatic data loading on app startup
- Real-time state updates across components

## Development Guidelines

### Code Style
- Follow existing patterns in the codebase
- Use TypeScript interfaces for all data structures
- Implement proper error handling with try-catch blocks
- Use React hooks consistently (useState, useEffect, useContext)

### State Management
- Always use the `useHabits()` hook for habit-related operations
- Leverage the existing context for data operations
- Follow the action types defined in the reducer

### Component Development
- Reuse existing components from `src/components/`
- Follow the established styling patterns with StyleSheet
- Implement proper loading states and error handling
- Use SafeAreaView for proper layout on different devices

### AI Features
- Test AI connections with `AIManager.testConnection()`
- Handle AI service availability gracefully
- Provide fallback UI when AI features are unavailable
- Store API keys securely with AsyncStorage

## Testing and Quality

- Run `pnpm lint` before committing changes
- Ensure all TypeScript types are properly defined
- Test on multiple platforms (iOS, Android, Web) when possible
- Validate data persistence after app restarts