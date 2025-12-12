'use client';

import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { ChevronDown } from 'lucide-react';

interface AccordionItem {
  id: string;
  trigger: React.ReactNode;
  content: React.ReactNode;
}

interface AccordionProps {
  items: AccordionItem[];
  allowMultiple?: boolean;
}

export const Accordion: React.FC<AccordionProps> = ({ items, allowMultiple = false }) => {
  const [expanded, setExpanded] = useState<string | null>(null);

  const handleToggle = (id: string) => {
    if (allowMultiple) {
      setExpanded(expanded === id ? null : id);
    } else {
      setExpanded(expanded === id ? null : id);
    }
  };

  return (
    <div className="space-y-md w-full">
      {items.map((item) => (
        <AccordionItem
          key={item.id}
          id={item.id}
          trigger={item.trigger}
          content={item.content}
          isExpanded={expanded === item.id}
          onToggle={handleToggle}
        />
      ))}
    </div>
  );
};

interface AccordionItemProps {
  id: string;
  trigger: React.ReactNode;
  content: React.ReactNode;
  isExpanded: boolean;
  onToggle: (id: string) => void;
}

const AccordionItem: React.FC<AccordionItemProps> = ({ id, trigger, content, isExpanded, onToggle }) => {
  return (
    <div className="border border-border-light rounded-lg overflow-hidden">
      <button
        onClick={() => onToggle(id)}
        className="w-full px-lg py-md flex items-center justify-between bg-surface hover:bg-background transition-colors"
      >
        <span className="text-left text-body font-semibold text-text">{trigger}</span>
        <motion.div
          animate={{ rotate: isExpanded ? 180 : 0 }}
          transition={{ duration: 0.2 }}
          className="flex-shrink-0 ml-md"
        >
          <ChevronDown className="w-5 h-5 text-text-secondary" />
        </motion.div>
      </button>

      <motion.div
        initial={{ height: 0, opacity: 0 }}
        animate={{
          height: isExpanded ? 'auto' : 0,
          opacity: isExpanded ? 1 : 0,
        }}
        transition={{ duration: 0.3, ease: 'easeInOut' }}
        className="overflow-hidden"
      >
        <div className="px-lg py-md bg-background border-t border-border-light text-body text-text-secondary">
          {content}
        </div>
      </motion.div>
    </div>
  );
};

Accordion.displayName = 'Accordion';
