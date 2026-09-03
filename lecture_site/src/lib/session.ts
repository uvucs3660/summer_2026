import { createHmac, timingSafeEqual } from "node:crypto";

export const SESSION_MAX_AGE_MS = 120 * 24 * 3600 * 1000;
const HANDLE_RE = /^[A-Za-z0-9](?:[A-Za-z0-9]|-(?=[A-Za-z0-9])){0,38}$/;

export interface Session { handle: string; iat: number; }

function mac(payload: string, secret: string): Buffer {
  return createHmac("sha256", secret).update(payload).digest();
}

export function signSession(handle: string, secret: string, now = Date.now()): string {
  const payload = Buffer.from(JSON.stringify({ h: handle, iat: now })).toString("base64url");
  return `${payload}.${mac(payload, secret).toString("base64url")}`;
}

export function verifySession(
  token: string | undefined, secret: string,
  maxAgeMs = SESSION_MAX_AGE_MS, now = Date.now(),
): Session | null {
  if (!token) return null;
  const parts = token.split(".");
  if (parts.length !== 2 || !parts[0] || !parts[1]) return null;
  const expect = mac(parts[0], secret);
  const got = Buffer.from(parts[1], "base64url");
  if (got.length !== expect.length || !timingSafeEqual(got, expect)) return null;
  let obj: unknown;
  try { obj = JSON.parse(Buffer.from(parts[0], "base64url").toString()); } catch { return null; }
  if (typeof obj !== "object" || obj === null) return null;
  const { h, iat } = obj as { h?: unknown; iat?: unknown };
  if (typeof h !== "string" || !HANDLE_RE.test(h) || typeof iat !== "number") return null;
  if (now - iat > maxAgeMs || iat > now + 60_000) return null;
  return { handle: h, iat };
}

export function isAdmin(handle: string, adminHandles = process.env.ADMIN_HANDLES ?? ""): boolean {
  return adminHandles.split(",").map((s) => s.trim().toLowerCase()).filter(Boolean)
    .includes(handle.toLowerCase());
}

export function sessionFromRequest(req: Request, secret = process.env.SESSION_SECRET ?? ""): Session | null {
  if (!secret) return null;
  const m = (req.headers.get("cookie") ?? "").match(/(?:^|;\s*)session=([^;]+)/);
  return verifySession(m?.[1], secret);
}

export function sessionCookie(token: string): string {
  return `session=${token}; Path=/; HttpOnly; Secure; SameSite=Lax; Max-Age=${SESSION_MAX_AGE_MS / 1000}`;
}

export function clearSessionCookie(): string {
  return "session=; Path=/; HttpOnly; Secure; SameSite=Lax; Max-Age=0";
}
