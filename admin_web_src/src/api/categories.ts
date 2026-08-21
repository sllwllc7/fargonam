import { apiFetch } from "./client";
import type { CategoryOut } from "./types";

export function listCategories() {
  return apiFetch<CategoryOut[]>(`/categories`);
}

export type CategoryPayload = {
  name?: string;
  slug?: string;
  parent_id?: number | null;
  icon?: string | null;
  color?: string | null;
};

export function createCategory(payload: Required<Pick<CategoryPayload, "name" | "slug">> & CategoryPayload) {
  return apiFetch<CategoryOut>(`/categories`, { method: "POST", body: JSON.stringify(payload) });
}

export function updateCategory(id: number, payload: CategoryPayload) {
  return apiFetch<CategoryOut>(`/categories/${id}`, { method: "PATCH", body: JSON.stringify(payload) });
}

export function deleteCategory(id: number) {
  return apiFetch<null>(`/categories/${id}`, { method: "DELETE" });
}

export function reorderCategories(items: { id: number; sort_order: number }[]) {
  return apiFetch<CategoryOut[]>(`/categories/reorder`, { method: "PATCH", body: JSON.stringify({ items }) });
}

export function uploadCategoryImage(id: number, file: Blob) {
  const form = new FormData();
  form.append("file", file);
  return apiFetch<CategoryOut>(`/categories/${id}/image`, { method: "POST", body: form });
}

export function deleteCategoryImage(id: number) {
  return apiFetch<CategoryOut>(`/categories/${id}/image`, { method: "DELETE" });
}
