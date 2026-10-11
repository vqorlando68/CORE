'use client';

import React from 'react';

export interface MainLayoutProps {
  sidebar?: React.ReactNode;
  header?: React.ReactNode;
  banner?: React.ReactNode;
  children: React.ReactNode;
}

export const MainLayout: React.FC<MainLayoutProps> = ({
  sidebar,
  header,
  banner,
  children,
}) => {
  return (
    <div className="app-container">
      {/* Sidebar de Navegación Lateral */}
      {sidebar}

      {/* Contenedor Principal */}
      <div className="main-wrapper">
        {/* Cabecera Superior */}
        {header}

        {/* Banner de Conexión / Alertas Transversales */}
        {banner}

        {/* Área de Trabajo / Vistas Modulares */}
        <main className="content-area">
          {children}
        </main>
      </div>
    </div>
  );
};
