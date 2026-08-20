import { apiFetch } from "./client";
import type { Page } from "./types";

export type OrderStatus = "pending" | "paid" | "preparing" | "ready" | "shipped" | "delivered" | "cancelled";

export type OrderItemOut = {
  id: number;
  variant_id: number;
  quantity: number;
  price_at_purchase: string;
  variant_name: string | null;
  product_id: number | null;
  product_name: string | null;
  product_image_url: string | null;
};

export type OrderOut = {
  id: number;
  user_id: number;
  total: string;
  status: OrderStatus;
  payment_method: string;
  delivery_type: string;
  delivery_address: string | null;
  pickup_code: string | null;
  cancel_reason: string | null;
  note: string | null;
  customer_phone: string | null;
  customer_name: string | null;
  created_at: string;
  items: OrderItemOut[];
};

export function listOrders(params: { status?: OrderStatus; offset?: number; limit?: number } = {}) {
  const q = new URLSearchParams();
  if (params.status) q.set("status", params.status);
  q.set("offset", String(params.offset ?? 0));
  q.set("limit", String(params.limit ?? 50));
  return apiFetch<Page<OrderOut>>(`/admin/orders?${q}`);
}

export function updateOrderStatus(id: number, status: OrderStatus) {
  return apiFetch<OrderOut>(`/admin/orders/${id}`, { method: "PATCH", body: JSON.stringify({ status }) });
}
