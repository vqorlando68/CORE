'use client';

import React from 'react';
import { Tenant } from '@/lib/types';
import { Palette, Globe, Server, CheckCircle2, AlertCircle } from 'lucide-react';

interface HeaderProps {
  tenants: Tenant[];
  selectedTenantId: number;
  onSelectTenant: (id: number) => void;
  isOnline: boolean;
  theme: string;
  onThemeChange: (theme: string) => void;
}

export const Header: React.FC<HeaderProps> = ({
  tenants,
  selectedTenantId,
  onSelectTenant,
  isOnline,
  theme,
  onThemeChange,
}) => {
  return (
    <header className="app-header">
      {/* Selector de Tenant */}
      <div className="header-tenant-selector">
        <Globe size={18} color="var(--color-primary)" />
        <span style={{ fontSize: '12px', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
          Tenant Activo:
        </span>
        <select
          value={selectedTenantId}
          onChange={(e) => onSelectTenant(Number(e.target.value))}
          className="tenant-select"
        >
          {tenants.map((t) => (
            <option key={t.id} value={t.id}>
              {t.codigo} — {t.nombre} ({t.id_plan})
            </option>
          ))}
        </select>
      </div>

      {/* Acciones y Estado */}
      <div className="header-actions">
        {/* Status Pill */}
        <div 
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '6px',
            padding: '6px 12px',
            borderRadius: 'var(--radius-full)',
            fontSize: '12px',
            fontWeight: 600,
            background: isOnline ? 'var(--badge-bg-success)' : 'var(--badge-bg-warning)',
            color: isOnline ? 'var(--color-success)' : 'var(--color-warning)',
            border: `1px solid ${isOnline ? 'var(--badge-border-success)' : 'var(--badge-border-warning)'}`
          }}
        >
          {isOnline ? <CheckCircle2 size={14} /> : <AlertCircle size={14} />}
          <span>{isOnline ? 'Oracle Cloud Online' : 'Modo Semilla Offline'}</span>
        </div>

        {/* Theme Selector */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <Palette size={16} color="var(--text-muted)" />
          <select
            value={theme}
            onChange={(e) => onThemeChange(e.target.value)}
            className="tenant-select"
            style={{ padding: '6px 10px', fontSize: '12px' }}
          >
            <option value="core">Tema Core Dark</option>
            <option value="light">Tema Claro</option>
            <option value="baby">Tema Baby</option>
            <option value="pirata">Tema Pirata Gold</option>
          </select>
        </div>
      </div>
    </header>
  );
};
