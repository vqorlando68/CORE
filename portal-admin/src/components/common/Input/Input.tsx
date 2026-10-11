'use client';

import React, { forwardRef } from 'react';

export interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
  helperText?: string;
  icon?: React.ReactNode;
}

export const Input = forwardRef<HTMLInputElement, InputProps>(
  ({ label, error, helperText, icon, className = '', id, ...props }, ref) => {
    const inputId = id || (label ? label.toLowerCase().replace(/\s+/g, '-') : undefined);

    return (
      <div className="form-group">
        {label && (
          <label htmlFor={inputId} className="form-label">
            {label}
          </label>
        )}
        <div className="input-wrapper">
          {icon && <span className="input-icon-left">{icon}</span>}
          <input
            ref={ref}
            id={inputId}
            className={`form-input ${icon ? 'has-icon' : ''} ${error ? 'is-invalid' : ''} ${className}`}
            {...props}
          />
        </div>
        {error ? (
          <span className="form-error">{error}</span>
        ) : (
          helperText && <span className="form-helper">{helperText}</span>
        )}
      </div>
    );
  }
);

Input.displayName = 'Input';
