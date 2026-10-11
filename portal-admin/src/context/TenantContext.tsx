'use client';

import React, { createContext, useContext, useState, useEffect } from 'react';

interface TenantContextType {
  activeTenantId: number;
  setActiveTenantId: (id: number) => void;
}

const TenantContext = createContext<TenantContextType | undefined>(undefined);

export const TenantProvider: React.FC<{ children: React.ReactNode; initialTenantId?: number }> = ({
  children,
  initialTenantId = 1,
}) => {
  const [activeTenantId, setActiveTenantIdState] = useState<number>(initialTenantId);

  useEffect(() => {
    const saved = localStorage.getItem('core_active_tenant_id');
    if (saved) {
      const parsed = parseInt(saved, 10);
      if (!isNaN(parsed)) {
        setActiveTenantIdState(parsed);
      }
    }
  }, []);

  const setActiveTenantId = (id: number) => {
    setActiveTenantIdState(id);
    localStorage.setItem('core_active_tenant_id', id.toString());
  };

  return (
    <TenantContext.Provider value={{ activeTenantId, setActiveTenantId }}>
      {children}
    </TenantContext.Provider>
  );
};

export const useTenant = (): TenantContextType => {
  const context = useContext(TenantContext);
  if (!context) {
    throw new Error('useTenant debe ser utilizado dentro de un TenantProvider');
  }
  return context;
};
