/** Fetch wrapper — access/refresh token localStorage'da, 401'da bir marta
 * avtomatik refresh qilib qayta urinadi (backend rotation: har refresh bir
 * martalik, shu sabab har safar yangi refresh_token ham saqlanadi). */

let accessToken: string | null = localStorage.getItem("admin_access_token");
let refreshToken: string | null = localStorage.getItem("admin_refresh_token");

export function setTokens(access: string, refresh: string): void {
  accessToken = access;
  refreshToken = refresh;
  localStorage.setItem("admin_access_token", access);
  localStorage.setItem("admin_refresh_token", refresh);
}

export function clearTokens(): void {
  accessToken = null;
  refreshToken = null;
  localStorage.removeItem("admin_access_token");
  localStorage.removeItem("admin_refresh_token");
}

export function getAccessToken(): string | null {
  return accessToken;
}

export class ApiError extends Error {
  status: number;
  detail: unknown;
  constructor(status: number, detail: unknown) {
    super(typeof detail === "string" ? detail : JSON.stringify(detail));
    this.status = status;
    this.detail = detail;
  }
}

async function doRefresh(): Promise<boolean> {
  if (!refreshToken) return false;
  const res = await fetch("/auth/refresh", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ refresh_token: refreshToken }),
  });
  if (!res.ok) {
    clearTokens();
    return false;
  }
  const data = await res.json();
  setTokens(data.access_token, data.refresh_token);
  return true;
}

export async function apiFetch<T = unknown>(
  path: string,
  opts: RequestInit = {},
  _retried = false,
): Promise<T> {
  const headers = new Headers(opts.headers);
  if (accessToken) headers.set("Authorization", `Bearer ${accessToken}`);
  const isForm = opts.body instanceof FormData;
  if (!isForm && opts.body && !headers.has("Content-Type")) {
    headers.set("Content-Type", "application/json");
  }

  const res = await fetch(path, { ...opts, headers });

  if (res.status === 401 && !_retried) {
    const ok = await doRefresh();
    if (ok) return apiFetch<T>(path, opts, true);
  }

  if (!res.ok) {
    let detail: unknown;
    try {
      detail = await res.json();
    } catch {
      detail = res.statusText;
    }
    const message =
      detail && typeof detail === "object" && "detail" in detail
        ? (detail as { detail: unknown }).detail
        : detail;
    throw new ApiError(res.status, message);
  }

  if (res.status === 204) return null as T;
  return res.json();
}
