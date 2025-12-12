'use client';

import React from 'react';
import { motion } from 'framer-motion';
import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { Section } from '@/components/layout/Section';
import { Card } from '@/components/ui/Card';

export const PricingSection: React.FC = () => {
  const benefits = [
    '✅ All Features Included',
    '✅ Unlimited Habits',
    '✅ AI Insights & Analysis',
    '✅ Cross-Platform Sync',
    '✅ Analytics & Charts',
    '✅ Priority Support',
  ];

  return (
    <Section id="pricing" background="default">
      {/* Header */}
      <motion.div
        initial={{ opacity: 0, y: -20 }}
        whileInView={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6 }}
        viewport={{ once: true }}
        className="mb-xxxl text-center max-w-2xl mx-auto"
      >
        <motion.div className="inline-block mb-lg">
          <span className="px-md py-sm bg-success/10 text-success rounded-full text-label font-semibold">
            💰 SIMPLE PRICING
          </span>
        </motion.div>
        <h2 className="text-5xl md:text-6xl font-extrabold text-text mb-lg">
          Free <span className="text-success">Forever</span>
        </h2>
        <p className="text-xl text-text-secondary">
          No hidden fees, no subscriptions, no limits. Everything is completely free.
        </p>
      </motion.div>

      {/* Main Card */}
      <motion.div
        initial={{ opacity: 0, scale: 0.95 }}
        whileInView={{ opacity: 1, scale: 1 }}
        transition={{ duration: 0.6 }}
        viewport={{ once: true }}
        className="max-w-2xl mx-auto mb-xxxl"
      >
        <motion.div whileHover={{ y: -8 }} className="relative group">
          {/* Glow effect */}
          <div className="absolute inset-0 bg-gradient-to-r from-primary/20 to-secondary/20 rounded-2xl blur-xl opacity-0 group-hover:opacity-100 transition-opacity duration-300" />

          <Card className="relative border-2 border-primary/20 group-hover:border-primary/40 transition-colors">
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-xxxl items-center">
              {/* Left side - Price */}
              <motion.div
                initial={{ opacity: 0, x: -20 }}
                whileInView={{ opacity: 1, x: 0 }}
                transition={{ duration: 0.6, delay: 0.1 }}
                viewport={{ once: true }}
              >
                <Badge variant="success" className="mb-lg">
                  BEST VALUE
                </Badge>
                <h3 className="text-5xl font-bold text-text mb-sm">
                  $0<span className="text-base text-text-secondary font-normal">/month</span>
                </h3>
                <p className="text-lg text-text-secondary mb-xxl">
                  Everything included. Forever free. No trial, no catch.
                </p>

                <motion.div whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.95 }}>
                  <Button variant="primary" size="lg" className="w-full mb-md">
                    📱 Get Habiter Now
                  </Button>
                </motion.div>
                <Button variant="ghost" size="lg" className="w-full">
                  Learn More →
                </Button>
              </motion.div>

              {/* Right side - Benefits */}
              <motion.div
                initial={{ opacity: 0, x: 20 }}
                whileInView={{ opacity: 1, x: 0 }}
                transition={{ duration: 0.6, delay: 0.2 }}
                viewport={{ once: true }}
              >
                <h4 className="text-body font-bold text-text mb-lg">What's included:</h4>
                <ul className="space-y-md">
                  {benefits.map((benefit, i) => (
                    <motion.li
                      key={i}
                      initial={{ opacity: 0, x: -10 }}
                      whileInView={{ opacity: 1, x: 0 }}
                      transition={{ duration: 0.4, delay: 0.3 + i * 0.05 }}
                      viewport={{ once: true }}
                      className="text-body text-text-secondary flex items-center gap-md"
                    >
                      <span className="text-lg">{benefit.split('')[0]}</span>
                      <span>{benefit.slice(3)}</span>
                    </motion.li>
                  ))}
                </ul>
              </motion.div>
            </div>
          </Card>
        </motion.div>
      </motion.div>

      {/* Why Free */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        whileInView={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6, delay: 0.3 }}
        viewport={{ once: true }}
        className="max-w-2xl mx-auto text-center"
      >
        <h3 className="text-2xl font-bold text-text mb-md">Why is Habiter Free?</h3>
        <p className="text-lg text-text-secondary leading-relaxed">
          We believe building better habits should be accessible to everyone. No paywalls, no premium tiers, no ads interrupting your progress. Your success is our success.
        </p>
      </motion.div>
    </Section>
  );
};
