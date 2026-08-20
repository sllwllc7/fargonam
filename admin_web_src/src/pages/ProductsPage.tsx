import { useEffect, useState } from "react";
import type { ApiError } from "../api/client";
import { listCategories } from "../api/moderation";
import { listAllProducts } from "../api/products";
import type { CategoryOut, Page, ProductOut, ProductStatus } from "../api/types";
import { ProductCreateModal } from "../components/ProductCreateModal";
import { ProductEditModal } from "../components/ProductEditModal";
import { effectiveFields } from "../utils/product";

const STATUS_LABEL: Record<ProductStatus, string> = {
  draft: "Qoralama",
  pending: "Kutilmoqda",
  approved: "Tasdiqlangan",
  rejected: "Rad etilgan",
};

export function ProductsPage() {
  const [categories, setCategories] = useState<CategoryOut[]>([]);
  const [q, setQ] = useState("");
  const [categoryId, setCategoryId] = useState<number | "">("");
  const [status, setStatus] = useState<ProductStatus | "">("");
  const [page, setPage] = useState<Page<ProductOut> | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [editing, setEditing] = useState<ProductOut | null>(null);
  const [creating, setCreating] = useState(false);

  async function load() {
    setLoading(true);
    setError(null);
    try {
      const res = await listAllProducts({
        q: q || undefined,
        category_id: categoryId || undefined,
        status: status || undefined,
      });
      setPage(res);
    } catch (e) {
      setError((e as ApiError).message || "Yuklashda xato");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    listCategories().then(setCategories).catch(() => {});
  }, []);

  useEffect(() => {
    const t = setTimeout(load, 300);
    return () => clearTimeout(t);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [q, categoryId, status]);

  function handleUpdated(updated: ProductOut) {
    setPage((prev) => (prev ? { ...prev, items: prev.items.map((p) => (p.id === updated.id ? updated : p)) } : prev));
  }

  function handleDeleted(id: number) {
    setPage((prev) => (prev ? { ...prev, items: prev.items.filter((p) => p.id !== id), total: prev.total - 1 } : prev));
  }

  function handleCreated(created: ProductOut) {
    setPage((prev) => (prev ? { ...prev, items: [created, ...prev.items], total: prev.total + 1 } : prev));
    setEditing(created);
  }

  return (
    <div className="p-8">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-semibold" style={{ letterSpacing: "-0.4px" }}>
            Mahsulotlar
          </h1>
          <p className="mt-1 text-sm text-text-muted">{page ? `${page.total} ta mahsulot` : "..."}</p>
        </div>
        <button onClick={() => setCreating(true)} className="btn-primary rounded-xl px-4 py-2 text-sm font-semibold">
          + Yangi mahsulot
        </button>
      </div>

      <div className="mt-5 flex flex-wrap gap-2">
        <input
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder="Qidirish..."
          className="w-56 rounded-lg border border-border bg-surface px-3 py-2 text-sm"
        />
        <select
          value={categoryId}
          onChange={(e) => setCategoryId(e.target.value ? Number(e.target.value) : "")}
          className="rounded-lg border border-border bg-surface px-3 py-2 text-sm"
        >
          <option value="">Barcha kategoriyalar</option>
          {categories.map((c) => (
            <option key={c.id} value={c.id}>
              {c.name}
            </option>
          ))}
        </select>
        <select
          value={status}
          onChange={(e) => setStatus(e.target.value as ProductStatus | "")}
          className="rounded-lg border border-border bg-surface px-3 py-2 text-sm"
        >
          <option value="">Barcha holatlar</option>
          {Object.entries(STATUS_LABEL).map(([k, v]) => (
            <option key={k} value={k}>
              {v}
            </option>
          ))}
        </select>
      </div>

      {error && <div className="mt-4 rounded-xl bg-danger-tint px-4 py-3 text-sm text-danger">{error}</div>}

      <div className="mt-5 space-y-2">
        {loading ? (
          <div className="py-16 text-center text-sm text-text-muted">Yuklanmoqda...</div>
        ) : !page || page.items.length === 0 ? (
          <div className="py-16 text-center text-sm text-text-muted">Hech narsa topilmadi</div>
        ) : (
          page.items.map((p) => {
            const eff = effectiveFields(p);
            return (
              <button
                key={p.id}
                onClick={() => setEditing(p)}
                className="flex w-full items-center gap-4 rounded-xl bg-surface border border-border px-4 py-3 text-left card-shadow hover:bg-background/50"
              >
                <div className="h-12 w-12 shrink-0 rounded-lg overflow-hidden bg-background border border-border">
                  {eff.thumb_url || eff.image_url ? (
                    <img src={eff.thumb_url ?? eff.image_url ?? undefined} className="h-full w-full object-cover" alt="" />
                  ) : null}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <span className="truncate text-sm font-medium text-text-primary">{eff.name}</span>
                    {!p.is_active && (
                      <span className="shrink-0 rounded-full bg-background px-2 py-0.5 text-[10px] text-text-muted">
                        Yashirilgan
                      </span>
                    )}
                  </div>
                  <div className="mt-0.5 text-xs text-text-muted">
                    {p.shop_name ?? "—"} · {STATUS_LABEL[p.status]}
                  </div>
                </div>
                <div className="shrink-0 text-sm text-text-secondary">
                  {p.min_price === p.max_price ? `${p.price ?? "—"} so'm` : `${p.min_price}–${p.max_price} so'm`}
                </div>
                <div className="shrink-0 text-xs text-text-muted">{p.total_stock} dona</div>
              </button>
            );
          })
        )}
      </div>

      {editing && (
        <ProductEditModal
          product={editing}
          categories={categories}
          onClose={() => setEditing(null)}
          onUpdated={handleUpdated}
          onDeleted={handleDeleted}
        />
      )}
      {creating && (
        <ProductCreateModal categories={categories} onClose={() => setCreating(false)} onCreated={handleCreated} />
      )}
    </div>
  );
}
