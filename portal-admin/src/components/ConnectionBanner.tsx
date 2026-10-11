'use client';

import React from 'react';
import { DbHealthStatus } from '@/lib/types';
import { Database, ShieldCheck, Info, RefreshCw } from 'lucide-react';

interface ConnectionBannerProps {
  health: DbHealthStatus | null;
  onRefresh: () => void;
  isLoading: boolean;
}

export const ConnectionBanner: React.FC<ConnectionBannerProps> = ({ health, onRefresh, isLoading }) => {
  if (!health) return null;

  return (
    <div className={`connection-banner ${health.conectado ? 'online' : 'offline'}`}>
      <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
        <Database size={18} />
        <div>
          <div style={{ fontWeight: 700, display: 'flex', alignItems: 'center', gap: '8px' }}>
            <span>{health.conectado ? 'Conexión a Oracle Autonomous Database Activa' : 'Modo Autónomo Local / Semilla CORE'}</span>
            {health.wallet_detectado && (
              <span style={{ fontSize: '11px', background: 'rgba(255,255,255,0.1)', padding: '2px 8px', borderRadius: '4px' }}>
                Wallet_CORE.zip Detectado
              </span>
            )}
          </div>
          <div style={{ fontSize: '12px', opacity: 0.9, marginTop: '2px' }}>
            {health.mensaje}
          </div>
        </div>
      </div>

      <button
        onClick={onRefresh}
        disabled={isLoading}
        className="btn btn-secondary btn-sm"
        style={{ display: 'flex', alignItems: 'center', gap: '6px' }}
      >
        <RefreshCw size={12} className={isLoading ? 'spin' : ''} />
        <span>Verificar</span>
      </button>
    </div>
  );
};
