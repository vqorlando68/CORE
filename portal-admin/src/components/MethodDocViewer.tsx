'use client';

import React, { useState } from 'react';
import { DocumentacionMetodo } from '@/lib/types';
import { 
  BookOpenCheck, 
  Search, 
  Copy, 
  Check, 
  Lock, 
  Unlock, 
  Cpu, 
  Activity, 
  KeyRound, 
  UserPlus, 
  ListOrdered, 
  CheckCircle2, 
  AlertTriangle,
  X,
  ExternalLink,
  GitBranch
} from 'lucide-react';
import { FlowchartDiagram } from './FlowchartDiagram';

interface MethodDocViewerProps {
  methods: DocumentacionMetodo[];
  selectedTenantId: number;
}

export const MethodDocViewer: React.FC<MethodDocViewerProps> = ({ methods }) => {
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string>('ALL');
  const [activeMethod, setActiveMethod] = useState<DocumentacionMetodo | null>(null);
  const [copiedKey, setCopiedKey] = useState<string | null>(null);

  const categories = ['ALL', 'SEGURIDAD', 'TELEMETRIA', 'OPERATIVO', 'CONFIGURACION'];

  const filtered = methods.filter((m) => {
    const matchesCat = selectedCategory === 'ALL' || m.categoria_visual === selectedCategory;
    const q = searchTerm.toLowerCase();
    const matchesSearch = !searchTerm || 
      m.titulo_funcional.toLowerCase().includes(q) ||
      m.nombre_paquete.toLowerCase().includes(q) ||
      m.nombre_metodo.toLowerCase().includes(q) ||
      (m.etiquetas_busqueda && m.etiquetas_busqueda.toLowerCase().includes(q));
    return matchesCat && matchesSearch;
  });

  const copyToClipboard = (text: string, key: string) => {
    navigator.clipboard.writeText(text);
    setCopiedKey(key);
    setTimeout(() => setCopiedKey(null), 2000);
  };

  const getIcon = (iconName: string) => {
    switch (iconName) {
      case 'lucide-user-plus': return <UserPlus size={18} />;
      case 'lucide-activity': return <Activity size={18} />;
      case 'lucide-key-round': return <KeyRound size={18} />;
      default: return <Cpu size={18} />;
    }
  };

  return (
    <div>
      <div className="view-header">
        <div className="view-title-group">
          <h1>Catálogo y Documentación de Métodos Orquestadores</h1>
          <p>Especificación funcional en lenguaje natural de los subprogramas expuestos (pkgln_) con flujos, validaciones y payloads.</p>
        </div>
      </div>

      {/* Barra de Filtros y Búsqueda */}
      <div style={{ display: 'flex', gap: '16px', alignItems: 'center', marginBottom: '24px', flexWrap: 'wrap' }}>
        <div style={{ position: 'relative', flex: 1, minWidth: '280px' }}>
          <Search size={16} style={{ position: 'absolute', left: '14px', top: '50%', transform: 'translateY(-50%)', color: 'var(--text-muted)' }} />
          <input
            type="text"
            placeholder="Buscar por título, paquete, método o etiqueta..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="form-input"
            style={{ paddingLeft: '40px' }}
          />
        </div>

        <div style={{ display: 'flex', gap: '8px' }}>
          {categories.map((cat) => (
            <button
              key={cat}
              onClick={() => setSelectedCategory(cat)}
              className={`btn btn-sm ${selectedCategory === cat ? 'btn-primary' : 'btn-secondary'}`}
            >
              {cat === 'ALL' ? 'Todas' : cat}
            </button>
          ))}
        </div>
      </div>

      {/* Grid de Métodos Documentados */}
      <div className="grid-cards">
        {filtered.map((item) => (
          <div 
            key={item.id} 
            className="card"
            style={{ 
              cursor: 'pointer',
              borderLeft: `4px solid ${item.color_distintivo || 'var(--color-primary)'}` 
            }}
            onClick={() => setActiveMethod(item)}
          >
            <div className="card-header">
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <span 
                  style={{ 
                    color: item.color_distintivo || 'var(--color-primary)',
                    display: 'flex',
                    alignItems: 'center'
                  }}
                >
                  {getIcon(item.icono_interfaz)}
                </span>
                <span className="badge badge-primary" style={{ fontSize: '10px' }}>
                  {item.categoria_visual}
                </span>
              </div>

              <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                {item.requiere_autenticacion === 1 ? (
                  <span className="badge badge-warning" title="Requiere autenticación">
                    <Lock size={10} />
                  </span>
                ) : (
                  <span className="badge badge-success" title="Acceso público">
                    <Unlock size={10} />
                  </span>
                )}
                <span style={{ fontFamily: 'var(--font-mono)', fontSize: '11px', color: 'var(--text-dim)' }}>
                  v{item.version_metodo}
                </span>
              </div>
            </div>

            <h3 className="card-title" style={{ fontSize: '15px', marginBottom: '8px' }}>
              {item.titulo_funcional}
            </h3>

            <div style={{ fontFamily: 'var(--font-mono)', fontSize: '12px', color: 'var(--color-primary)', marginBottom: '10px' }}>
              {item.nombre_paquete}.{item.nombre_metodo}
            </div>

            <p className="card-desc" style={{ fontSize: '12.5px', lineClamp: 3, display: '-webkit-box', WebkitBoxOrient: 'vertical', overflow: 'hidden' }}>
              {item.resumen_ejecutivo}
            </p>

            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', paddingTop: '12px', borderTop: '1px solid var(--border-subtle)', fontSize: '11.5px' }}>
              <span style={{ color: 'var(--text-muted)' }}>
                Actor: <strong>{item.actor_principal || 'API / Front'}</strong>
              </span>
              <span style={{ color: 'var(--color-primary)', display: 'flex', alignItems: 'center', gap: '4px', fontWeight: 600 }}>
                Ver Ficha <ExternalLink size={12} />
              </span>
            </div>
          </div>
        ))}

        {filtered.length === 0 && (
          <div style={{ gridColumn: '1 / -1', textAlign: 'center', padding: '60px', color: 'var(--text-muted)' }}>
            No se encontraron métodos documentados con los criterios de búsqueda.
          </div>
        )}
      </div>

      {/* MODAL DETALLADO EN LENGUAJE NATURAL */}
      {activeMethod && (
        <div className="modal-overlay" onClick={() => setActiveMethod(null)}>
          <div className="modal-content" style={{ maxWidth: '850px' }} onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '4px' }}>
                  <span className="badge badge-primary">{activeMethod.categoria_visual}</span>
                  <span style={{ fontFamily: 'var(--font-mono)', fontSize: '12px', color: 'var(--color-primary)' }}>
                    {activeMethod.nombre_paquete}.{activeMethod.nombre_metodo}
                  </span>
                  <span style={{ fontSize: '11px', color: 'var(--text-dim)' }}>v{activeMethod.version_metodo}</span>
                </div>
                <h2 style={{ fontSize: '18px', fontWeight: 800, color: 'var(--text-main)' }}>
                  {activeMethod.titulo_funcional}
                </h2>
              </div>
              <button onClick={() => setActiveMethod(null)} style={{ background: 'none', border: 'none', color: 'var(--text-muted)', cursor: 'pointer' }}>
                <X size={20} />
              </button>
            </div>

            <div className="modal-body" style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
              {/* Resumen & Narrativa de Negocio */}
              <div>
                <div className="form-label" style={{ color: 'var(--color-primary)' }}>Propósito y Narrativa de Negocio</div>
                <p style={{ fontSize: '14px', lineHeight: '1.7', color: 'var(--text-main)' }}>
                  {activeMethod.descripcion_negocio}
                </p>
                {activeMethod.actor_principal && (
                  <div style={{ marginTop: '8px', fontSize: '12.5px', color: 'var(--text-muted)' }}>
                    🎯 <strong>Actor o Rol Principal:</strong> {activeMethod.actor_principal}
                  </div>
                )}
              </div>

              {/* Flujo Funcional Paso a Paso (Diagrama de Flujo Gráfico) */}
              {activeMethod.flujo_funcional_pasos && (
                <div>
                  <div className="form-label" style={{ display: 'flex', alignItems: 'center', gap: '6px', marginBottom: '8px' }}>
                    <GitBranch size={14} color="var(--color-primary)" />
                    <span>Diagrama de Flujo del Proceso (Paso a Paso)</span>
                  </div>
                  <FlowchartDiagram
                    pasosTexto={activeMethod.flujo_funcional_pasos}
                    tituloMetodo={`${activeMethod.nombre_paquete}.${activeMethod.nombre_metodo}`}
                  />
                </div>
              )}

              {/* Reglas de Validación */}
              {activeMethod.reglas_validacion && (
                <div>
                  <div className="form-label" style={{ color: 'var(--color-warning)' }}>Reglas de Validación Exigidas</div>
                  <pre style={{ whiteSpace: 'pre-wrap', fontFamily: 'inherit', fontSize: '12.5px', color: 'var(--text-muted)', lineHeight: '1.5' }}>
                    {activeMethod.reglas_validacion}
                  </pre>
                </div>
              )}

              {/* Payload de Entrada */}
              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                  <div>
                    <span className="form-label">Parámetro p_json_entrada (IN CLOB)</span>
                    <span style={{ fontSize: '12px', color: 'var(--text-muted)' }}>
                      {activeMethod.descripcion_entrada_natural}
                    </span>
                  </div>
                  <button
                    onClick={() => copyToClipboard(activeMethod.ejemplo_json_entrada, 'in')}
                    className="btn btn-secondary btn-sm"
                  >
                    {copiedKey === 'in' ? <Check size={12} color="var(--color-success)" /> : <Copy size={12} />}
                    <span>{copiedKey === 'in' ? 'Copiado' : 'Copiar JSON'}</span>
                  </button>
                </div>
                <div className="code-block">
                  {activeMethod.ejemplo_json_entrada}
                </div>
              </div>

              {/* Payload de Salida */}
              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                  <div>
                    <span className="form-label">Parámetro p_json_salida (OUT CLOB)</span>
                    <span style={{ fontSize: '12px', color: 'var(--text-muted)' }}>
                      {activeMethod.descripcion_salida_natural}
                    </span>
                  </div>
                  <button
                    onClick={() => copyToClipboard(activeMethod.ejemplo_json_salida, 'out')}
                    className="btn btn-secondary btn-sm"
                  >
                    {copiedKey === 'out' ? <Check size={12} color="var(--color-success)" /> : <Copy size={12} />}
                    <span>{copiedKey === 'out' ? 'Copiado' : 'Copiar JSON'}</span>
                  </button>
                </div>
                <div className="code-block" style={{ color: 'var(--color-success)' }}>
                  {activeMethod.ejemplo_json_salida}
                </div>
              </div>

              {/* Excepciones de Negocio */}
              {activeMethod.excepciones_negocio && (
                <div style={{ padding: '12px', background: 'var(--badge-bg-danger)', borderRadius: 'var(--radius-md)', border: '1px solid var(--badge-border-danger)' }}>
                  <div className="form-label" style={{ color: 'var(--color-danger)', marginBottom: '4px' }}>
                    Excepciones Controladas y Posibles Errores
                  </div>
                  <pre style={{ whiteSpace: 'pre-wrap', fontFamily: 'inherit', fontSize: '12px', color: 'var(--color-danger)', lineHeight: '1.5' }}>
                    {activeMethod.excepciones_negocio}
                  </pre>
                </div>
              )}
            </div>

            <div className="modal-footer">
              <button onClick={() => setActiveMethod(null)} className="btn btn-secondary">
                Cerrar
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
