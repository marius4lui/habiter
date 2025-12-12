'use client';

import React, { Suspense } from 'react';
import { motion } from 'framer-motion';

interface PhoneFrameProps {
  children: React.ReactNode;
  notch?: boolean;
}

// Loading skeleton
const PhoneFrameSkeleton = () => (
  <div className="relative mx-auto" style={{ aspectRatio: '9 / 19.5', maxWidth: '280px' }}>
    <div className="absolute inset-0 bg-black rounded-[40px] shadow-2xl border-8 border-black">
      <div className="absolute inset-0 bg-background rounded-[32px] overflow-hidden flex items-center justify-center">
        <div className="text-center">
          <div className="w-8 h-8 border-4 border-primary/30 border-t-primary rounded-full animate-spin mb-2" />
          <p className="text-sm text-text-secondary">Loading...</p>
        </div>
      </div>
    </div>
  </div>
);

export const PhoneFrame: React.FC<PhoneFrameProps> = ({ children, notch = true }) => {
  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.95 }}
      animate={{ opacity: 1, scale: 1 }}
      transition={{ duration: 0.5 }}
      className="flex items-center justify-center h-full w-full"
    >
      <Suspense fallback={<PhoneFrameSkeleton />}>
        <div className="relative mx-auto" style={{ aspectRatio: '9 / 19.5', maxWidth: '280px' }}>
          {/* Phone outer frame */}
          <div className="absolute inset-0 bg-black rounded-[40px] shadow-2xl border-8 border-black">
            {/* Inner screen */}
            <div className="absolute inset-0 bg-background rounded-[32px] overflow-hidden">
              {/* Notch */}
              {notch && (
                <div className="absolute top-0 left-1/2 -translate-x-1/2 w-32 h-6 bg-black rounded-b-3xl z-10 flex items-center justify-center gap-1 px-md">
                  {/* Signal */}
                  <div className="flex gap-0.5">
                    {[1, 2, 3].map((i) => (
                      <div key={i} className="w-0.5 h-1 bg-white rounded-sm" />
                    ))}
                  </div>
                  {/* Time */}
                  <div className="text-white text-xs font-semibold mx-auto">9:41</div>
                  {/* Battery */}
                  <div className="flex gap-0.5">
                    {[1, 2].map((i) => (
                      <div key={i} className="w-0.5 h-1 bg-white rounded-sm" />
                    ))}
                  </div>
                </div>
              )}

              {/* Safe area with content */}
              <div className="absolute inset-0 pt-8 flex flex-col">
                {/* Safe area content - scrollable area */}
                <div className="flex-1 overflow-y-auto scrollbar-hide">
                  {children}
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Glow effect */}
        <div className="absolute inset-0 bg-gradient-to-t from-primary/5 to-transparent pointer-events-none rounded-full blur-3xl" />
      </Suspense>
    </motion.div>
  );
};
