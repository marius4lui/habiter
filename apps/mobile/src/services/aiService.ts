import axios, { AxiosInstance } from 'axios';
import { AIInsight, Habit, HabitEntry } from '../types/habit';

// AI Provider Types
export type AIProvider = 'glm' | 'openai' | 'openrouter';

export interface AIConfig {
    provider: AIProvider;
    apiKey: string;
    model?: string;
}

// Provider Configurations
const PROVIDER_CONFIGS = {
    glm: {
        baseUrl: 'https://open.bigmodel.cn/api/paas/v4',
        defaultModel: 'glm-4-flash',
        models: ['glm-4-flash', 'glm-4', 'glm-4-plus', 'glm-4-air'],
    },
    openai: {
        baseUrl: 'https://api.openai.com/v1',
        defaultModel: 'gpt-4o-mini',
        models: ['gpt-4o-mini', 'gpt-4o', 'gpt-4-turbo', 'gpt-3.5-turbo'],
    },
    openrouter: {
        baseUrl: 'https://openrouter.ai/api/v1',
        defaultModel: 'anthropic/claude-3.5-sonnet',
        models: [
            'anthropic/claude-3.5-sonnet',
            'anthropic/claude-3-haiku',
            'google/gemini-flash-1.5',
            'google/gemini-pro-1.5',
            'meta-llama/llama-3.1-70b-instruct',
            'mistralai/mixtral-8x7b-instruct',
        ],
    },
};

// Smart Prompt Templates
const PROMPTS = {
    system: {
        base: `You are an expert habit coach and behavioral psychologist. You understand:
- The psychology behind habit formation and maintenance
- Evidence-based strategies for behavior change
- The importance of personalization and context
- How to provide actionable, specific advice

Always be:
- Encouraging yet realistic
- Specific and actionable
- Concise (2-3 sentences max)
- Empathetic and understanding`,
    },

    recommendation: (habits: Habit[]) => {
        const categories = [...new Set(habits.map(h => h.category))];
        const habitNames = habits.map(h => h.name).join(', ');

        return `Analyze these existing habits: ${habitNames}

Current focus areas: ${categories.join(', ')}

Suggest ONE new complementary habit that:
1. Fills a gap in their current routine
2. Builds on their existing success
3. Is specific and immediately actionable
4. Takes 5-15 minutes daily

Format: "Try [specific habit]. [Why it complements their routine]. [Exact action to take]."`;
    },

    motivation: (habit: Habit, streak: number, context: { category: string; time: string }) => {
        const milestones = {
            7: 'first week',
            14: 'two solid weeks',
            21: '21-day milestone',
            30: 'full month',
            60: 'two months',
            100: '100-day achievement',
        };

        const milestone = Object.entries(milestones)
            .reverse()
            .find(([days]) => streak >= parseInt(days))?.[1] || `${streak} days`;

        return `You're celebrating someone's ${milestone} streak with "${habit.name}" in their ${context.category.toLowerCase()} routine.

Context: It's ${context.time} and they're maintaining momentum.

Write a powerful 2-sentence motivation that:
1. Acknowledges their specific achievement
2. Shows the compound effect they've created
3. Energizes them for the next step

Be authentic, not generic.`;
    },

    analysis: (habit: Habit, stats: { completionRate: number; recentRate: number; totalDays: number; bestStreak: number }) => {
        const trend = stats.recentRate > stats.completionRate ? 'improving' :
            stats.recentRate < stats.completionRate ? 'declining' : 'stable';

        return `Analyze this habit performance:

Habit: "${habit.name}" (${habit.category})
Overall: ${stats.completionRate}% over ${stats.totalDays} days
Recent (7 days): ${stats.recentRate}%
Best streak: ${stats.bestStreak} days
Trend: ${trend}

Provide:
1. Key insight about the pattern (what stands out?)
2. ONE specific, actionable improvement strategy
3. Why this strategy fits their data

Be data-driven and specific.`;
    },

    prediction: (habit: Habit, stats: {
        completionRate: number;
        trend: string;
        consistency: number;
        timeOfDay?: string
    }) => {
        return `Predict long-term success for this habit:

"${habit.name}"
- Success rate: ${stats.completionRate}%
- Trend: ${stats.trend}
- Consistency score: ${stats.consistency}/10
${stats.timeOfDay ? `- Usually tracked: ${stats.timeOfDay}` : ''}

Provide:
1. Success likelihood (high/medium/low) with WHY
2. The #1 risk factor to watch
3. ONE concrete action to improve odds

Base it on behavioral science.`;
    },

    personalizedTips: (habitSummary: Array<{ name: string; rate: number; category: string }>) => {
        const avgRate = habitSummary.reduce((sum, h) => sum + h.rate, 0) / habitSummary.length;
        const weakest = habitSummary.reduce((min, h) => h.rate < min.rate ? h : min);

        return `Analyze habit performance holistically:

${habitSummary.map(h => `- ${h.name} (${h.category}): ${h.rate}%`).join('\n')}

Average: ${avgRate.toFixed(0)}%
Weakest: ${weakest.name} at ${weakest.rate}%

Provide 3 evidence-based tips that:
1. Target the weakest link
2. Leverage existing strengths  
3. Add a habit stacking opportunity

Each tip: ONE sentence, specific action.`;
    },
};

