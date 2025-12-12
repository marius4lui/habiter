'use client';

import React from 'react';

export const Footer: React.FC = () => {
  const currentYear = new Date().getFullYear();

  return (
    <footer className="bg-background-dark border-t border-border-light py-xxxl">
      <div className="max-w-content mx-auto px-lg">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-xxl mb-xxxl">
          {/* About */}
          <div>
            <h4 className="text-body font-bold text-text mb-md">Habiter</h4>
            <p className="text-body-sm text-text-secondary leading-relaxed">
              Build better habits with AI-powered insights and beautiful analytics.
            </p>
          </div>

          {/* Links */}
          <div>
            <h4 className="text-body font-bold text-text mb-md">Product</h4>
            <ul className="space-y-sm">
              <li>
                <a href="#features" className="text-body-sm text-text-secondary hover:text-primary transition-colors">
                  Features
                </a>
              </li>
              <li>
                <a href="#preview" className="text-body-sm text-text-secondary hover:text-primary transition-colors">
                  Try It
                </a>
              </li>
              <li>
                <a href="#faq" className="text-body-sm text-text-secondary hover:text-primary transition-colors">
                  FAQ
                </a>
              </li>
            </ul>
          </div>

          {/* Legal */}
          <div>
            <h4 className="text-body font-bold text-text mb-md">Legal</h4>
            <ul className="space-y-sm">
              <li>
                <a href="#" className="text-body-sm text-text-secondary hover:text-primary transition-colors">
                  Privacy Policy
                </a>
              </li>
              <li>
                <a href="#" className="text-body-sm text-text-secondary hover:text-primary transition-colors">
                  Terms of Service
                </a>
              </li>
            </ul>
          </div>
        </div>

        {/* Bottom */}
        <div className="border-t border-border-light pt-lg text-center">
          <p className="text-body-sm text-text-secondary">
            © {currentYear} Habiter. All rights reserved.
          </p>
        </div>
      </div>
    </footer>
  );
};
