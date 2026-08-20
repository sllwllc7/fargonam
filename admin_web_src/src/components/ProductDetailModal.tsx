import { useState } from "react";
import {
  approveProduct,
  editApproveProduct,
  rejectProduct,
  uploadProductImage,
} from "../api/moderation";
import type { ApiError } from "../api/client";
import type { CategoryOut, ProductOut } from "../api/types";
import { effectiveFields } from "../utils/product";
import { ImageCropModal } from "./ImageCropModal";

export function ProductDetailModal({
  product: initialProduct,
  categories,
  onClose,
  onUpdated,
}: {
  product: ProductOut;
  categories: CategoryOut[];
  onClose: () => void;
  onUpdated: (p: ProductOut) => void;
}) {
  const [product, setProduct] = useState(initialProduct);
  const eff = effectiveFields(product);

  const [name, setName] = useState(eff.name);
  const [brand, setBrand] = useState(eff.brand ?? "");
  const [description, setDescription] = useState(eff.description ?? "");
  const [categoryId, setCategoryId] = useState<number | null>(eff.category_id);
  const [imageChanged, setImageChanged] = useState(false);
  const [cropSrc, setCropSrc] = useState<string | null>(null);
  const [rejecting, setRejecting] = useState(false);
  const [reason, setReason] = useState("");
  const [busy, setBusy] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  function applyUpdated(p: ProductOut) {
    setProduct(p);
    onUpdated(p);
  }

  async function handleApprove() {
    setBusy("approve");
    setError(null);
    try {
      const updated = await approveProduct(product.id);
      applyUpdated(updated);
      onClose();
    } catch (e) {
      setError((e as ApiError).message || "Xato yuz berdi");
    } finally {
      setBusy(null);
    }
  }

  async function handleEditApprove() {
    setBusy("edit-approve");
    setError(null);
    try {
      const updated = await editApproveProduct(product.id, {
        name,
        brand: brand || null,
        description: description || null,
        category_id: categoryId,
      });
      applyUpdated(updated);
      onClose();
    } catch (e) {
      setError((e as ApiError).message || "Xato yuz berdi");
    } finally {
      setBusy(null);
    }
  }

  async function handleReject() {
    if (!reason.trim()) {
      setError("Rad etish sababini yozing");
      return;
    }
    setBusy("reject");
    setError(null);
    try {
      const updated = await rejectProduct(product.id, reason.trim());
      applyUpdated(updated);
      onClose();
    } catch (e) {
      setError((e as ApiError).message || "Xato yuz berdi");
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
      setProduct(updated);
      setImageChanged(true);
      onUpdated(updated);
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

  const currentEff = effectiveFields(product);
  const displayImage = currentEff.image_url;

  return (
    <div className="fixed inset-0 z-40 flex items-center justify-center bg-black/40 p-4">
      <div className="w-full max-w-2xl max-h-[90vh] overflow-y-auto rounded-2xl bg-surface card-shadow">
        <div className="flex items-center justify-between border-b border-border px-6 py-4">
          <h2 className="text-base font-semibold" style={{ letterSpacing: "-0.2px" }}>
            Mahsulotni ko'rib chiqish
          </h2>
          <button onClick={onClose} className="text-text-muted hover:text-text-primary text-xl leading-none">
            &times;
          </button>
        </div>

        <div className="p-6 space-y-5">
          <div className="flex gap-4">
            <div className="shrink-0">
              <div className="h-28 w-28 rounded-xl overflow-hidden bg-background border border-border">
                {displayImage ? (
                  <img src={displayImage} alt={name} className="h-full w-full object-cover" />
                ) : (
                  <div className="h-full w-full flex items-center justify-center text-xs text-text-muted">
                    Rasm yo'q
                  </div>
                )}
              </div>
              <div className="mt-2 flex flex-col gap-1">
                {displayImage && (
                  <button
                    onClick={() => setCropSrc(displayImage)}
                    className="text-xs font-medium text-primary-mid hover:underline"
                  >
                    Kesish / aylantirish
                  </button>
                )}
                <button onClick={pickNewFile} className="text-xs font-medium text-primary-mid hover:underline">
                  Yangi rasm
                </button>
              </div>
              {imageChanged && (
                <p className="mt-1 text-[11px] text-success" style={{ lineHeight: 1.4 }}>
                  Rasm yangilandi — "Tasdiqlash" bilan yakunlang
                </p>
              )}
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

          <div className="rounded-xl bg-background px-4 py-3 text-xs text-text-muted grid grid-cols-2 gap-x-4 gap-y-1">
            <span>Do'kon: {product.shop_name ?? "—"}</span>
            <span>Narx: {product.price ? `${product.price} so'm` : "—"}</span>
            <span>Holat: {product.status}</span>
            <span>Zaxira: {product.total_stock}</span>
          </div>

          {product.rejected_reason && (
            <div className="rounded-xl bg-danger-tint px-4 py-3 text-sm text-danger">
              Oldingi rad sababi: {product.rejected_reason}
            </div>
          )}

          {rejecting && (
            <div>
              <label className="text-xs font-medium text-text-muted">Rad etish sababi</label>
              <textarea
                value={reason}
                onChange={(e) => setReason(e.target.value)}
                rows={2}
                autoFocus
                className="mt-1 w-full rounded-lg border border-danger/40 px-3 py-2 text-sm"
                placeholder="Sababni yozing..."
              />
            </div>
          )}

          {error && <div className="rounded-xl bg-danger-tint px-4 py-2 text-sm text-danger">{error}</div>}
        </div>

        <div className="flex items-center justify-between gap-3 border-t border-border px-6 py-4">
          {rejecting ? (
            <>
              <button
                onClick={() => setRejecting(false)}
                className="rounded-xl border border-border px-4 py-2 text-sm font-medium text-text-secondary hover:bg-background"
              >
                Orqaga
              </button>
              <button
                onClick={handleReject}
                disabled={busy !== null}
                className="rounded-xl bg-danger px-4 py-2 text-sm font-semibold text-white disabled:opacity-60"
              >
                {busy === "reject" ? "Yuborilmoqda..." : "Rad etishni tasdiqlash"}
              </button>
            </>
          ) : (
            <>
              <button
                onClick={() => setRejecting(true)}
                disabled={busy !== null}
                className="rounded-xl border border-danger/30 px-4 py-2 text-sm font-medium text-danger hover:bg-danger-tint disabled:opacity-60"
              >
                Rad etish
              </button>
              <div className="flex gap-2">
                {!imageChanged && (
                  <button
                    onClick={handleEditApprove}
                    disabled={busy !== null}
                    className="rounded-xl border border-border px-4 py-2 text-sm font-medium text-text-secondary hover:bg-background disabled:opacity-60"
                  >
                    {busy === "edit-approve" ? "Saqlanmoqda..." : "Saqlab tasdiqlash"}
                  </button>
                )}
                <button
                  onClick={handleApprove}
                  disabled={busy !== null}
                  className="btn-primary rounded-xl px-5 py-2 text-sm font-semibold disabled:opacity-60"
                >
                  {busy === "approve" ? "Tasdiqlanmoqda..." : "Tasdiqlash"}
                </button>
              </div>
            </>
          )}
        </div>
      </div>

      {cropSrc && (
        <ImageCropModal imageSrc={cropSrc} onCancel={() => setCropSrc(null)} onDone={handleCropDone} />
      )}
    </div>
  );
}
