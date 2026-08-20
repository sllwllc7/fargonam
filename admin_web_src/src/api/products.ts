import { apiFetch } from "./client";
import type { Page, ProductOut, ProductStatus, VariantOut } from "./types";

export type GalleryImage = { id: number; image_url: string; thumb_url: string | null; sort_order: number };

export function listAllProducts(params: {
  q?: string;
  category_id?: number;
  status?: ProductStatus;
  is_active?: boolean;
  offset?: number;
  limit?: number;
}) {
  const q = new URLSearchParams();
  if (params.q) q.set("q", params.q);
  if (params.category_id !== undefined) q.set("category_id", String(params.category_id));
  if (params.status) q.set("status", params.status);
  if (params.is_active !== undefined) q.set("is_active", String(params.is_active));
  q.set("offset", String(params.offset ?? 0));
  q.set("limit", String(params.limit ?? 50));
  return apiFetch<Page<ProductOut>>(`/admin/products?${q}`);
}

export type ProductCreatePayload = {
  shop_id: number;
  name: string;
  brand?: string | null;
  description?: string | null;
  category_id?: number | null;
  price: number;
  stock: number;
};

export function createProduct(payload: ProductCreatePayload) {
  return apiFetch<ProductOut>(`/products`, { method: "POST", body: JSON.stringify(payload) });
}

export function updateProductFields(
  productId: number,
  payload: Partial<{
    name: string;
    brand: string | null;
    description: string | null;
    category_id: number | null;
    is_active: boolean;
  }>,
) {
  return apiFetch<ProductOut>(`/products/${productId}`, { method: "PATCH", body: JSON.stringify(payload) });
}

export function deleteProduct(productId: number) {
  return apiFetch<{ deleted: boolean; deleted_reviews: number }>(`/products/${productId}`, { method: "DELETE" });
}

export function getProduct(productId: number) {
  return apiFetch<ProductOut>(`/products/${productId}`);
}

export function listProductImages(productId: number) {
  return apiFetch<GalleryImage[]>(`/products/${productId}/images`);
}

export function addProductImage(productId: number, file: Blob) {
  const form = new FormData();
  form.append("file", file, "image.jpg");
  return apiFetch<GalleryImage>(`/products/${productId}/images`, { method: "POST", body: form });
}

export function deleteProductImage(productId: number, imageId: number) {
  return apiFetch<null>(`/products/${productId}/images/${imageId}`, { method: "DELETE" });
}

export function reorderProductImages(productId: number, items: { id: number; sort_order: number }[]) {
  return apiFetch<GalleryImage[]>(`/products/${productId}/images/reorder`, {
    method: "PATCH",
    body: JSON.stringify({ items }),
  });
}

export function setMainProductImage(productId: number, imageId: number) {
  return apiFetch<ProductOut>(`/products/${productId}/images/${imageId}/set-main`, { method: "POST" });
}

export type VariantPayload = {
  variant_name: string;
  price: number;
  stock: number;
  sku?: string;
  attributes?: Record<string, string>;
  sort_order?: number;
};

export function createVariant(productId: number, payload: VariantPayload) {
  return apiFetch<VariantOut>(`/products/${productId}/variants`, {
    method: "POST",
    body: JSON.stringify(payload),
  });
}

export function updateVariant(
  productId: number,
  variantId: number,
  payload: Partial<{
    variant_name: string;
    price: number;
    stock: number;
    attributes: Record<string, string>;
    is_active: boolean;
    sort_order: number;
  }>,
) {
  return apiFetch<VariantOut>(`/products/${productId}/variants/${variantId}`, {
    method: "PATCH",
    body: JSON.stringify(payload),
  });
}

export function deleteVariant(productId: number, variantId: number) {
  return apiFetch<null>(`/products/${productId}/variants/${variantId}`, { method: "DELETE" });
}
