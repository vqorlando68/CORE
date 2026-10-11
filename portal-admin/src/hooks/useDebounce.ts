'use client';

import { useState, useEffect } from 'react';

/**
 * useDebounce
 * Retrasa la actualización del valor para optimizar búsquedas y reducir renders o llamadas de API.
 */
export function useDebounce<T>(value: T, delayMs: number = 300): T {
  const [debouncedValue, setDebouncedValue] = useState<T>(value);

  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedValue(value);
    }, delayMs);

    return () => {
      clearTimeout(handler);
    };
  }, [value, delayMs]);

  return debouncedValue;
}
