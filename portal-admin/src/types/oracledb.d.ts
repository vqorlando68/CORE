declare module 'oracledb' {
  const oracledb: any;
  export default oracledb;
  export const NUMBER: number;
  export const STRING: number;
  export const BIND_IN: number;
  export const BIND_OUT: number;
  export const BIND_INOUT: number;
  export function getConnection(config: any): Promise<any>;
  export function createPool(config: any): Promise<any>;
}
