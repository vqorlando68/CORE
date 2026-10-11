'use client';

import React, { useState } from 'react';
import { Aplicacion } from '@/lib/types';
import { AppWindow, Plus, Layers, CheckCircle2, AlertTriangle, X } from 'lucide-react';

interface AppManagerProps {
  apps: Aplicacion[];
  selectedTenantId: number;
  onRefresh: () => void;
}

export const AppManager: React.FC<AppManagerProps> = ({ apps, selectedTenantId, onRefresh }) => {
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [formData, setFormData] = useState({
    codigo: '',
    nombre: '',
    descripcion: '',
    version: '1.0.0',
    estado: 'ACTIVA'
  });
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    setErrorMsg('');

    try {
      const res = await fetch('/api/applications', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData)
      });
      const data = await res.json();

      if (data.success) {
        setShowCreateModal(false);
        setFormData({
          codigo: '',
          nombre: '',
          descripcion: '',
          version: '1.0.0',
          estado: 'ACTIVA'
        });
        onRefresh();
      } else {
        setErrorMsg(data.error || 'Error al registrar aplicación');
      }
    } catch (err: any) {
      setErrorMsg(err.message || 'Error de conexión');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div>
      <div className="view-header">
        <div className="view-title-group">
          <h1>Registro de Aplicaciones y Módulos</h1>
          <p>Catálogo centralizado de soluciones SaaS y módulos disponibles para activación por tenant.</p>
        </div>
        <button className="btn btn-primary" onClick={() => setShowCreateModal(true)}>
          <Plus size={16} />
          <span>Registrar Aplicación</span>
        </button>
      </div>

      <div className="grid-cards">
        {apps.map((app) => (
          <div key={app.id} className="card">
            <div className="card-header">
              <div>
                <span className="badge badge-primary" style={{ marginBottom: '8px' }}>
                  {app.codigo}
                </span>
                <h3 className="card-title">{app.nombre}</h3>
              </div>
              <span className={`badge ${app.estado === 'ACTIVA' ? 'badge-success' : 'badge-warning'}`}>
                {app.estado}
              </span>
            </div>

            <p className="card-desc">{app.descripcion}</p>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', fontSize: '13px', marginBottom: '16px' }}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <span style={{ color: 'var(--text-muted)' }}>Versión:</span>
                <span style={{ fontFamily: 'var(--font-mono)', fontWeight: 600 }}>v{app.version}</span>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <span style={{ color: 'var(--text-muted)' }}>Módulos activos:</span>
                <span className="badge badge-primary">{app.total_modulos || 3} módulos</span>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <span style={{ color: 'var(--text-muted)' }}>Habilitada en este Tenant:</span>
                <span className={`badge ${app.habilitada ? 'badge-success' : 'badge-warning'}`}>
                  {app.habilitada ? 'Suscrita' : 'No suscrita'}
                </span>
              </div>
            </div>

            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', paddingTop: '14px', borderTop: '1px solid var(--border-subtle)', fontSize: '11px', color: 'var(--text-dim)' }}>
              <span>ID App: #{app.id}</span>
              <span style={{ color: 'var(--color-primary)' }}>core_aplicacion</span>
            </div>
          </div>
        ))}
      </div>

      {/* Modal Registrar Aplicación */}
      {showCreateModal && (
        <div className="modal-overlay">
          <div className="modal-content">
            <div className="modal-header">
              <h2 style={{ fontSize: '18px', fontWeight: 700, color: 'var(--text-main)' }}>
                Registrar Nueva Solución / Aplicación SaaS
              </h2>
              <button 
                onClick={() => setShowCreateModal(false)}
                style={{ background: 'none', border: 'none', color: 'var(--text-muted)', cursor: 'pointer' }}
              >
                <X size={20} />
              </button>
            </div>

            <form onSubmit={handleSubmit}>
              <div className="modal-body">
                {errorMsg && (
                  <div style={{ padding: '10px 14px', background: 'var(--badge-bg-danger)', border: '1px solid var(--badge-border-danger)', color: 'var(--color-danger)', borderRadius: 'var(--radius-md)', marginBottom: '16px', fontSize: '13px' }}>
                    {errorMsg}
                  </div>
                )}

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                  <div className="form-group">
                    <label className="form-label">Código de Aplicación (Ej: CORE_HR)</label>
                    <input
                      type="text"
                      required
                      placeholder="CORE_HR"
                      value={formData.codigo}
                      onChange={(e) => setFormData({ ...formData, codigo: e.target.value })}
                      className="form-input"
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">Versión Inicial</label>
                    <input
                      type="text"
                      required
                      placeholder="1.0.0"
                      value={formData.version}
                      onChange={(e) => setFormData({ ...formData, version: e.target.value })}
                      className="form-input"
                    />
                  </div>
                </div>

                <div className="form-group">
                  <label className="form-label">Nombre de la Aplicación</label>
                  <input
                    type="text"
                    required
                    placeholder="Gestión de Talento Humano y Nómina"
                    value={formData.nombre}
                    onChange={(e) => setFormData({ ...formData, nombre: e.target.value })}
                    className="form-input"
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Descripción Funcional</label>
                  <textarea
                    rows={3}
                    placeholder="Módulo para contratación, gestión de colaboradores, turnos y nómina."
                    value={formData.descripcion}
                    onChange={(e) => setFormData({ ...formData, descripcion: e.target.value })}
                    className="form-input"
                    style={{ resize: 'vertical' }}
                  />
                </div>
              </div>

              <div className="modal-footer">
                <button 
                  type="button" 
                  onClick={() => setShowCreateModal(false)}
                  className="btn btn-secondary"
                  disabled={isSubmitting}
                >
                  Cancelar
                </button>
                <button 
                  type="submit" 
                  className="btn btn-primary"
                  disabled={isSubmitting}
                >
                  {isSubmitting ? 'Guardando...' : 'Registrar Aplicación'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
