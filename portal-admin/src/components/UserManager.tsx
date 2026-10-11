'use client';

import React, { useState } from 'react';
import { Usuario, Rol } from '@/lib/types';
import { Users2, Shield, Plus, UserPlus, Lock, Unlock, Mail, CheckCircle2, X } from 'lucide-react';

interface UserManagerProps {
  users: Usuario[];
  roles: Rol[];
  selectedTenantId: number;
  onRefresh: () => void;
}

export const UserManager: React.FC<UserManagerProps> = ({ users, roles, selectedTenantId, onRefresh }) => {
  const [activeSubTab, setActiveSubTab] = useState<'users' | 'roles'>('users');
  const [showCreateUserModal, setShowCreateUserModal] = useState(false);
  const [showCreateRoleModal, setShowCreateRoleModal] = useState(false);

  // Form Usuario
  const [userForm, setUserForm] = useState({
    nombre_usuario: '',
    correo_electronico: '',
    primer_nombre: '',
    primer_apellido: '',
    tipo_documento: 'CC',
    numero_documento: '',
    codigo_rol: 'ROL_OPERADOR'
  });

  // Form Rol
  const [roleForm, setRoleForm] = useState({
    codigo: '',
    nombre: '',
    descripcion: '',
    alcance: 'G' as 'G' | 'S' | 'O'
  });

  const [isSubmitting, setIsSubmitting] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');

  const handleCreateUser = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    setErrorMsg('');

    try {
      const res = await fetch('/api/users', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ ...userForm, id_tenant: selectedTenantId })
      });
      const data = await res.json();

      if (data.success) {
        setShowCreateUserModal(false);
        setUserForm({
          nombre_usuario: '',
          correo_electronico: '',
          primer_nombre: '',
          primer_apellido: '',
          tipo_documento: 'CC',
          numero_documento: '',
          codigo_rol: 'ROL_OPERADOR'
        });
        onRefresh();
      } else {
        setErrorMsg(data.error || 'Error al crear usuario');
      }
    } catch (err: any) {
      setErrorMsg(err.message || 'Error de conexión');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleCreateRole = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    setErrorMsg('');

    try {
      const res = await fetch('/api/roles', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ ...roleForm, id_tenant: selectedTenantId })
      });
      const data = await res.json();

      if (data.success) {
        setShowCreateRoleModal(false);
        setRoleForm({
          codigo: '',
          nombre: '',
          descripcion: '',
          alcance: 'G'
        });
        onRefresh();
      } else {
        setErrorMsg(data.error || 'Error al crear rol');
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
          <h1>Administración de Usuarios y Roles</h1>
          <p>Control de acceso basado en roles (RBAC), credenciales y perfiles aislados por tenant.</p>
        </div>

        <div style={{ display: 'flex', gap: '10px' }}>
          {activeSubTab === 'users' ? (
            <button className="btn btn-primary" onClick={() => setShowCreateUserModal(true)}>
              <UserPlus size={16} />
              <span>Nuevo Usuario</span>
            </button>
          ) : (
            <button className="btn btn-primary" onClick={() => setShowCreateRoleModal(true)}>
              <Plus size={16} />
              <span>Nuevo Rol</span>
            </button>
          )}
        </div>
      </div>

      {/* Sub Tabs */}
      <div style={{ display: 'flex', gap: '12px', marginBottom: '20px' }}>
        <button
          onClick={() => setActiveSubTab('users')}
          className={`btn ${activeSubTab === 'users' ? 'btn-primary' : 'btn-secondary'}`}
        >
          <Users2 size={16} />
          <span>Usuarios ({users.length})</span>
        </button>
        <button
          onClick={() => setActiveSubTab('roles')}
          className={`btn ${activeSubTab === 'roles' ? 'btn-primary' : 'btn-secondary'}`}
        >
          <Shield size={16} />
          <span>Roles de Seguridad ({roles.length})</span>
        </button>
      </div>

      {/* TABLA DE USUARIOS */}
      {activeSubTab === 'users' && (
        <div className="table-container">
          <table className="data-table">
            <thead>
              <tr>
                <th>Usuario</th>
                <th>Nombre y Apellido</th>
                <th>Documento</th>
                <th>Correo Electrónico</th>
                <th>Roles Asignados</th>
                <th>Estado</th>
                <th>Último Ingreso</th>
              </tr>
            </thead>
            <tbody>
              {users.map((u) => (
                <tr key={u.id}>
                  <td>
                    <div style={{ fontWeight: 700, color: 'var(--color-primary)' }}>
                      {u.nombre_usuario}
                    </div>
                    <div style={{ fontSize: '11px', color: 'var(--text-dim)' }}>ID: #{u.id}</div>
                  </td>
                  <td>{u.primer_nombre} {u.primer_apellido}</td>
                  <td>
                    <span style={{ fontFamily: 'var(--font-mono)', fontSize: '12px' }}>
                      {u.tipo_documento} {u.numero_documento}
                    </span>
                  </td>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                      <Mail size={12} color="var(--text-muted)" />
                      <span>{u.correo_electronico}</span>
                    </div>
                  </td>
                  <td>
                    <div style={{ display: 'flex', gap: '4px', flexWrap: 'wrap' }}>
                      {(u.roles || ['ROL_OPERADOR']).map((r, i) => (
                        <span key={i} className="badge badge-primary">{r}</span>
                      ))}
                    </div>
                  </td>
                  <td>
                    <span className={`badge ${u.estado === 1 ? 'badge-success' : 'badge-danger'}`}>
                      {u.bloqueado === 1 ? 'Bloqueado' : u.estado === 1 ? 'Activo' : 'Inactivo'}
                    </span>
                  </td>
                  <td style={{ fontSize: '12px', color: 'var(--text-muted)' }}>
                    {u.ultimo_ingreso || 'Sin ingresos'}
                  </td>
                </tr>
              ))}
              {users.length === 0 && (
                <tr>
                  <td colSpan={7} style={{ textAlign: 'center', padding: '30px', color: 'var(--text-muted)' }}>
                    No hay usuarios registrados para este tenant.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      )}

      {/* TABLA DE ROLES */}
      {activeSubTab === 'roles' && (
        <div className="table-container">
          <table className="data-table">
            <thead>
              <tr>
                <th>Código de Rol</th>
                <th>Nombre del Rol</th>
                <th>Descripción</th>
                <th>Alcance</th>
                <th>Permisos Otorgados</th>
                <th>Estado</th>
              </tr>
            </thead>
            <tbody>
              {roles.map((r) => (
                <tr key={r.id}>
                  <td>
                    <span className="badge badge-primary" style={{ fontFamily: 'var(--font-mono)' }}>
                      {r.codigo}
                    </span>
                  </td>
                  <td style={{ fontWeight: 700 }}>{r.nombre}</td>
                  <td style={{ color: 'var(--text-muted)', fontSize: '13px' }}>{r.descripcion}</td>
                  <td>
                    <span className="badge badge-warning">
                      {r.alcance === 'G' ? 'Global' : r.alcance === 'S' ? 'Sucursal' : 'Operativo'}
                    </span>
                  </td>
                  <td>
                    <div style={{ display: 'flex', gap: '4px', flexWrap: 'wrap' }}>
                      {(r.permisos || ['ACCESO_GENERAL']).slice(0, 3).map((p, i) => (
                        <span key={i} className="badge badge-success" style={{ fontSize: '10px' }}>{p}</span>
                      ))}
                      {(r.permisos && r.permisos.length > 3) && (
                        <span style={{ fontSize: '11px', color: 'var(--text-dim)' }}>+{r.permisos.length - 3}</span>
                      )}
                    </div>
                  </td>
                  <td>
                    <span className="badge badge-success">Activo</span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* MODAL CREAR USUARIO */}
      {showCreateUserModal && (
        <div className="modal-overlay">
          <div className="modal-content">
            <div className="modal-header">
              <h2 style={{ fontSize: '18px', fontWeight: 700, color: 'var(--text-main)' }}>
                Dar de Alta Nuevo Usuario en el Tenant
              </h2>
              <button onClick={() => setShowCreateUserModal(false)} style={{ background: 'none', border: 'none', color: 'var(--text-muted)', cursor: 'pointer' }}>
                <X size={20} />
              </button>
            </div>

            <form onSubmit={handleCreateUser}>
              <div className="modal-body">
                {errorMsg && (
                  <div style={{ padding: '10px 14px', background: 'var(--badge-bg-danger)', border: '1px solid var(--badge-border-danger)', color: 'var(--color-danger)', borderRadius: 'var(--radius-md)', marginBottom: '16px', fontSize: '13px' }}>
                    {errorMsg}
                  </div>
                )}

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                  <div className="form-group">
                    <label className="form-label">Nombre de Usuario (Username)</label>
                    <input
                      type="text"
                      required
                      placeholder="cgomez"
                      value={userForm.nombre_usuario}
                      onChange={(e) => setUserForm({ ...userForm, nombre_usuario: e.target.value })}
                      className="form-input"
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">Correo Electrónico</label>
                    <input
                      type="email"
                      required
                      placeholder="carlos.gomez@empresa.com"
                      value={userForm.correo_electronico}
                      onChange={(e) => setUserForm({ ...userForm, correo_electronico: e.target.value })}
                      className="form-input"
                    />
                  </div>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                  <div className="form-group">
                    <label className="form-label">Primer Nombre</label>
                    <input
                      type="text"
                      required
                      placeholder="Carlos"
                      value={userForm.primer_nombre}
                      onChange={(e) => setUserForm({ ...userForm, primer_nombre: e.target.value })}
                      className="form-input"
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">Primer Apellido</label>
                    <input
                      type="text"
                      placeholder="Gómez"
                      value={userForm.primer_apellido}
                      onChange={(e) => setUserForm({ ...userForm, primer_apellido: e.target.value })}
                      className="form-input"
                    />
                  </div>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 2fr', gap: '16px' }}>
                  <div className="form-group">
                    <label className="form-label">Tipo Doc</label>
                    <select
                      value={userForm.tipo_documento}
                      onChange={(e) => setUserForm({ ...userForm, tipo_documento: e.target.value })}
                      className="form-input"
                    >
                      <option value="CC">CC</option>
                      <option value="CE">CE</option>
                      <option value="PASAPORTE">PASAPORTE</option>
                      <option value="NIT">NIT</option>
                    </select>
                  </div>

                  <div className="form-group">
                    <label className="form-label">Número de Identificación</label>
                    <input
                      type="text"
                      placeholder="1020304050"
                      value={userForm.numero_documento}
                      onChange={(e) => setUserForm({ ...userForm, numero_documento: e.target.value })}
                      className="form-input"
                    />
                  </div>
                </div>

                <div className="form-group">
                  <label className="form-label">Rol Asignado</label>
                  <select
                    value={userForm.codigo_rol}
                    onChange={(e) => setUserForm({ ...userForm, codigo_rol: e.target.value })}
                    className="form-input"
                  >
                    {roles.map((r) => (
                      <option key={r.id} value={r.codigo}>
                        {r.nombre} ({r.codigo})
                      </option>
                    ))}
                    {roles.length === 0 && <option value="ROL_OPERADOR">ROL_OPERADOR</option>}
                  </select>
                </div>
              </div>

              <div className="modal-footer">
                <button type="button" onClick={() => setShowCreateUserModal(false)} className="btn btn-secondary">
                  Cancelar
                </button>
                <button type="submit" className="btn btn-primary" disabled={isSubmitting}>
                  {isSubmitting ? 'Registrando...' : 'Dar de Alta'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* MODAL CREAR ROL */}
      {showCreateRoleModal && (
        <div className="modal-overlay">
          <div className="modal-content">
            <div className="modal-header">
              <h2 style={{ fontSize: '18px', fontWeight: 700, color: 'var(--text-main)' }}>
                Crear Nuevo Rol de Seguridad
              </h2>
              <button onClick={() => setShowCreateRoleModal(false)} style={{ background: 'none', border: 'none', color: 'var(--text-muted)', cursor: 'pointer' }}>
                <X size={20} />
              </button>
            </div>

            <form onSubmit={handleCreateRole}>
              <div className="modal-body">
                {errorMsg && (
                  <div style={{ padding: '10px 14px', background: 'var(--badge-bg-danger)', border: '1px solid var(--badge-border-danger)', color: 'var(--color-danger)', borderRadius: 'var(--radius-md)', marginBottom: '16px', fontSize: '13px' }}>
                    {errorMsg}
                  </div>
                )}

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                  <div className="form-group">
                    <label className="form-label">Código de Rol (Ej: ROL_AUDITOR)</label>
                    <input
                      type="text"
                      required
                      placeholder="ROL_AUDITOR"
                      value={roleForm.codigo}
                      onChange={(e) => setRoleForm({ ...roleForm, codigo: e.target.value })}
                      className="form-input"
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">Alcance</label>
                    <select
                      value={roleForm.alcance}
                      onChange={(e) => setRoleForm({ ...roleForm, alcance: e.target.value as any })}
                      className="form-input"
                    >
                      <option value="G">Global (Todo el tenant)</option>
                      <option value="S">Sucursal / Contexto</option>
                      <option value="O">Operativo / Limitado</option>
                    </select>
                  </div>
                </div>

                <div className="form-group">
                  <label className="form-label">Nombre del Rol</label>
                  <input
                    type="text"
                    required
                    placeholder="Auditor de Cumplimiento"
                    value={roleForm.nombre}
                    onChange={(e) => setRoleForm({ ...roleForm, nombre: e.target.value })}
                    className="form-input"
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Descripción</label>
                  <textarea
                    rows={3}
                    placeholder="Acceso de solo lectura para auditoría y revisión de trazas."
                    value={roleForm.descripcion}
                    onChange={(e) => setRoleForm({ ...roleForm, descripcion: e.target.value })}
                    className="form-input"
                    style={{ resize: 'vertical' }}
                  />
                </div>
              </div>

              <div className="modal-footer">
                <button type="button" onClick={() => setShowCreateRoleModal(false)} className="btn btn-secondary">
                  Cancelar
                </button>
                <button type="submit" className="btn btn-primary" disabled={isSubmitting}>
                  {isSubmitting ? 'Guardando...' : 'Crear Rol'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
