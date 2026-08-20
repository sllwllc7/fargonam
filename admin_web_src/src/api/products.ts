import { apiFetch } from "./client";
import type { ProductOut, VariantOut } from "./types";

export type GalleryImage = { id: number; image_url: string; thumb_url: string | null; sort_order: number };

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
