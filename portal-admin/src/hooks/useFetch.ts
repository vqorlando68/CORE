'use client';

import { useState, useEffect, useCallback } from 'react';
import { apiClient, ApiError } from '@/services/apiClient';

interface UseFetchState<T> {
  data: T | null;
  isLoading: boolean;
  error: ApiError | Error | null;
}

interface UseFetchReturn<T> extends UseFetchState<T> {
  refetch: () => Promise<void>;
  setData: React.Dispatch<React.SetStateAction<T | null>>;
}

/**
 * useFetch
 * Custom Hook modular para llamadas asíncronas con gestión automática de estados
 * (data, isLoading, error) y capacidad de recarga imperativa (refetch).
 */
export function useFetch<T>(url: string | null, autoFetch = true): UseFetchReturn<T> {
  const [state, setState] = useState<UseFetchState<T>>({
    data: null,
    isLoading: !!url && autoFetch,
    error: null,
  });

  const fetchData = useCallback(async () => {
    if (!url) return;

    setState((prev) => ({ ...prev, isLoading: true, error: null }));
    try {
      const result = await apiClient<T>(url);
      setState({ data: result, isLoading: false, error: null });
    } catch (err) {
      setState({
        data: null,
        isLoading: false,
        error: err instanceof Error ? err : new Error('Error al cargar datos'),
      });
    }
  }, [url]);

  useEffect(() => {
    if (autoFetch && url) {
      fetchData();
    }
  }, [url, autoFetch, fetchData]);

  const setData = useCallback((updater: React.SetStateAction<T | null>) => {
    setState((prev) => ({
      ...prev,
      data: typeof updater === 'function' ? (updater as (prevState: T | null) => T | null)(prev.data) : updater,
    }));
  }, []);

  return {
    ...state,
    refetch: fetchData,
    setData,
  };
}