export class UnifiedAIService {
    private config: AIConfig;
    private axiosInstance: AxiosInstance;
    private providerConfig: typeof PROVIDER_CONFIGS[AIProvider];

    constructor(config: AIConfig) {
        this.config = config;
        this.providerConfig = PROVIDER_CONFIGS[config.provider];

        // Setup axios instance based on provider
        this.axiosInstance = axios.create({
            baseURL: this.providerConfig.baseUrl,
            headers: this.getHeaders(),
        });
    }

    private getHeaders(): Record<string, string> {
        const baseHeaders = { 'Content-Type': 'application/json' };

        switch (this.config.provider) {
            case 'glm':
                return {
                    ...baseHeaders,
                    'Authorization': `Bearer ${this.config.apiKey}`,
                };
            case 'openai':
                return {
                    ...baseHeaders,
                    'Authorization': `Bearer ${this.config.apiKey}`,
                };
            case 'openrouter':
                return {
                    ...baseHeaders,
                    'Authorization': `Bearer ${this.config.apiKey}`,
                    'HTTP-Referer': 'https://habiter.app',
                    'X-Title': 'Habiter - Habit Tracker',
                };
            default:
                return baseHeaders;
        }
    }

    private async makeRequest(userPrompt: string, systemPrompt?: string): Promise<string> {
        try {
            const model = this.config.model || this.providerConfig.defaultModel;

            const response = await this.axiosInstance.post('/chat/completions', {
                model,
                messages: [
                    {
                        role: 'system',
                        content: systemPrompt || PROMPTS.system.base,
                    },
                    {
                        role: 'user',
                        content: userPrompt,
                    },
                ],
                temperature: 0.7,
                max_tokens: 300,
                // OpenRouter specific
                ...(this.config.provider === 'openrouter' && {
                    route: 'fallback',
                }),
            });

            return response.data.choices[0]?.message?.content || 'No response generated';
        } catch (error: any) {
            console.error('AI API Error:', error.response?.data || error.message);
            throw new Error(`Failed to get AI response: ${error.response?.data?.error?.message || error.message}`);
        }
    }

    async generateHabitRecommendation(habits: Habit[]): Promise<AIInsight> {
        const prompt = PROMPTS.recommendation(habits);

        try {
            const response = await this.makeRequest(prompt);
            return {
                id: Date.now().toString(),
                type: 'recommendation',
                title: '💡 New Habit Idea',
                message: response,
                confidence: 0.85,
                createdAt: new Date(),
                isRead: false,
            };
        } catch (error) {
            throw new Error('Failed to generate habit recommendation');
        }
    }

    async generateMotivationalMessage(habit: Habit, streak: number): Promise<AIInsight> {
        const now = new Date();
        const hour = now.getHours();
        const timeOfDay = hour < 12 ? 'morning' : hour < 18 ? 'afternoon' : 'evening';

        const prompt = PROMPTS.motivation(habit, streak, {
            category: habit.category,
            time: timeOfDay,
        });

        try {
            const response = await this.makeRequest(prompt);
            return {
                id: Date.now().toString(),
                habitId: habit.id,
                type: 'motivation',
                title: `🔥 ${streak} Day Streak!`,
                message: response,
                confidence: 0.9,
                createdAt: new Date(),
                isRead: false,
            };
        } catch (error) {
            throw new Error('Failed to generate motivational message');
        }
    }

