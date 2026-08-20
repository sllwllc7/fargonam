import { apiFetch } from "./client";

export type KitItemOut = {
  id: number;
  variant_id: number;
  quantity: number;
  product_name: string | null;
  variant_name: string | null;
  price: number | null;
  line_total: number | null;
};

export type KitOut = {
  id: number;
  shop_id: number | null;
  name: string;
  grade_level: string | null;
  description: string | null;
  image_url: string | null;
  is_active: boolean;
  created_at: string;
  items: KitItemOut[];
  total: number;
  status: string;
  rejected_reason: string | null;
  pending_edit: Record<string, unknown> | null;
  submitted_at: string | null;
};

export function listKits(shopId: number) {
  return apiFetch<KitOut[]>(`/kits?shop_id=${shopId}`);
}

export type KitItemPayload = { variant_id: number; quantity: number };

export function createKit(payload: {
  shop_id: number;
  name: string;
  grade_level?: string | null;
  description?: string | null;
  items: KitItemPayload[];
}) {
  return apiFetch<KitOut>(`/kits`, { method: "POST", body: JSON.stringify(payload) });
}

export function updateKit(
  id: number,
  payload: Partial<{
    name: string;
    grade_level: string | null;
    description: string | null;
    is_active: boolean;
    items: KitItemPayload[];
  }>,
) {
  return apiFetch<KitOut>(`/kits/${id}`, { method: "PUT", body: JSON.stringify(payload) });
}

export function deleteKit(id: number) {
  return apiFetch<null>(`/kits/${id}`, { method: "DELETE" });
}

export function approveKit(id: number) {
  return apiFetch<KitOut>(`/admin/moderation/kits/${id}/approve`, { method: "POST" });
}
