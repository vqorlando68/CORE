'use client';

import React from 'react';
import { 
  LayoutDashboard, 
  Building2, 
  AppWindow, 
  Users2, 
  BookOpenCheck, 
  Activity, 
  DatabaseZap,
  ShieldCheck
} from 'lucide-react';

export type ActiveTab = 'dashboard' | 'tenants' | 'apps' | 'users' | 'methods' | 'traces';

interface SidebarProps {
  activeTab: ActiveTab;
  onTabChange: (tab: ActiveTab) => void;
}

export const Sidebar: React.FC<SidebarProps> = ({ activeTab, onTabChange }) => {
  const navItems = [
    { id: 'dashboard', label: 'Panel de Control', icon: LayoutDashboard },
    { id: 'tenants', label: 'Gestión de Tenants', icon: Building2 },
    { id: 'apps', label: 'Aplicaciones & Módulos', icon: AppWindow },
    { id: 'users', label: 'Usuarios & Roles', icon: Users2 },
    { id: 'methods', label: 'Documentación Métodos', icon: BookOpenCheck },
    { id: 'traces', label: 'Visor de Trazas (APM)', icon: Activity },
  ];

  return (
    <aside className="app-sidebar">
      {/* Brand */}
      <div className="sidebar-brand">
        <div className="brand-icon">
          <DatabaseZap size={22} />
        </div>
        <div>
          <div className="brand-title">CORE Engine</div>
          <div className="brand-subtitle">Portal Administrativo</div>
        </div>
      </div>

      {/* Navigation */}
      <nav className="sidebar-nav">
        {navItems.map((item) => {
          const Icon = item.icon;
          const isActive = activeTab === item.id;
          return (
            <button
              key={item.id}
              onClick={() => onTabChange(item.id as ActiveTab)}
              className={`nav-item ${isActive ? 'active' : ''}`}
            >
              <Icon size={18} />
              <span>{item.label}</span>
            </button>
          );
        })}
      </nav>

      {/* Footer Info */}
      <div className="sidebar-footer">
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '11px', color: 'var(--text-muted)' }}>
          <ShieldCheck size={14} color="var(--color-primary)" />
          <span>Oracle DB 23ai / 26ai</span>
        </div>
        <div style={{ fontSize: '10.5px', color: 'var(--text-dim)', marginTop: '4px' }}>
          Arquitectura Multi-Inquilino
        </div>
      </div>
    </aside>
  );
};
