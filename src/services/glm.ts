import axios from 'axios';
import { Habit, HabitEntry, AIInsight } from '../types/habit';

export interface GLMConfig {
  apiKey: string;
  baseUrl: string;
}

export class GLMService {
  private config: GLMConfig;

  constructor(config: GLMConfig) {
    this.config = config;
  }

  private async makeRequest(prompt: string): Promise<string> {
    try {
      const response = await axios.post(
        `${this.config.baseUrl}/api/paas/v4/chat/completions`,
        {
          model: 'glm-4',
          messages: [
            {
              role: 'system',
              content: 'You are a helpful AI assistant specialized in habit tracking and personal development. Provide concise, actionable advice.'
            },
            {
              role: 'user',
              content: prompt
            }
          ],
          temperature: 0.7,
          max_tokens: 200
        },
        {
          headers: {
            'Authorization': `Bearer ${this.config.apiKey}`,
            'Content-Type': 'application/json'
          }
        }
      );

      return response.data.choices[0]?.message?.content || 'No response generated';
    } catch (error) {
      console.error('GLM API Error:', error);
      throw new Error('Failed to get AI response');
    }
  }

  async generateHabitRecommendation(habits: Habit[]): Promise<AIInsight> {
    const habitList = habits.map(h => `${h.name} (${h.category})`).join(', ');
    const prompt = `Based on these existing habits: ${habitList}, suggest one new complementary habit that would enhance personal growth. Keep it specific and actionable.`;

    try {
      const response = await this.makeRequest(prompt);
      return {
        id: Date.now().toString(),
        type: 'recommendation',
        title: 'New Habit Suggestion',
        message: response,
        confidence: 0.8,
        createdAt: new Date(),
        isRead: false
      };
    } catch {
      throw new Error('Failed to generate habit recommendation');
    }
  }

  async generateMotivationalMessage(habit: Habit, streak: number): Promise<AIInsight> {
    const prompt = `Generate a motivational message for someone who has maintained their "${habit.name}" habit for ${streak} days in a row. Keep it encouraging and personalized.`;

    try {
      const response = await this.makeRequest(prompt);
      return {
        id: Date.now().toString(),
        habitId: habit.id,
        type: 'motivation',
        title: `Keep Going with ${habit.name}!`,
        message: response,
        confidence: 0.9,
        createdAt: new Date(),
        isRead: false
      };
    } catch {
      throw new Error('Failed to generate motivational message');
    }
  }

  async analyzeHabitPattern(habit: Habit, entries: HabitEntry[]): Promise<AIInsight> {
    const completionRate = entries.length > 0 ?
      (entries.filter(e => e.completed).length / entries.length * 100).toFixed(1) : 0;

    const recentEntries = entries.slice(-7); // Last 7 entries
    const recentCompletions = recentEntries.filter(e => e.completed).length;

    const prompt = `Analyze this habit pattern: "${habit.name}" has a ${completionRate}% completion rate overall, with ${recentCompletions} completions in the last 7 tracked days. Provide insights and suggestions for improvement.`;

    try {
      const response = await this.makeRequest(prompt);
      return {
        id: Date.now().toString(),
        habitId: habit.id,
        type: 'analysis',
        title: `Analysis: ${habit.name}`,
        message: response,
        confidence: 0.85,
        createdAt: new Date(),
        isRead: false
      };
    } catch {
      throw new Error('Failed to analyze habit pattern');
    }
  }

  async predictHabitSuccess(habit: Habit, entries: HabitEntry[]): Promise<AIInsight> {
    const totalDays = entries.length;
    const completions = entries.filter(e => e.completed).length;
    const completionRate = totalDays > 0 ? (completions / totalDays * 100).toFixed(1) : 0;

    // Calculate recent trend (last 7 vs previous 7)
    const recent7 = entries.slice(-7).filter(e => e.completed).length;
    const previous7 = entries.slice(-14, -7).filter(e => e.completed).length;
    const trend = recent7 > previous7 ? 'improving' : recent7 < previous7 ? 'declining' : 'stable';

    const prompt = `Based on ${totalDays} days of data with ${completionRate}% completion rate and a ${trend} trend, predict the likelihood of maintaining "${habit.name}" habit long-term and provide actionable advice.`;

    try {
      const response = await this.makeRequest(prompt);
      return {
        id: Date.now().toString(),
        habitId: habit.id,
        type: 'prediction',
        title: `Future Outlook: ${habit.name}`,
        message: response,
        confidence: 0.75,
        createdAt: new Date(),
        isRead: false
      };
    } catch {
      throw new Error('Failed to predict habit success');
    }
  }

  async generatePersonalizedTips(habits: Habit[], entries: HabitEntry[]): Promise<AIInsight> {
    const habitSummary = habits.map(habit => {
      const habitEntries = entries.filter(e => e.habitId === habit.id);
      const rate = habitEntries.length > 0 ?
        (habitEntries.filter(e => e.completed).length / habitEntries.length * 100).toFixed(0) : 0;
      return `${habit.name}: ${rate}%`;
    }).join(', ');

    const prompt = `Based on these habit completion rates: ${habitSummary}, provide 3 personalized tips to improve overall habit consistency and success.`;

    try {
      const response = await this.makeRequest(prompt);
      return {
        id: Date.now().toString(),
        type: 'recommendation',
        title: 'Personalized Tips',
        message: response,
        confidence: 0.9,
        createdAt: new Date(),
        isRead: false
      };
    } catch {
      throw new Error('Failed to generate personalized tips');
    }
  }
}

// Default configuration (users should provide their own API key)
export const createGLMService = (apiKey: string): GLMService => {
  return new GLMService({
    apiKey,
    baseUrl: 'https://open.bigmodel.cn'
  });
};