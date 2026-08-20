import { apiFetch } from "./client";
import type { Page } from "./types";

export type UserRole = "buyer" | "seller" | "admin";

export type UserOut = {
  id: number;
  phone: string | null;
  full_name: string | null;
  role: UserRole;
  avatar_url: string | null;
  is_active: boolean;
  created_at: string;
};

export function listUsers(params: { q?: string; role?: UserRole; offset?: number; limit?: number } = {}) {
  const query = new URLSearchParams();
  if (params.q) query.set("q", params.q);
  if (params.role) query.set("role", params.role);
  query.set("offset", String(params.offset ?? 0));
  query.set("limit", String(params.limit ?? 50));
  return apiFetch<Page<UserOut>>(`/admin/users?${query}`);
}

export function updateUser(id: number, payload: Partial<{ is_active: boolean; role: UserRole }>) {
  return apiFetch<UserOut>(`/admin/users/${id}`, { method: "PATCH", body: JSON.stringify(payload) });
}

export function broadcastMessage(payload: {
  title: string;
  body: string;
  target: "all" | "buyers" | "sellers" | "user_ids";
  user_ids?: number[];
}) {
  return apiFetch<{ total_users: number; push_sent: number }>(`/admin/broadcast`, {
    method: "POST",
    body: JSON.stringify(payload),
  });
}
