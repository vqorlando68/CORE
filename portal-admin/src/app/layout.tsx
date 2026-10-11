import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'CORE Engine — Portal Administrativo Multi-Tenant',
  description: 'Administración de Tenants, Soluciones SaaS, Seguridad RBAC, Catálogo en Lenguaje Natural y Telemetría APM sobre Oracle Database 23ai / 26ai.',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="es" data-theme="core">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link
          href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@300;400;500;600;700;800&family=JetBrains+Mono:wght@400;500;600&display=swap"
          rel="stylesheet"
        />
      </head>
      <body>{children}</body>
    </html>
  );
}
