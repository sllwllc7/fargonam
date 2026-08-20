import { apiFetch } from "./client";
import type { CategoryOut, Page, ProductOut, ProductStatus } from "./types";

export function listModerationProducts(status: ProductStatus, offset = 0, limit = 50) {
  const q = new URLSearchParams({ status, offset: String(offset), limit: String(limit) });
  return apiFetch<Page<ProductOut>>(`/admin/moderation/products?${q}`);
}

export function approveProduct(id: number) {
  return apiFetch<ProductOut>(`/admin/moderation/products/${id}/approve`, { method: "POST" });
}

export function rejectProduct(id: number, reason: string) {
  return apiFetch<ProductOut>(`/admin/moderation/products/${id}/reject`, {
    method: "POST",
    body: JSON.stringify({ reason }),
  });
}

export type ProductDirectEdit = {
  name?: string;
  brand?: string | null;
  description?: string | null;
  category_id?: number | null;
  image_url?: string | null;
};

export function editApproveProduct(id: number, payload: ProductDirectEdit) {
  return apiFetch<ProductOut>(`/admin/moderation/products/${id}/edit-approve`, {
    method: "POST",
    body: JSON.stringify(payload),
  });
}

export function bulkApproveProducts(ids: number[]) {
  return apiFetch<{ approved: number }>(`/admin/moderation/products/bulk-approve`, {
    method: "POST",
    body: JSON.stringify({ ids }),
  });
}

export function uploadProductImage(id: number, file: Blob) {
  const form = new FormData();
  form.append("file", file, "image.jpg");
  return apiFetch<ProductOut>(`/products/${id}/image`, { method: "POST", body: form });
}

export function listCategories() {
  return apiFetch<CategoryOut[]>(`/categories`);
}
