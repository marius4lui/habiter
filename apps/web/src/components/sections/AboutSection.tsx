'use client';

import React from 'react';
import { motion } from 'framer-motion';
import { Section } from '@/components/layout/Section';

export const AboutSection: React.FC = () => {
  return (
    <Section id="about" background="light">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        whileInView={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6 }}
        viewport={{ once: true }}
        className="max-w-2xl mx-auto"
      >
        <h2 className="text-h2 font-bold text-text mb-lg text-center">About Habiter</h2>

        <div className="space-y-md text-body text-text-secondary leading-relaxed">
          <p>
            Habiter is a modern habit tracking application designed to help you build and maintain positive daily routines. We believe that small, consistent actions lead to big, lasting changes. Our app combines cutting-edge technology with a beautiful, minimalist interface to make habit tracking effortless and enjoyable.
          </p>

          <p>
            Powered by advanced AI, Habiter provides personalized insights and recommendations to help you understand your progress and stay motivated. Whether you want to build healthier habits, improve your productivity, or develop new skills, Habiter is your perfect companion.
          </p>

          <p>
            Built with React Native and Expo, Habiter works seamlessly across iOS, Android, and Web platforms. Your data stays on your device, completely private and secure. We're committed to providing a privacy-first experience without ads or paywalls.
          </p>
        </div>

        <div className="grid grid-cols-3 gap-md mt-xxxl text-center">
          <motion.div
            whileInView={{ scale: 1.05 }}
            transition={{ duration: 0.3 }}
            viewport={{ once: true }}
          >
            <div className="text-h2 font-bold text-primary">100K+</div>
            <div className="text-body-sm text-text-secondary">Habits Tracked</div>
          </motion.div>
          <motion.div
            whileInView={{ scale: 1.05 }}
            transition={{ duration: 0.3, delay: 0.1 }}
            viewport={{ once: true }}
          >
            <div className="text-h2 font-bold text-primary">50K+</div>
            <div className="text-body-sm text-text-secondary">Active Users</div>
          </motion.div>
          <motion.div
            whileInView={{ scale: 1.05 }}
            transition={{ duration: 0.3, delay: 0.2 }}
            viewport={{ once: true }}
          >
            <div className="text-h2 font-bold text-primary">1M+</div>
            <div className="text-body-sm text-text-secondary">Days Completed</div>
          </motion.div>
        </div>
      </motion.div>
    </Section>
  );
};
