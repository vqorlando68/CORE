/**
 * endpoints.ts
 * Catálogo centralizado de endpoints API del sistema CORE.
 */

export const API_ENDPOINTS = {
  HEALTH: '/api/health',
  TENANTS: '/api/tenants',
  USERS: '/api/users',
  APPS: '/api/apps',
  DOCS: '/api/docs',
  TRACES: '/api/traces',
} as const;

export type ApiEndpoint = typeof API_ENDPOINTS[keyof typeof API_ENDPOINTS];
