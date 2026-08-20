import { useState } from "react";
import type { ApiError } from "../api/client";
import { approveKit, createKit, deleteKit, updateKit, type KitItemPayload, type KitOut } from "../api/kits";
import { listAllProducts } from "../api/products";
import type { ProductOut } from "../api/types";

type LocalItem = { variant_id: number; quantity: number; label: string; price: number };

export function KitForm({
  kit,
  shopId,
  onClose,
  onSaved,
  onDeleted,
}: {
  kit: KitOut | null;
  shopId: number;
  onClose: () => void;
  onSaved: (k: KitOut) => void;
  onDeleted: (id: number) => void;
}) {
  const [name, setName] = useState(kit?.name ?? "");
  const [gradeLevel, setGradeLevel] = useState(kit?.grade_level ?? "");
  const [description, setDescription] = useState(kit?.description ?? "");
  const [items, setItems] = useState<LocalItem[]>(
    (kit?.items ?? []).map((it) => ({
      variant_id: it.variant_id,
      quantity: it.quantity,
      label: `${it.product_name ?? "?"} — ${it.variant_name ?? ""}`,
      price: it.price ?? 0,
    })),
  );
  const [search, setSearch] = useState("");
  const [results, setResults] = useState<ProductOut[]>([]);
  const [busy, setBusy] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function handleSearch(value: string) {
    setSearch(value);
    if (!value.trim()) {
      setResults([]);
      return;
    }
    try {
      const res = await listAllProducts({ q: value, limit: 8 });
      setResults(res.items);
    } catch {
      setResults([]);
    }
  }

  function addItem(product: ProductOut, variantId: number) {
    const variant = product.variants.find((v) => v.id === variantId);
    if (!variant) return;
    if (items.some((it) => it.variant_id === variantId)) return;
    setItems((prev) => [
      ...prev,
      { variant_id: variantId, quantity: 1, label: `${product.name} — ${variant.variant_name}`, price: variant.price },
    ]);
    setSearch("");
    setResults([]);
  }

  function removeItem(variantId: number) {
    setItems((prev) => prev.filter((it) => it.variant_id !== variantId));
  }

  function setQty(variantId: number, qty: number) {
    setItems((prev) => prev.map((it) => (it.variant_id === variantId ? { ...it, quantity: qty } : it)));
  }

  async function handleSave() {
    if (!name.trim() || items.length === 0) {
      setError("Nom va kamida bitta mahsulot kerak");
      return;
    }
    setBusy("save");
    setError(null);
    const payloadItems: KitItemPayload[] = items.map((it) => ({ variant_id: it.variant_id, quantity: it.quantity }));
    try {
      const saved = kit
        ? await updateKit(kit.id, {
            name,
            grade_level: gradeLevel || null,
            description: description || null,
            items: payloadItems,
          })
        : await createKit({ shop_id: shopId, name, grade_level: gradeLevel || null, description: description || null, items: payloadItems });
      onSaved(saved);
      onClose();
    } catch (e) {
      setError((e as ApiError).message || "Saqlashda xato");
    } finally {
      setBusy(null);
    }
  }

  async function handleApprove() {
    if (!kit) return;
    setBusy("approve");
    setError(null);
    try {
      const saved = await approveKit(kit.id);
      onSaved(saved);
    } catch (e) {
      setError((e as ApiError).message || "Tasdiqlashda xato");
    } finally {
      setBusy(null);
    }
  }

  async function handleToggleActive() {
    if (!kit) return;
    setBusy("active");
    setError(null);
    try {
      const saved = await updateKit(kit.id, { is_active: !kit.is_active });
      onSaved(saved);
    } catch (e) {
      setError((e as ApiError).message || "Xato yuz berdi");
    } finally {
      setBusy(null);
    }
  }

  async function handleDelete() {
    if (!kit) return;
    if (!window.confirm(`"${kit.name}" to'plamini o'chirasizmi?`)) return;
    setBusy("delete");
    setError(null);
    try {
      await deleteKit(kit.id);
      onDeleted(kit.id);
      onClose();
    } catch (e) {
      setError((e as ApiError).message || "O'chirishda xato");
    } finally {
      setBusy(null);
    }
  }

  const total = items.reduce((sum, it) => sum + it.price * it.quantity, 0);

  return (
    <div className="fixed inset-0 z-40 flex items-center justify-center bg-black/40 p-4">
      <div className="w-full max-w-xl max-h-[90vh] overflow-y-auto rounded-2xl bg-surface card-shadow">
        <div className="flex items-center justify-between border-b border-border px-6 py-4">
          <h2 className="text-base font-semibold">{kit ? "To'plamni tahrirlash" : "Yangi to'plam"}</h2>
          <button onClick={onClose} className="text-text-muted hover:text-text-primary text-xl leading-none">
            &times;
          </button>
        </div>
        <div className="p-6 space-y-4">
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-xs font-medium text-text-muted">Nomi</label>
              <input
                value={name}
                onChange={(e) => setName(e.target.value)}
                className="mt-1 w-full rounded-lg border border-border px-3 py-2 text-sm"
              />
            </div>
            <div>
              <label className="text-xs font-medium text-text-muted">Sinf</label>
              <input
                value={gradeLevel}
                onChange={(e) => setGradeLevel(e.target.value)}
                placeholder="masalan: 5"
                className="mt-1 w-full rounded-lg border border-border px-3 py-2 text-sm"
              />
            </div>
          </div>
          <div>
            <label className="text-xs font-medium text-text-muted">Tavsif</label>
            <textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              rows={2}
              className="mt-1 w-full rounded-lg border border-border px-3 py-2 text-sm"
            />
          </div>

          {kit && (
            <div className="flex items-center justify-between rounded-xl bg-background px-4 py-3 text-xs text-text-muted">
              <span>
                Holat: {kit.status} · {kit.is_active ? "Ko'rinadi" : "Yashirilgan"}
              </span>
              <div className="flex gap-2">
                {kit.status !== "approved" && (
                  <button
                    onClick={handleApprove}
                    disabled={busy !== null}
                    className="rounded-lg border border-border bg-surface px-3 py-1.5 text-xs font-medium hover:bg-background"
                  >
                    Tasdiqlash
                  </button>
                )}
                <button
                  onClick={handleToggleActive}
                  disabled={busy !== null}
                  className="rounded-lg border border-border bg-surface px-3 py-1.5 text-xs font-medium hover:bg-background"
                >
                  {kit.is_active ? "Yashirish" : "Ko'rsatish"}
                </button>
              </div>
            </div>
          )}

          <div>
            <label className="text-xs font-medium text-text-muted">Mahsulot qo'shish</label>
            <input
              value={search}
              onChange={(e) => handleSearch(e.target.value)}
              placeholder="Mahsulot nomini qidiring..."
              className="mt-1 w-full rounded-lg border border-border px-3 py-2 text-sm"
            />
            {results.length > 0 && (
              <div className="mt-1 max-h-48 overflow-y-auto rounded-lg border border-border">
                {results.map((p) => (
                  <div key={p.id} className="border-b border-border last:border-0 px-3 py-2">
                    <div className="text-xs font-medium text-text-secondary">{p.name}</div>
                    <div className="mt-1 flex flex-wrap gap-1">
                      {p.variants.map((v) => (
                        <button
                          key={v.id}
                          onClick={() => addItem(p, v.id)}
                          className="rounded-full border border-border px-2 py-0.5 text-[11px] hover:bg-primary-light"
                        >
                          {v.variant_name} · {v.price} so'm
                        </button>
                      ))}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>

          <div className="rounded-xl border border-border overflow-hidden">
            {items.length === 0 ? (
              <p className="px-3 py-3 text-xs text-text-muted">Hali mahsulot qo'shilmagan</p>
            ) : (
              items.map((it) => (
                <div key={it.variant_id} className="flex items-center gap-2 border-b border-border last:border-0 px-3 py-2 text-xs">
                  <span className="flex-1 min-w-0 truncate">{it.label}</span>
                  <input
                    type="number"
                    min={1}
                    value={it.quantity}
                    onChange={(e) => setQty(it.variant_id, Math.max(1, Number(e.target.value)))}
                    className="w-14 rounded border border-border px-1.5 py-1 text-right"
                  />
                  <span className="w-20 text-right text-text-muted">{it.price * it.quantity} so'm</span>
                  <button onClick={() => removeItem(it.variant_id)} className="text-danger">
                    ✕
                  </button>
                </div>
              ))
            )}
            {items.length > 0 && (
              <div className="flex justify-between bg-background px-3 py-2 text-xs font-medium">
                <span>Jami</span>
                <span>{total} so'm</span>
              </div>
            )}
          </div>

          {error && <div className="rounded-lg bg-danger-tint px-3 py-2 text-xs text-danger">{error}</div>}
        </div>
        <div className="flex items-center justify-between gap-3 border-t border-border px-6 py-4">
          {kit ? (
            <button
              onClick={handleDelete}
              disabled={busy !== null}
              className="rounded-xl border border-danger/30 px-4 py-2 text-sm font-medium text-danger hover:bg-danger-tint disabled:opacity-60"
            >
              O'chirish
            </button>
          ) : (
            <span />
          )}
          <button
            onClick={handleSave}
            disabled={busy !== null}
            className="btn-primary rounded-xl px-5 py-2 text-sm font-semibold disabled:opacity-60"
          >
            {busy === "save" ? "Saqlanmoqda..." : "Saqlash"}
          </button>
        </div>
      </div>
    </div>
  );
}
