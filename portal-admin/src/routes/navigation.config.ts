import { 
  LayoutDashboard, 
  Building2, 
  AppWindow, 
  Users2, 
  BookOpenCheck, 
  Activity,
  LucideIcon 
} from 'lucide-react';

export type NavTabId = 'dashboard' | 'tenants' | 'apps' | 'users' | 'methods' | 'traces';

export interface NavItem {
  id: NavTabId;
  label: string;
  icon: LucideIcon;
  badge?: string;
}

export const NAVIGATION_ITEMS: NavItem[] = [
  { id: 'dashboard', label: 'Panel de Control', icon: LayoutDashboard },
  { id: 'tenants', label: 'Gestión de Tenants', icon: Building2 },
  { id: 'apps', label: 'Aplicaciones & Módulos', icon: AppWindow },
  { id: 'users', label: 'Usuarios & Roles', icon: Users2 },
  { id: 'methods', label: 'Documentación Métodos', icon: BookOpenCheck },
  { id: 'traces', label: 'Visor de Trazas (APM)', icon: Activity },
];
