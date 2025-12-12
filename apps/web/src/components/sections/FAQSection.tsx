'use client';

import React from 'react';
import { motion } from 'framer-motion';
import { Accordion } from '@/components/ui/Accordion';
import { Section } from '@/components/layout/Section';

export const FAQSection: React.FC = () => {
  const faqItems = [
    {
      id: 'faq-1',
      trigger: 'How does the AI work?',
      content:
        'Habiter uses advanced machine learning to analyze your habit patterns and provide personalized insights. The AI learns from your daily completions, streaks, and patterns to suggest improvements and predict your success rate.',
    },
    {
      id: 'faq-2',
      trigger: 'Is my data private?',
      content:
        'Absolutely. All your data is stored locally on your device. We never access, store, or share your personal information. Your habits and progress are 100% private.',
    },
    {
      id: 'faq-3',
      trigger: 'Is it really free?',
      content:
        'Yes! Habiter is completely free forever. No subscriptions, no ads, no hidden costs. All features are available for free on iOS, Android, and Web.',
    },
    {
      id: 'faq-4',
      trigger: 'What platforms are supported?',
      content:
        'Habiter is available on iOS (iPhone), Android, and Web. All versions are fully synchronized so you can access your habits from any device.',
    },
    {
      id: 'faq-5',
      trigger: 'Can I sync across devices?',
      content:
        'Currently, Habiter stores data locally on each device. Future versions will include cloud sync while maintaining your privacy with end-to-end encryption.',
    },
    {
      id: 'faq-6',
      trigger: 'How do I get started?',
      content:
        'Simply download Habiter from the App Store or Google Play, create your first habit, and start tracking. You can add as many habits as you want and customize them to your needs.',
    },
  ];

  return (
    <Section id="faq" background="light">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        whileInView={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6 }}
        viewport={{ once: true }}
        className="max-w-2xl mx-auto"
      >
        <h2 className="text-h2 font-bold text-text mb-lg text-center">Frequently Asked Questions</h2>

        <Accordion items={faqItems} />
      </motion.div>
    </Section>
  );
};
