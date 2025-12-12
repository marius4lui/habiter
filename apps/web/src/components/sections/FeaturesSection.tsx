'use client';

import React from 'react';
import { motion } from 'framer-motion';
import { Card } from '@/components/ui/Card';
import { Section } from '@/components/layout/Section';

interface Feature {
  icon: string;
  title: string;
  description: string;
  accent: string;
}

const features: Feature[] = [
  {
    icon: '🧠',
    title: 'AI-Powered Insights',
    description: 'Get personalized recommendations and analysis powered by advanced AI that learns your patterns',
    accent: 'from-primary',
  },
  {
    icon: '🔥',
    title: 'Streak Tracking',
    description: 'Build momentum with visual streak counters that keep you motivated day after day',
    accent: 'from-warning',
  },
  {
    icon: '📊',
    title: 'Beautiful Analytics',
    description: 'Visualize your progress with stunning charts, stats, and progress reports',
    accent: 'from-info',
  },
  {
    icon: '📁',
    title: 'Smart Categories',
    description: 'Organize your habits by Health, Learning, Productivity, and more',
    accent: 'from-accent1',
  },
  {
    icon: '📱',
    title: 'Cross-Platform Sync',
    description: 'iOS, Android, and Web - your habits follow you everywhere',
    accent: 'from-secondary',
  },
  {
    icon: '🔒',
    title: 'Privacy First',
    description: 'Your data stays on your device. We never access or share your information',
    accent: 'from-accent3',
  },
];

export const FeaturesSection: React.FC = () => {
  const containerVariants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.1,
      },
    },
  };

  const itemVariants = {
    hidden: { opacity: 0, y: 30 },
    visible: {
      opacity: 1,
      y: 0,
      transition: { duration: 0.6 },
    },
  };

  return (
    <Section id="features" background="light">
      {/* Header */}
      <motion.div
        initial={{ opacity: 0, y: -20 }}
        whileInView={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6 }}
        viewport={{ once: true }}
        className="mb-xxxl text-center max-w-2xl mx-auto"
      >
        <motion.div className="inline-block mb-lg">
          <span className="px-md py-sm bg-primary/10 text-primary rounded-full text-label font-semibold">
            ✨ POWERFUL FEATURES
          </span>
        </motion.div>
        <h2 className="text-5xl md:text-6xl font-extrabold text-text mb-lg leading-tight">
          Everything You Need to <br />
          <span className="bg-gradient-to-r from-primary to-secondary bg-clip-text text-transparent">
            Master Your Habits
          </span>
        </h2>
        <p className="text-xl text-text-secondary leading-relaxed">
          Packed with features that make habit tracking effortless, intuitive, and actually fun
        </p>
      </motion.div>

      {/* Features Grid */}
      <motion.div
        variants={containerVariants}
        initial="hidden"
        whileInView="visible"
        viewport={{ once: true, amount: 0.2 }}
        className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-lg"
      >
        {features.map((feature) => (
          <motion.div key={feature.title} variants={itemVariants}>
            <motion.div
              whileHover={{ y: -8, shadow: 'lg' }}
              className="relative h-full group"
            >
              {/* Gradient accent */}
              <motion.div
                className={`absolute inset-0 bg-gradient-to-br ${feature.accent} to-transparent opacity-0 group-hover:opacity-10 rounded-lg transition-opacity duration-300`}
              />

              <Card hover className="relative h-full flex flex-col">
                {/* Icon Background */}
                <motion.div
                  whileHover={{ scale: 1.1, rotate: 5 }}
                  className={`w-16 h-16 rounded-xl bg-gradient-to-br ${feature.accent} to-transparent/30 flex items-center justify-center mb-lg`}
                >
                  <span className="text-4xl">{feature.icon}</span>
                </motion.div>

                {/* Content */}
                <h3 className="text-xl font-bold text-text mb-md">{feature.title}</h3>
                <p className="text-body text-text-secondary flex-1 leading-relaxed">
                  {feature.description}
                </p>

                {/* Arrow Icon */}
                <motion.div
                  className="mt-md text-primary opacity-0 group-hover:opacity-100 transition-opacity"
                  initial={{ x: 0, opacity: 0 }}
                  whileHover={{ x: 4 }}
                >
                  <span className="text-xl">→</span>
                </motion.div>
              </Card>
            </motion.div>
          </motion.div>
        ))}
      </motion.div>

      {/* Bottom CTA */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        whileInView={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6, delay: 0.3 }}
        viewport={{ once: true }}
        className="mt-xxxl text-center"
      >
        <p className="text-lg text-text-secondary mb-lg">
          And much more... including habit statistics, completion tracking, and AI recommendations
        </p>
      </motion.div>
    </Section>
  );
};
