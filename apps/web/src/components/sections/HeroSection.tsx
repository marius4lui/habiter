'use client';

import React, { Suspense } from 'react';
import Image from 'next/image';
import { motion } from 'framer-motion';
import { Button } from '@/components/ui/Button';
import { PhoneFrame } from '@/components/preview/PhoneFrame';
import { PreviewApp } from '@/components/preview/PreviewApp';
import { Section } from '@/components/layout/Section';

interface HeroSectionProps {
  scrollY: number;
}

export const HeroSection: React.FC<HeroSectionProps> = ({ scrollY }) => {
  const containerVariants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.2,
        delayChildren: 0.1,
      },
    },
  };

  const itemVariants = {
    hidden: { opacity: 0, y: 40 },
    visible: {
      opacity: 1,
      y: 0,
      transition: { duration: 0.8, ease: 'easeOut' },
    },
  };

  return (
    <Section id="hero" background="default" className="relative py-xxxl overflow-hidden">
      {/* Decorative elements */}
      <motion.div
        style={{ y: scrollY * 0.5 }}
        className="absolute -top-32 right-0 w-64 h-64 bg-gradient-to-br from-primary/5 to-secondary/5 rounded-full blur-3xl"
      />

      <motion.div
        variants={containerVariants}
        initial="hidden"
        animate="visible"
        className="grid grid-cols-1 lg:grid-cols-2 gap-xxxl items-center relative z-10"
      >
        {/* Left Content */}
        <div className="space-y-lg">
          {/* App Icon */}
          <motion.div variants={itemVariants}>
            <div className="flex items-center gap-md">
              <motion.div
                whileHover={{ scale: 1.1, rotate: 5 }}
                whileTap={{ scale: 0.95 }}
                className="w-16 h-16 rounded-3xl overflow-hidden shadow-lg border-2 border-primary/20"
              >
                <Image
                  src="/app-icon.png"
                  alt="Habiter"
                  width={64}
                  height={64}
                  priority
                  className="w-full h-full"
                />
              </motion.div>
              <div>
                <p className="text-label text-text-secondary">HABIT TRACKING</p>
                <h2 className="text-h3 font-bold text-text">Habiter</h2>
              </div>
            </div>
          </motion.div>

          {/* Main Headline */}
          <motion.div variants={itemVariants}>
            <h1 className="text-5xl md:text-6xl font-extrabold leading-tight">
              <span className="bg-gradient-to-r from-primary via-secondary to-accent3 bg-clip-text text-transparent">
                Transform Your Life,
              </span>
              <br />
              <span className="text-text">One Habit at a Time</span>
            </h1>
          </motion.div>

          {/* Subtitle */}
          <motion.p variants={itemVariants} className="text-xl text-text-secondary leading-relaxed max-w-lg">
            Build unstoppable momentum with AI-powered insights, beautiful analytics, and streaks that keep you motivated. Your habits, your rules, forever free.
          </motion.p>

          {/* Stats */}
          <motion.div variants={itemVariants} className="grid grid-cols-3 gap-md py-lg border-y border-border-light">
            {[
              { number: '100K+', label: 'Habits Tracked' },
              { number: '50K+', label: 'Active Users' },
              { number: '1M+', label: 'Days Completed' },
            ].map((stat, i) => (
              <div key={i}>
                <motion.div className="text-h3 font-bold text-primary">{stat.number}</motion.div>
                <p className="text-body-sm text-text-secondary">{stat.label}</p>
              </div>
            ))}
          </motion.div>

          {/* CTA Buttons */}
          <motion.div variants={itemVariants} className="flex flex-col sm:flex-row gap-md pt-lg">
            <motion.div whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.95 }}>
              <Button
                variant="primary"
                size="lg"
                className="w-full sm:w-auto text-lg px-8"
              >
                📱 Download Now
              </Button>
            </motion.div>
            <motion.div whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.95 }}>
              <Button
                variant="secondary"
                size="lg"
                className="w-full sm:w-auto text-lg px-8"
              >
                ▶️ Watch Demo
              </Button>
            </motion.div>
          </motion.div>

          {/* Trust badges */}
          <motion.div variants={itemVariants} className="flex items-center gap-md text-body-sm text-text-tertiary pt-md">
            <div className="flex -space-x-2">
              {['👨', '👩', '👨‍💼'].map((emoji, i) => (
                <span key={i} className="text-xl">
                  {emoji}
                </span>
              ))}
            </div>
            <span>Loved by 50,000+ users worldwide</span>
          </motion.div>
        </div>

        {/* Right Content - Phone Preview */}
        <motion.div
          initial={{ opacity: 0, scale: 0.9, x: 40 }}
          animate={{ opacity: 1, scale: 1, x: 0 }}
          transition={{ duration: 1, delay: 0.4 }}
          className="hidden lg:flex justify-center items-center h-[600px] relative"
        >
          {/* Glow effect behind phone */}
          <motion.div
            animate={{
              scale: [1, 1.1, 1],
              opacity: [0.2, 0.4, 0.2],
            }}
            transition={{ duration: 4, repeat: Infinity }}
            className="absolute inset-0 bg-gradient-to-tr from-primary/30 to-secondary/30 rounded-full blur-3xl -z-10"
          />

          <Suspense fallback={<div className="text-center">Loading preview...</div>}>
            <PhoneFrame>
              <PreviewApp />
            </PhoneFrame>
          </Suspense>
        </motion.div>
      </motion.div>

      {/* Mobile Preview - Below on small screens */}
      <motion.div
        initial={{ opacity: 0, y: 40 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.8, delay: 0.6 }}
        className="lg:hidden flex justify-center mt-xxxl h-[500px]"
      >
        <Suspense fallback={<div className="text-center">Loading preview...</div>}>
          <PhoneFrame>
            <PreviewApp />
          </PhoneFrame>
        </Suspense>
      </motion.div>

      {/* Scroll indicator */}
      <motion.div
        animate={{ y: [0, 12, 0] }}
        transition={{ duration: 2, repeat: Infinity }}
        className="absolute bottom-8 left-1/2 -translate-x-1/2 flex flex-col items-center gap-2 text-primary hidden md:flex"
      >
        <span className="text-body-sm font-medium">Scroll to explore</span>
        <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 14l-7 7m0 0l-7-7m7 7V3" />
        </svg>
      </motion.div>
    </Section>
  );
};