    async analyzeHabitPattern(habit: Habit, entries: HabitEntry[]): Promise<AIInsight> {
        const totalDays = entries.length;
        const completions = entries.filter(e => e.completed).length;
        const completionRate = Math.round((completions / totalDays) * 100);

        const recent7 = entries.slice(-7);
        const recentCompletions = recent7.filter(e => e.completed).length;
        const recentRate = Math.round((recentCompletions / Math.min(7, recent7.length)) * 100);

        // Calculate best streak
        let currentStreak = 0;
        let bestStreak = 0;
        for (const entry of entries.sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime())) {
            if (entry.completed) {
                currentStreak++;
                bestStreak = Math.max(bestStreak, currentStreak);
            } else {
                currentStreak = 0;
            }
        }

        const prompt = PROMPTS.analysis(habit, {
            completionRate,
            recentRate,
            totalDays,
            bestStreak,
        });

        try {
            const response = await this.makeRequest(prompt);
            return {
                id: Date.now().toString(),
                habitId: habit.id,
                type: 'analysis',
                title: `📊 ${habit.name} Analysis`,
                message: response,
                confidence: 0.85,
                createdAt: new Date(),
                isRead: false,
            };
        } catch (error) {
            throw new Error('Failed to analyze habit pattern');
        }
    }

    async predictHabitSuccess(habit: Habit, entries: HabitEntry[]): Promise<AIInsight> {
        const totalDays = entries.length;
        const completions = entries.filter(e => e.completed).length;
        const completionRate = Math.round((completions / totalDays) * 100);

        // Calculate trend
        const recent7 = entries.slice(-7).filter(e => e.completed).length;
        const previous7 = entries.slice(-14, -7).filter(e => e.completed).length || 1;
        const trend = recent7 > previous7 ? 'improving' : recent7 < previous7 ? 'declining' : 'stable';

        // Calculate consistency (how evenly distributed are completions?)
        const consistency = Math.min(10, Math.round(completionRate / 10));

        const prompt = PROMPTS.prediction(habit, {
            completionRate,
            trend,
            consistency,
        });

        try {
            const response = await this.makeRequest(prompt);
            return {
                id: Date.now().toString(),
                habitId: habit.id,
                type: 'prediction',
                title: `🔮 ${habit.name} Outlook`,
                message: response,
                confidence: 0.75,
                createdAt: new Date(),
                isRead: false,
            };
        } catch (error) {
            throw new Error('Failed to predict habit success');
        }
    }

    async generatePersonalizedTips(habits: Habit[], entries: HabitEntry[]): Promise<AIInsight> {
        const habitSummary = habits.map(habit => {
            const habitEntries = entries.filter(e => e.habitId === habit.id);
            const rate = habitEntries.length > 0
                ? Math.round((habitEntries.filter(e => e.completed).length / habitEntries.length) * 100)
                : 0;
            return { name: habit.name, rate, category: habit.category };
        });

        const prompt = PROMPTS.personalizedTips(habitSummary);

        try {
            const response = await this.makeRequest(prompt);
            return {
                id: Date.now().toString(),
                type: 'recommendation',
                title: '✨ Personalized Tips',
                message: response,
                confidence: 0.9,
                createdAt: new Date(),
                isRead: false,
            };
        } catch (error) {
            throw new Error('Failed to generate personalized tips');
        }
    }
}

// Export available models for each provider
export const getAvailableModels = (provider: AIProvider): string[] => {
    return PROVIDER_CONFIGS[provider]?.models || [];
};

// Export default model for a provider
export const getDefaultModel = (provider: AIProvider): string => {
    return PROVIDER_CONFIGS[provider]?.defaultModel || '';
};

// Factory function to create AI service
export const createAIService = (config: AIConfig): UnifiedAIService => {
    return new UnifiedAIService(config);
};
