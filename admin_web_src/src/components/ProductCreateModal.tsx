import { useEffect, useState } from "react";
import type { ApiError } from "../api/client";
import { createProduct } from "../api/products";
import { listShops, type ShopAdminOut } from "../api/shops";
import type { CategoryOut, ProductOut } from "../api/types";

export function ProductCreateModal({
  categories,
  onClose,
  onCreated,
}: {
  categories: CategoryOut[];
  onClose: () => void;
  onCreated: (p: ProductOut) => void;
}) {
  const [shops, setShops] = useState<ShopAdminOut[]>([]);
  const [shopId, setShopId] = useState<number | "">("");
  const [name, setName] = useState("");
  const [brand, setBrand] = useState("");
  const [description, setDescription] = useState("");
  const [categoryId, setCategoryId] = useState<number | "">("");
  const [price, setPrice] = useState("");
  const [stock, setStock] = useState("0");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    listShops().then((page) => {
      setShops(page.items);
      if (page.items.length === 1) setShopId(page.items[0].id);
    });
  }, []);

  async function handleCreate() {
    if (!shopId || !name.trim() || !price) {
      setError("Do'kon, nom va narx to'ldirilishi shart");
      return;
    }
    setBusy(true);
    setError(null);
    try {
      const created = await createProduct({
        shop_id: Number(shopId),
        name: name.trim(),
        brand: brand || null,
        description: description || null,
        category_id: categoryId ? Number(categoryId) : null,
        price: Number(price),
        stock: Number(stock),
      });
      onCreated(created);
      onClose();
    } catch (e) {
      setError((e as ApiError).message || "Yaratishda xato");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="fixed inset-0 z-40 flex items-center justify-center bg-black/40 p-4">
      <div className="w-full max-w-md rounded-2xl bg-surface card-shadow">
        <div className="flex items-center justify-between border-b border-border px-6 py-4">
          <h2 className="text-base font-semibold">Yangi mahsulot</h2>
          <button onClick={onClose} className="text-text-muted hover:text-text-primary text-xl leading-none">
            &times;
          </button>
        </div>
        <div className="p-6 space-y-4">
          <div>
            <label className="text-xs font-medium text-text-muted">Do'kon</label>
            <select
              value={shopId}
              onChange={(e) => setShopId(e.target.value ? Number(e.target.value) : "")}
              className="mt-1 w-full rounded-lg border border-border px-3 py-2 text-sm bg-surface"
            >
              <option value="">— tanlang —</option>
              {shops.map((s) => (
                <option key={s.id} value={s.id}>
                  {s.name}
                </option>
              ))}
            </select>
          </div>
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
              value={categoryId}
              onChange={(e) => setCategoryId(e.target.value ? Number(e.target.value) : "")}
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
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-xs font-medium text-text-muted">Narx</label>
              <input
                value={price}
                onChange={(e) => setPrice(e.target.value)}
                inputMode="numeric"
                className="mt-1 w-full rounded-lg border border-border px-3 py-2 text-sm"
              />
            </div>
            <div>
              <label className="text-xs font-medium text-text-muted">Zaxira</label>
              <input
                value={stock}
                onChange={(e) => setStock(e.target.value)}
                inputMode="numeric"
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
          {error && <div className="rounded-lg bg-danger-tint px-3 py-2 text-xs text-danger">{error}</div>}
        </div>
        <div className="flex justify-end gap-2 border-t border-border px-6 py-4">
          <button
            onClick={onClose}
            className="rounded-xl border border-border px-4 py-2 text-sm font-medium text-text-secondary hover:bg-background"
          >
            Bekor qilish
          </button>
          <button
            onClick={handleCreate}
            disabled={busy}
            className="btn-primary rounded-xl px-5 py-2 text-sm font-semibold disabled:opacity-60"
          >
            {busy ? "Yaratilmoqda..." : "Yaratish"}
          </button>
        </div>
      </div>
    </div>
  );
}
