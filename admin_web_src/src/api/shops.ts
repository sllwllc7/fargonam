import { apiFetch } from "./client";
import type { Page } from "./types";

export type ShopStatus = "pending" | "approved" | "rejected";

export type ShopAdminOut = {
  id: number;
  owner_id: number;
  name: string;
  description: string | null;
  status: ShopStatus;
  admin_note: string | null;
  is_active: boolean;
  is_trusted: boolean;
  created_at: string;
  owner_phone: string | null;
  product_count: number;
};

export function listShops(params: { status?: ShopStatus; offset?: number; limit?: number } = {}) {
  const q = new URLSearchParams();
  if (params.status) q.set("status", params.status);
  q.set("offset", String(params.offset ?? 0));
  q.set("limit", String(params.limit ?? 100));
  return apiFetch<Page<ShopAdminOut>>(`/admin/shops?${q}`);
}

export function updateShop(
  id: number,
  payload: Partial<{ status: ShopStatus; admin_note: string; is_trusted: boolean; is_active: boolean }>,
) {
  return apiFetch<ShopAdminOut>(`/admin/shops/${id}`, { method: "PATCH", body: JSON.stringify(payload) });
}

export function createSeller(payload: {
  full_name: string;
  telegram_id: number;
  phone?: string | null;
  shop_name: string;
  shop_description?: string | null;
}) {
  return apiFetch<ShopAdminOut>(`/admin/shops`, { method: "POST", body: JSON.stringify(payload) });
}
