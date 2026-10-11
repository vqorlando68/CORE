import { NextResponse } from 'next/server';
import { checkDatabaseHealth } from '@/lib/db';

export async function GET() {
  const health = await checkDatabaseHealth();
  return NextResponse.json(health);
}
