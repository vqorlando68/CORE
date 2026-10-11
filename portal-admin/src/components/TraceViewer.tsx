'use client';

import React, { useState } from 'react';
import { TrazaEjecucion, TrazaLlamado } from '@/lib/types';
import { 
  Activity, 
  Clock, 
  CheckCircle2, 
  AlertCircle, 
  Eye, 
  Copy, 
  Check, 
  ArrowRight, 
  Server,
  Layers,
  X 
} from 'lucide-react';

interface TraceViewerProps {
  traces: TrazaEjecucion[];
  selectedTenantId: number;
}

export const TraceViewer: React.FC<TraceViewerProps> = ({ traces }) => {
  const [selectedTrace, setSelectedTrace] = useState<TrazaEjecucion | null>(null);
  const [callStack, setCallStack] = useState<TrazaLlamado[]>([]);
  const [loadingStack, setLoadingStack] = useState(false);
  const [filterState, setFilterState] = useState<string>('ALL');
  const [copiedKey, setCopiedKey] = useState<string | null>(null);

  const filtered = traces.filter((t) => {
    if (filterState === 'ALL') return true;
    return t.estado === filterState;
  });

  const handleOpenDetail = async (trace: TrazaEjecucion) => {
    setSelectedTrace(trace);
    setLoadingStack(true);

    try {
      const res = await fetch(`/api/traces?executionId=${trace.id}`);
      const data = await res.json();
      if (data.success) {
        setCallStack(data.data || []);
      }
    } catch (err) {
      console.warn('Error cargando call stack:', err);
    } finally {
      setLoadingStack(false);
    }
  };

  const copyToClipboard = (text: string, key: string) => {
    navigator.clipboard.writeText(text);
    setCopiedKey(key);
    setTimeout(() => setCopiedKey(null), 2000);
  };

  return (
    <div>
      <div className="view-header">
        <div className="view-title-group">
          <h1>Visor de Trazas y Telemetría APM (Observabilidad)</h1>
          <p>Auditoría de ejecuciones de subprogramas en tiempo real, latencias P95, call-stack jerárquico y capturas forenses.</p>
        </div>

        {/* Filtros de Estado */}
        <div style={{ display: 'flex', gap: '8px' }}>
          {['ALL', 'EXITO', 'ERROR', 'EN_PROCESO'].map((st) => (
            <button
              key={st}
              onClick={() => setFilterState(st)}
              className={`btn btn-sm ${filterState === st ? 'btn-primary' : 'btn-secondary'}`}
            >
              {st === 'ALL' ? 'Todos los Estados' : st}
            </button>
          ))}
        </div>
      </div>

      {/* Tabla de Ejecuciones de Traza */}
      <div className="table-container">
        <table className="data-table">
          <thead>
            <tr>
              <th>Trace ID</th>
              <th>Paquete & Método</th>
              <th>Hora Bogotá</th>
              <th>Duración</th>
              <th>Estado</th>
              <th>Sub-Llamados</th>
              <th>IP Origen</th>
              <th>Acción</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((t) => (
              <tr key={t.id}>
                <td>
                  <span style={{ fontFamily: 'var(--font-mono)', fontSize: '12px', color: 'var(--color-primary)', fontWeight: 600 }}>
                    {t.codigo_traza}
                  </span>
                  <div style={{ fontSize: '10.5px', color: 'var(--text-dim)' }}>ID: #{t.id}</div>
                </td>
                <td>
                  <div style={{ fontWeight: 700 }}>{t.nombre_metodo}</div>
                  <div style={{ fontSize: '11.5px', color: 'var(--text-muted)', fontFamily: 'var(--font-mono)' }}>
                    {t.nombre_paquete}
                  </div>
                </td>
                <td style={{ fontSize: '12.5px' }}>
                  {t.fecha_inicio}
                </td>
                <td>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                    <Clock size={12} color="var(--text-muted)" />
                    <span style={{ fontFamily: 'var(--font-mono)', fontWeight: 700, color: (t.duracion_ms || 0) > 100 ? 'var(--color-warning)' : 'var(--text-main)' }}>
                      {t.duracion_ms != null ? `${t.duracion_ms.toFixed(2)} ms` : '-'}
                    </span>
                  </div>
                </td>
                <td>
                  <span className={`badge ${t.estado === 'EXITO' ? 'badge-success' : t.estado === 'ERROR' ? 'badge-danger' : 'badge-warning'}`}>
                    {t.estado}
                  </span>
                </td>
                <td>
                  <span className="badge badge-primary">
                    {t.total_llamados} spans
                  </span>
                </td>
                <td style={{ fontSize: '12px', color: 'var(--text-muted)' }}>
                  {t.ip_origen || '127.0.0.1'}
                </td>
                <td>
                  <button onClick={() => handleOpenDetail(t)} className="btn btn-secondary btn-sm">
                    <Eye size={12} />
                    <span>Inspeccionar</span>
                  </button>
                </td>
              </tr>
            ))}
            {filtered.length === 0 && (
              <tr>
                <td colSpan={8} style={{ textAlign: 'center', padding: '30px', color: 'var(--text-muted)' }}>
                  No hay trazas registradas con los filtros seleccionados.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {/* MODAL DETALLE DE TRAZA & CALL STACK */}
      {selectedTrace && (
        <div className="modal-overlay" onClick={() => setSelectedTrace(null)}>
          <div className="modal-content" style={{ maxWidth: '850px' }} onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '4px' }}>
                  <span className={`badge ${selectedTrace.estado === 'EXITO' ? 'badge-success' : 'badge-danger'}`}>
                    {selectedTrace.estado}
                  </span>
                  <span style={{ fontFamily: 'var(--font-mono)', fontSize: '12px', color: 'var(--color-primary)' }}>
                    {selectedTrace.codigo_traza}
                  </span>
                </div>
                <h2 style={{ fontSize: '18px', fontWeight: 700, color: 'var(--text-main)' }}>
                  {selectedTrace.nombre_paquete}.{selectedTrace.nombre_metodo}
                </h2>
              </div>
              <button onClick={() => setSelectedTrace(null)} style={{ background: 'none', border: 'none', color: 'var(--text-muted)', cursor: 'pointer' }}>
                <X size={20} />
              </button>
            </div>

            <div className="modal-body" style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
              {/* Metadatos Rápidos */}
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '12px', padding: '14px', background: 'var(--bg-surface-elevated)', borderRadius: 'var(--radius-md)' }}>
                <div>
                  <div style={{ fontSize: '11px', color: 'var(--text-dim)', textTransform: 'uppercase' }}>Duración Total</div>
                  <div style={{ fontSize: '15px', fontWeight: 800, color: 'var(--color-primary)', fontFamily: 'var(--font-mono)' }}>
                    {selectedTrace.duracion_ms?.toFixed(2)} ms
                  </div>
                </div>
                <div>
                  <div style={{ fontSize: '11px', color: 'var(--text-dim)', textTransform: 'uppercase' }}>Sesión Oracle</div>
                  <div style={{ fontSize: '13px', fontWeight: 600 }}>
                    {selectedTrace.id_sesion_oracle || 'SID: Local'}
                  </div>
                </div>
                <div>
                  <div style={{ fontSize: '11px', color: 'var(--text-dim)', textTransform: 'uppercase' }}>IP Cliente</div>
                  <div style={{ fontSize: '13px', fontWeight: 600 }}>
                    {selectedTrace.ip_origen || '127.0.0.1'}
                  </div>
                </div>
                <div>
                  <div style={{ fontSize: '11px', color: 'var(--text-dim)', textTransform: 'uppercase' }}>Fecha Ejecución</div>
                  <div style={{ fontSize: '12px' }}>
                    {selectedTrace.fecha_inicio}
                  </div>
                </div>
              </div>

              {/* Mensaje de Error si aplica */}
              {selectedTrace.mensaje_error && (
                <div style={{ padding: '12px', background: 'var(--badge-bg-danger)', border: '1px solid var(--badge-border-danger)', borderRadius: 'var(--radius-md)', color: 'var(--color-danger)' }}>
                  <strong>Error Capturado (SQLCODE {selectedTrace.codigo_error}):</strong>
                  <div style={{ fontSize: '12.5px', marginTop: '4px' }}>{selectedTrace.mensaje_error}</div>
                </div>
              )}

              {/* CALL-STACK / SPANS JERÁRQUICOS */}
              <div>
                <div className="form-label" style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                  <Layers size={14} />
                  <span>Call-Stack Jerárquico de Subprogramas Invocados</span>
                </div>

                <div className="trace-timeline">
                  {callStack.map((span) => (
                    <div 
                      key={span.id} 
                      className={`timeline-item ${span.estado === 'ERROR' ? 'error' : ''}`}
                      style={{ marginLeft: `${(span.nivel_anidamiento - 1) * 20}px` }}
                    >
                      <div style={{ flex: 1 }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                          <span className="badge badge-primary" style={{ fontSize: '10px' }}>
                            {span.tipo_llamado}
                          </span>
                          <span style={{ fontFamily: 'var(--font-mono)', fontWeight: 700, fontSize: '13px' }}>
                            {span.paquete_llamado}.{span.metodo_llamado}
                          </span>
                          <span className={`badge ${span.estado === 'EXITO' ? 'badge-success' : 'badge-danger'}`} style={{ fontSize: '9px' }}>
                            {span.estado}
                          </span>
                        </div>
                        {span.mensaje_error && (
                          <div style={{ fontSize: '11.5px', color: 'var(--color-danger)', marginTop: '4px' }}>
                            {span.mensaje_error}
                          </div>
                        )}
                      </div>

                      <div style={{ fontFamily: 'var(--font-mono)', fontSize: '12px', color: 'var(--text-muted)' }}>
                        {span.duracion_ms != null ? `${span.duracion_ms.toFixed(2)} ms` : '-'}
                      </div>
                    </div>
                  ))}

                  {callStack.length === 0 && !loadingStack && (
                    <div style={{ fontSize: '13px', color: 'var(--text-muted)', padding: '10px', textAlign: 'center' }}>
                      No se registraron sub-llamados para esta traza (nivel cabecera).
                    </div>
                  )}
                </div>
              </div>

              {/* PAYLOADS ENTRADA Y SALIDA */}
              {selectedTrace.json_entrada && (
                <div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                    <span className="form-label">Payload de Entrada (json_entrada)</span>
                    <button
                      onClick={() => copyToClipboard(selectedTrace.json_entrada!, 'tr_in')}
                      className="btn btn-secondary btn-sm"
                    >
                      {copiedKey === 'tr_in' ? <Check size={12} color="var(--color-success)" /> : <Copy size={12} />}
                      <span>{copiedKey === 'tr_in' ? 'Copiado' : 'Copiar'}</span>
                    </button>
                  </div>
                  <div className="code-block">{selectedTrace.json_entrada}</div>
                </div>
              )}

              {selectedTrace.json_salida && (
                <div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                    <span className="form-label">Payload de Salida (json_salida)</span>
                    <button
                      onClick={() => copyToClipboard(selectedTrace.json_salida!, 'tr_out')}
                      className="btn btn-secondary btn-sm"
                    >
                      {copiedKey === 'tr_out' ? <Check size={12} color="var(--color-success)" /> : <Copy size={12} />}
                      <span>{copiedKey === 'tr_out' ? 'Copiado' : 'Copiar'}</span>
                    </button>
                  </div>
                  <div className="code-block" style={{ color: 'var(--color-success)' }}>{selectedTrace.json_salida}</div>
                </div>
              )}
            </div>

            <div className="modal-footer">
              <button onClick={() => setSelectedTrace(null)} className="btn btn-secondary">
                Cerrar
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
