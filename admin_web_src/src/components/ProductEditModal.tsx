import { useState } from "react";
import type { ApiError } from "../api/client";
import { uploadProductImage } from "../api/moderation";
import { deleteProduct, updateProductFields } from "../api/products";
import type { CategoryOut, ProductOut, VariantOut } from "../api/types";
import { effectiveFields } from "../utils/product";
import { ImageCropModal } from "./ImageCropModal";
import { ImageGallery } from "./ImageGallery";
import { SkuEditor } from "./SkuEditor";

export function ProductEditModal({
  product: initialProduct,
  categories,
  onClose,
  onUpdated,
  onDeleted,
}: {
  product: ProductOut;
  categories: CategoryOut[];
  onClose: () => void;
  onUpdated: (p: ProductOut) => void;
  onDeleted: (id: number) => void;
}) {
  const [product, setProduct] = useState(initialProduct);
  const eff = effectiveFields(product);

  const [name, setName] = useState(eff.name);
  const [brand, setBrand] = useState(eff.brand ?? "");
  const [description, setDescription] = useState(eff.description ?? "");
  const [categoryId, setCategoryId] = useState<number | null>(eff.category_id);
  const [cropSrc, setCropSrc] = useState<string | null>(null);
  const [busy, setBusy] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  function applyUpdated(p: ProductOut) {
    setProduct(p);
    onUpdated(p);
  }

  async function handleSave() {
    setBusy("save");
    setError(null);
    try {
      const updated = await updateProductFields(product.id, {
        name,
        brand: brand || null,
        description: description || null,
        category_id: categoryId,
      });
      applyUpdated(updated);
    } catch (e) {
      setError((e as ApiError).message || "Saqlashda xato");
    } finally {
      setBusy(null);
    }
  }

  async function handleToggleActive() {
    setBusy("active");
    setError(null);
    try {
      const updated = await updateProductFields(product.id, { is_active: !product.is_active });
      applyUpdated(updated);
    } catch (e) {
      setError((e as ApiError).message || "Xato yuz berdi");
    } finally {
      setBusy(null);
    }
  }

  async function handleDelete() {
    if (!window.confirm(`"${eff.name}" mahsulotini butunlay o'chirasizmi?`)) return;
    setBusy("delete");
    setError(null);
    try {
      await deleteProduct(product.id);
      onDeleted(product.id);
      onClose();
    } catch (e) {
      setError((e as ApiError).message || "O'chirishda xato (buyurtma/savatda ishlatilgan bo'lishi mumkin)");
    } finally {
      setBusy(null);
    }
  }

  async function handleCropDone(blob: Blob) {
    setCropSrc(null);
    setBusy("image");
    setError(null);
    try {
      const updated = await uploadProductImage(product.id, blob);
      applyUpdated(updated);
    } catch (e) {
      setError((e as ApiError).message || "Rasm yuklashda xato");
    } finally {
      setBusy(null);
    }
  }

  function pickNewFile() {
    const input = document.createElement("input");
    input.type = "file";
    input.accept = "image/jpeg,image/png,image/webp";
    input.onchange = () => {
      const file = input.files?.[0];
      if (file) setCropSrc(URL.createObjectURL(file));
    };
    input.click();
  }

  function handleVariantsChange(variants: VariantOut[]) {
    setProduct((prev) => {
      const next = { ...prev, variants };
      onUpdated(next);
      return next;
    });
  }

  const currentEff = effectiveFields(product);

  return (
    <div className="fixed inset-0 z-40 flex items-center justify-center bg-black/40 p-4">
      <div className="w-full max-w-2xl max-h-[90vh] overflow-y-auto rounded-2xl bg-surface card-shadow">
        <div className="flex items-center justify-between border-b border-border px-6 py-4">
          <h2 className="text-base font-semibold">Mahsulotni tahrirlash</h2>
          <button onClick={onClose} className="text-text-muted hover:text-text-primary text-xl leading-none">
            &times;
          </button>
        </div>

        <div className="p-6 space-y-5">
          <div className="flex gap-4">
            <div className="shrink-0">
              <div className="h-28 w-28 rounded-xl overflow-hidden bg-background border border-border">
                {currentEff.image_url ? (
                  <img src={currentEff.image_url} alt={name} className="h-full w-full object-cover" />
                ) : (
                  <div className="h-full w-full flex items-center justify-center text-xs text-text-muted">
                    Rasm yo'q
                  </div>
                )}
              </div>
              <div className="mt-2 flex flex-col gap-1">
                {currentEff.image_url && (
                  <button
                    onClick={() => setCropSrc(currentEff.image_url)}
                    className="text-xs font-medium text-primary-mid hover:underline"
                  >
                    Kesish / aylantirish
                  </button>
                )}
                <button onClick={pickNewFile} className="text-xs font-medium text-primary-mid hover:underline">
                  Yangi rasm
                </button>
              </div>
            </div>

            <div className="flex-1 min-w-0 space-y-3">
              <div>
                <label className="text-xs font-medium text-text-muted">Nomi</label>
                <input
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  className="mt-1 w-full rounded-lg border border-border px-3 py-2 text-sm"
                />
              </div>
              <div>
                <label className="text-xs font-medium text-text-muted">Brend</label>
                <input
                  value={brand}
                  onChange={(e) => setBrand(e.target.value)}
                  className="mt-1 w-full rounded-lg border border-border px-3 py-2 text-sm"
                />
              </div>
              <div>
                <label className="text-xs font-medium text-text-muted">Kategoriya</label>
                <select
                  value={categoryId ?? ""}
                  onChange={(e) => setCategoryId(e.target.value ? Number(e.target.value) : null)}
                  className="mt-1 w-full rounded-lg border border-border px-3 py-2 text-sm bg-surface"
                >
                  <option value="">—</option>
                  {categories.map((c) => (
                    <option key={c.id} value={c.id}>
                      {c.name}
                    </option>
                  ))}
                </select>
              </div>
            </div>
          </div>

          <div>
            <label className="text-xs font-medium text-text-muted">Tavsif</label>
            <textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              rows={3}
              className="mt-1 w-full rounded-lg border border-border px-3 py-2 text-sm"
            />
          </div>

          <div className="flex items-center justify-between rounded-xl bg-background px-4 py-3 text-xs text-text-muted">
            <span>
              Holat: {product.status} · {product.is_active ? "Ko'rinadi" : "Yashirilgan"}
            </span>
            <button
              onClick={handleToggleActive}
              disabled={busy !== null}
              className="rounded-lg border border-border bg-surface px-3 py-1.5 text-xs font-medium hover:bg-background disabled:opacity-60"
            >
              {product.is_active ? "Yashirish" : "Ko'rsatish"}
            </button>
          </div>

          <SkuEditor productId={product.id} variants={product.variants} onVariantsChange={handleVariantsChange} />

          <ImageGallery productId={product.id} onMainImageChanged={applyUpdated} />

          {error && <div className="rounded-xl bg-danger-tint px-4 py-2 text-sm text-danger">{error}</div>}
        </div>

        <div className="flex items-center justify-between gap-3 border-t border-border px-6 py-4">
          <button
            onClick={handleDelete}
            disabled={busy !== null}
            className="rounded-xl border border-danger/30 px-4 py-2 text-sm font-medium text-danger hover:bg-danger-tint disabled:opacity-60"
          >
            {busy === "delete" ? "O'chirilmoqda..." : "Butunlay o'chirish"}
          </button>
          <button
            onClick={handleSave}
            disabled={busy !== null}
            className="btn-primary rounded-xl px-5 py-2 text-sm font-semibold disabled:opacity-60"
          >
            {busy === "save" ? "Saqlanmoqda..." : "Saqlash"}
          </button>
        </div>
      </div>

      {cropSrc && (
        <ImageCropModal imageSrc={cropSrc} onCancel={() => setCropSrc(null)} onDone={handleCropDone} />
      )}
    </div>
  );
}
