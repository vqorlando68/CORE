'use client';

import React from 'react';

export interface BadgeProps {
  children: React.ReactNode;
  variant?: 'success' | 'warning' | 'danger' | 'info' | 'neutral';
  size?: 'sm' | 'md';
  className?: string;
}

export const Badge: React.FC<BadgeProps> = ({
  children,
  variant = 'neutral',
  size = 'md',
  className = '',
}) => {
  const variantClass = {
    success: 'badge-success',
    warning: 'badge-warning',
    danger: 'badge-danger',
    info: 'badge-info',
    neutral: 'badge-neutral',
  }[variant];

  const sizeClass = size === 'sm' ? 'badge-sm' : 'badge-md';

  return (
    <span className={`badge ${variantClass} ${sizeClass} ${className}`}>
      {children}
    </span>
  );
};
