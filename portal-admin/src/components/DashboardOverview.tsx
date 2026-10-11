'use client';

import React from 'react';
import { ActiveTab } from './Sidebar';
import { 
  Building2, 
  AppWindow, 
  Users2, 
  BookOpenCheck, 
  Activity, 
  CheckCircle2, 
  Zap, 
  ShieldCheck, 
  ArrowUpRight 
} from 'lucide-react';
import { Tenant, Aplicacion, Usuario, DocumentacionMetodo, TrazaEjecucion } from '@/lib/types';

interface DashboardOverviewProps {
  tenants: Tenant[];
  apps: Aplicacion[];
  users: Usuario[];
  methods: DocumentacionMetodo[];
  traces: TrazaEjecucion[];
  onNavigate: (tab: ActiveTab) => void;
}

export const DashboardOverview: React.FC<DashboardOverviewProps> = ({
  tenants,
  apps,
  users,
  methods,
  traces,
  onNavigate,
}) => {
  const exitosas = traces.filter((t) => t.estado === 'EXITO').length;
  const tasaExito = traces.length > 0 ? ((exitosas / traces.length) * 100).toFixed(0) : '100';

  const stats = [
    { label: 'Tenants Activos', value: tenants.length, icon: Building2, tab: 'tenants' as ActiveTab, color: 'var(--color-primary)' },
    { label: 'Apps Registradas', value: apps.length, icon: AppWindow, tab: 'apps' as ActiveTab, color: 'var(--color-secondary)' },
    { label: 'Usuarios del Tenant', value: users.length, icon: Users2, tab: 'users' as ActiveTab, color: 'var(--color-cyan)' },
    { label: 'Métodos en Catálogo', value: methods.length, icon: BookOpenCheck, tab: 'methods' as ActiveTab, color: 'var(--color-purple)' },
    { label: 'Trazas Monitoreadas', value: traces.length, icon: Activity, tab: 'traces' as ActiveTab, color: 'var(--color-emerald)', extra: `${tasaExito}% éxito` },
  ];

  return (
    <div>
      <div className="view-header">
        <div className="view-title-group">
          <h1>Panel de Control — Plataforma Transversal CORE</h1>
          <p>Supervisión ejecutiva de tenants, seguridad multi-inquilino, observabilidad y catálogo de microservicios.</p>
        </div>
      </div>

      {/* Grid de Métricas Principales */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(210px, 1fr))', gap: '16px', marginBottom: '28px' }}>
        {stats.map((s, idx) => {
          const Icon = s.icon;
          return (
            <div
              key={idx}
              className="card"
              style={{ cursor: 'pointer', padding: '20px' }}
              onClick={() => onNavigate(s.tab)}
            >
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '12px' }}>
                <span style={{ fontSize: '12px', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
                  {s.label}
                </span>
                <span style={{ color: s.color }}>
                  <Icon size={20} />
                </span>
              </div>
              <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between' }}>
                <span style={{ fontSize: '32px', fontWeight: 800, color: 'var(--text-main)', letterSpacing: '-0.03em' }}>
                  {s.value}
                </span>
                {s.extra && (
                  <span className="badge badge-success" style={{ fontSize: '10px' }}>
                    {s.extra}
                  </span>
                )}
              </div>
            </div>
          );
        })}
      </div>

      {/* Acciones Rápidas y Tarjetas de Navegación */}
      <h2 style={{ fontSize: '17px', fontWeight: 700, marginBottom: '16px', color: 'var(--text-main)' }}>
        Módulos Administrativos Principales
      </h2>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))', gap: '20px' }}>
        <div className="card" onClick={() => onNavigate('tenants')} style={{ cursor: 'pointer' }}>
          <div className="card-header">
            <span className="badge badge-primary">Aislamiento</span>
            <ArrowUpRight size={16} color="var(--color-primary)" />
          </div>
          <h3 className="card-title">Gestión de Tenants y Subscripciones</h3>
          <p className="card-desc">
            Cree nuevos inquilinos empresariales, asigne planes y configure los contextos organizacionales aislados.
          </p>
          <div style={{ fontSize: '12px', color: 'var(--color-primary)', fontWeight: 600 }}>
            Administrar {tenants.length} Tenants →
          </div>
        </div>

        <div className="card" onClick={() => onNavigate('methods')} style={{ cursor: 'pointer' }}>
          <div className="card-header">
            <span className="badge badge-primary">Lenguaje Natural</span>
            <ArrowUpRight size={16} color="var(--color-primary)" />
          </div>
          <h3 className="card-title">Catálogo Gráfico de Orquestadores</h3>
          <p className="card-desc">
            Explore los servicios expuestos en pkgln_ con documentación funcional en lenguaje natural, validaciones y payloads listos para copiar.
          </p>
          <div style={{ fontSize: '12px', color: 'var(--color-primary)', fontWeight: 600 }}>
            Ver {methods.length} Métodos Documentados →
          </div>
        </div>

        <div className="card" onClick={() => onNavigate('traces')} style={{ cursor: 'pointer' }}>
          <div className="card-header">
            <span className="badge badge-primary">APM & Telemetría</span>
            <ArrowUpRight size={16} color="var(--color-primary)" />
          </div>
          <h3 className="card-title">Visor de Trazas y Profiling</h3>
          <p className="card-desc">
            Monitoree tiempos de respuesta, llamadas jerárquicas a DAOs, paquetes pkgcn_ e inspeccione payloads y errores de ejecución.
          </p>
          <div style={{ fontSize: '12px', color: 'var(--color-primary)', fontWeight: 600 }}>
            Inspeccionar Trazas Recientes →
          </div>
        </div>
      </div>
    </div>
  );
};
