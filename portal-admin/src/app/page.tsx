'use client';

import React, { useState, useEffect } from 'react';
import { Sidebar, ActiveTab } from '@/components/Sidebar';
import { Header } from '@/components/Header';
import { ConnectionBanner } from '@/components/ConnectionBanner';
import { DashboardOverview } from '@/components/DashboardOverview';
import { TenantManager } from '@/components/TenantManager';
import { AppManager } from '@/components/AppManager';
import { UserManager } from '@/components/UserManager';
import { MethodDocViewer } from '@/components/MethodDocViewer';
import { TraceViewer } from '@/components/TraceViewer';
import { Tenant, Aplicacion, Usuario, Rol, DocumentacionMetodo, TrazaEjecucion, DbHealthStatus } from '@/lib/types';

export default function HomePage() {
  const [activeTab, setActiveTab] = useState<ActiveTab>('dashboard');
  const [selectedTenantId, setSelectedTenantId] = useState<number>(1);
  const [theme, setTheme] = useState<string>('core');

  // Estados de datos
  const [health, setHealth] = useState<DbHealthStatus | null>(null);
  const [tenants, setTenants] = useState<Tenant[]>([]);
  const [apps, setApps] = useState<Aplicacion[]>([]);
  const [users, setUsers] = useState<Usuario[]>([]);
  const [roles, setRoles] = useState<Rol[]>([]);
  const [methods, setMethods] = useState<DocumentacionMetodo[]>([]);
  const [traces, setTraces] = useState<TrazaEjecucion[]>([]);
  const [isLoadingHealth, setIsLoadingHealth] = useState<boolean>(false);

  // Inicializar Tema
  useEffect(() => {
    const savedTheme = localStorage.getItem('core_theme') || 'core';
    setTheme(savedTheme);
    document.documentElement.setAttribute('data-theme', savedTheme);
  }, []);

  const handleThemeChange = (newTheme: string) => {
    setTheme(newTheme);
    localStorage.setItem('core_theme', newTheme);
    document.documentElement.setAttribute('data-theme', newTheme);
  };

  // Carga de Health Check
  const loadHealth = async () => {
    setIsLoadingHealth(true);
    try {
      const res = await fetch('/api/health');
      const data = await res.json();
      setHealth(data);
    } catch {
      setHealth({
        conectado: false,
        modo: 'SIMULADOR_OFFLINE',
        mensaje: 'Operando en Modo Autónomo Local (Semilla activa).',
        wallet_detectado: true
      });
    } finally {
      setIsLoadingHealth(false);
    }
  };

  // Carga de Datos Principales
  const loadData = async () => {
    try {
      // Tenants
      const resTenants = await fetch('/api/tenants');
      const dTenants = await resTenants.json();
      if (dTenants.success) setTenants(dTenants.data);

      // Apps
      const resApps = await fetch(`/api/applications?tenantId=${selectedTenantId}`);
      const dApps = await resApps.json();
      if (dApps.success) setApps(dApps.data);

      // Users
      const resUsers = await fetch(`/api/users?tenantId=${selectedTenantId}`);
      const dUsers = await resUsers.json();
      if (dUsers.success) setUsers(dUsers.data);

      // Roles
      const resRoles = await fetch(`/api/roles?tenantId=${selectedTenantId}`);
      const dRoles = await resRoles.json();
      if (dRoles.success) setRoles(dRoles.data);

      // Methods
      const resMethods = await fetch(`/api/documentation?tenantId=${selectedTenantId}`);
      const dMethods = await resMethods.json();
      if (dMethods.success) setMethods(dMethods.data);

      // Traces
      const resTraces = await fetch(`/api/traces?tenantId=${selectedTenantId}`);
      const dTraces = await resTraces.json();
      if (dTraces.success) setTraces(dTraces.data);
    } catch (err) {
      console.warn('Error al cargar datos del portal:', err);
    }
  };

  useEffect(() => {
    loadHealth();
  }, []);

  useEffect(() => {
    loadData();
  }, [selectedTenantId]);

  return (
    <div className="app-layout">
      {/* Barra Lateral */}
      <Sidebar activeTab={activeTab} onTabChange={setActiveTab} />

      {/* Contenido Principal */}
      <div className="app-content">
        <Header
          tenants={tenants}
          selectedTenantId={selectedTenantId}
          onSelectTenant={setSelectedTenantId}
          isOnline={health?.conectado || false}
          theme={theme}
          onThemeChange={handleThemeChange}
        />

        <main className="view-container">
          {/* Banner de Conexión a Oracle */}
          <ConnectionBanner
            health={health}
            onRefresh={loadHealth}
            isLoading={isLoadingHealth}
          />

          {/* Vistas Dinámicas */}
          {activeTab === 'dashboard' && (
            <DashboardOverview
              tenants={tenants}
              apps={apps}
              users={users}
              methods={methods}
              traces={traces}
              onNavigate={setActiveTab}
            />
          )}

          {activeTab === 'tenants' && (
            <TenantManager
              tenants={tenants}
              onRefresh={loadData}
            />
          )}

          {activeTab === 'apps' && (
            <AppManager
              apps={apps}
              selectedTenantId={selectedTenantId}
              onRefresh={loadData}
            />
          )}

          {activeTab === 'users' && (
            <UserManager
              users={users}
              roles={roles}
              selectedTenantId={selectedTenantId}
              onRefresh={loadData}
            />
          )}

          {activeTab === 'methods' && (
            <MethodDocViewer
              methods={methods}
              selectedTenantId={selectedTenantId}
            />
          )}

          {activeTab === 'traces' && (
            <TraceViewer
              traces={traces}
              selectedTenantId={selectedTenantId}
            />
          )}
        </main>
      </div>
    </div>
  );
}
