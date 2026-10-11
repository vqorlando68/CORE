'use client';

import React, { useState } from 'react';
import { Tenant } from '@/lib/types';
import { Building2, Plus, Mail, Phone, MapPin, CheckCircle, XCircle, FileText, X } from 'lucide-react';

interface TenantManagerProps {
  tenants: Tenant[];
  onRefresh: () => void;
}

export const TenantManager: React.FC<TenantManagerProps> = ({ tenants, onRefresh }) => {
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [formData, setFormData] = useState({
    codigo: '',
    nombre: '',
    id_plan: 'BUSINESS' as 'STARTER' | 'BUSINESS' | 'ENTERPRISE',
    nit_empresa: '',
    contacto_correo: '',
    contacto_telefono: '',
    pais: 'CO'
  });
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    setErrorMsg('');

    try {
      const res = await fetch('/api/tenants', {
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
          id_plan: 'BUSINESS',
          nit_empresa: '',
          contacto_correo: '',
          contacto_telefono: '',
          pais: 'CO'
        });
        onRefresh();
      } else {
        setErrorMsg(data.error || 'Error al crear tenant');
      }
    } catch (err: any) {
      setErrorMsg(err.message || 'Error de conexión');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div>
      {/* Encabezado */}
      <div className="view-header">
        <div className="view-title-group">
          <h1>Gestión de Tenants (Inquilinos Multi-Tenant)</h1>
          <p>Crea, administra y supervisa los espacios de trabajo empresariales y planes de suscripción.</p>
        </div>
        <button className="btn btn-primary" onClick={() => setShowCreateModal(true)}>
          <Plus size={16} />
          <span>Nuevo Tenant</span>
        </button>
      </div>

      {/* Grid de Tarjetas de Tenants */}
      <div className="grid-cards">
        {tenants.map((tenant) => (
          <div key={tenant.id} className="card">
            <div className="card-header">
              <div>
                <span className="badge badge-primary" style={{ marginBottom: '8px' }}>
                  {tenant.codigo}
                </span>
                <h3 className="card-title">{tenant.nombre}</h3>
              </div>
              <span className={`badge ${tenant.estado === 1 ? 'badge-success' : 'badge-danger'}`}>
                {tenant.estado === 1 ? 'Activo' : 'Inactivo'}
              </span>
            </div>

            <div className="card-desc">
              <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', fontSize: '13px' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <FileText size={14} color="var(--text-muted)" />
                  <span><strong>Plan:</strong> {tenant.id_plan}</span>
                </div>
                {tenant.nit_empresa && (
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <Building2 size={14} color="var(--text-muted)" />
                    <span><strong>NIT:</strong> {tenant.nit_empresa}</span>
                  </div>
                )}
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <Mail size={14} color="var(--text-muted)" />
                  <span>{tenant.contacto_correo}</span>
                </div>
                {tenant.contacto_telefono && (
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <Phone size={14} color="var(--text-muted)" />
                    <span>{tenant.contacto_telefono}</span>
                  </div>
                )}
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <MapPin size={14} color="var(--text-muted)" />
                  <span>País: {tenant.pais}</span>
                </div>
              </div>
            </div>

            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', paddingTop: '14px', borderTop: '1px solid var(--border-subtle)', fontSize: '11px', color: 'var(--text-dim)' }}>
              <span>ID: #{tenant.id}</span>
              <span>{tenant.fecha_creacion ? `Registrado: ${tenant.fecha_creacion.split(' ')[0]}` : 'Sistema CORE'}</span>
            </div>
          </div>
        ))}
      </div>

      {/* Modal Crear Tenant */}
      {showCreateModal && (
        <div className="modal-overlay">
          <div className="modal-content">
            <div className="modal-header">
              <h2 style={{ fontSize: '18px', fontWeight: 700, color: 'var(--text-main)' }}>
                Registrar Nuevo Tenant Empresarial
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
                    <label className="form-label">Código Único (Ej: ACME)</label>
                    <input
                      type="text"
                      required
                      placeholder="ACME"
                      value={formData.codigo}
                      onChange={(e) => setFormData({ ...formData, codigo: e.target.value })}
                      className="form-input"
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">Plan de Suscripción</label>
                    <select
                      value={formData.id_plan}
                      onChange={(e) => setFormData({ ...formData, id_plan: e.target.value as any })}
                      className="form-input"
                    >
                      <option value="STARTER">STARTER</option>
                      <option value="BUSINESS">BUSINESS</option>
                      <option value="ENTERPRISE">ENTERPRISE</option>
                    </select>
                  </div>
                </div>

                <div className="form-group">
                  <label className="form-label">Nombre Comercial o Razón Social</label>
                  <input
                    type="text"
                    required
                    placeholder="Acme Global Solutions S.A.S."
                    value={formData.nombre}
                    onChange={(e) => setFormData({ ...formData, nombre: e.target.value })}
                    className="form-input"
                  />
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                  <div className="form-group">
                    <label className="form-label">NIT / Identificación Fiscal</label>
                    <input
                      type="text"
                      placeholder="900123456-1"
                      value={formData.nit_empresa}
                      onChange={(e) => setFormData({ ...formData, nit_empresa: e.target.value })}
                      className="form-input"
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">País (ISO-2)</label>
                    <input
                      type="text"
                      placeholder="CO"
                      maxLength={2}
                      value={formData.pais}
                      onChange={(e) => setFormData({ ...formData, pais: e.target.value.toUpperCase() })}
                      className="form-input"
                    />
                  </div>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                  <div className="form-group">
                    <label className="form-label">Correo Electrónico de Contacto</label>
                    <input
                      type="email"
                      required
                      placeholder="admin@tenant.com"
                      value={formData.contacto_correo}
                      onChange={(e) => setFormData({ ...formData, contacto_correo: e.target.value })}
                      className="form-input"
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">Teléfono de Contacto</label>
                    <input
                      type="text"
                      placeholder="+57 3001234567"
                      value={formData.contacto_telefono}
                      onChange={(e) => setFormData({ ...formData, contacto_telefono: e.target.value })}
                      className="form-input"
                    />
                  </div>
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
                  {isSubmitting ? 'Guardando...' : 'Crear Tenant'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
