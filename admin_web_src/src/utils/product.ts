import type { ProductOut } from "../api/types";

/** Admin ko'rishi kerak bo'lgan "amaldagi" qiymat — agar `pending_edit`da
 * staged bo'lsa o'sha, aks holda LIVE (tasdiqlangan) qiymat. */
export function effectiveFields(p: ProductOut) {
  const pe = p.pending_edit ?? {};
  return {
    name: pe.name ?? p.name,
    brand: pe.brand !== undefined ? pe.brand : p.brand,
    description: pe.description !== undefined ? pe.description : p.description,
    category_id: pe.category_id !== undefined ? pe.category_id : p.category_id,
    image_url: pe.image_url !== undefined ? pe.image_url : p.image_url,
    thumb_url: pe.thumb_url !== undefined ? pe.thumb_url : p.thumb_url,
  };
}

export function hasPendingEdit(p: ProductOut): boolean {
  return !!p.pending_edit && Object.keys(p.pending_edit).length > 0;
}
