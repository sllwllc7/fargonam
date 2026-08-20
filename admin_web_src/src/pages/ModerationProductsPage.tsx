import { useEffect, useState } from "react";
import {
  bulkApproveProducts,
  listCategories,
  listModerationProducts,
} from "../api/moderation";
import type { ApiError } from "../api/client";
import type { CategoryOut, ProductOut, ProductStatus } from "../api/types";
import { ProductDetailModal } from "../components/ProductDetailModal";
import { effectiveFields, hasPendingEdit } from "../utils/product";

const TABS: { key: ProductStatus; label: string }[] = [
  { key: "pending", label: "Kutilmoqda" },
  { key: "approved", label: "Tasdiqlangan" },
  { key: "rejected", label: "Rad etilgan" },
];

function timeAgo(iso: string | null): string {
  if (!iso) return "—";
  const diffMs = Date.now() - new Date(iso).getTime();
  const minutes = Math.floor(diffMs / 60000);
  if (minutes < 1) return "hozirgina";
  if (minutes < 60) return `${minutes} daqiqa oldin`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours} soat oldin`;
  return `${Math.floor(hours / 24)} kun oldin`;
}

export function ModerationProductsPage() {
  const [tab, setTab] = useState<ProductStatus>("pending");
  const [page, setPage] = useState<{ items: ProductOut[]; total: number } | null>(null);
  const [categories, setCategories] = useState<CategoryOut[]>([]);
  const [selected, setSelected] = useState<Set<number>>(new Set());
  const [detail, setDetail] = useState<ProductOut | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [bulkBusy, setBulkBusy] = useState(false);

  async function load() {
    setLoading(true);
    setError(null);
    try {
      const res = await listModerationProducts(tab);
      setPage(res);
      setSelected(new Set());
    } catch (e) {
      setError((e as ApiError).message || "Yuklashda xato");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [tab]);

  useEffect(() => {
    listCategories().then(setCategories).catch(() => {});
  }, []);

  function toggleSelect(id: number) {
    setSelected((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  }

  async function handleBulkApprove() {
    if (selected.size === 0) return;
    setBulkBusy(true);
    try {
      await bulkApproveProducts([...selected]);
      await load();
    } catch (e) {
      setError((e as ApiError).message || "Xato yuz berdi");
    } finally {
      setBulkBusy(false);
    }
  }

  function handleUpdated(updated: ProductOut) {
    setPage((prev) => {
      if (!prev) return prev;
      if (updated.status !== tab) {
        return { ...prev, items: prev.items.filter((p) => p.id !== updated.id), total: prev.total - 1 };
      }
      return { ...prev, items: prev.items.map((p) => (p.id === updated.id ? updated : p)) };
    });
  }

  return (
    <div className="p-8">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-semibold" style={{ letterSpacing: "-0.4px" }}>
            Moderatsiya navbati
          </h1>
          <p className="mt-1 text-sm text-text-muted">Sotuvchilar yuborgan mahsulotlarni tekshiring</p>
        </div>
        {selected.size > 0 && (
          <button
            onClick={handleBulkApprove}
            disabled={bulkBusy}
            className="btn-primary rounded-xl px-4 py-2 text-sm font-semibold disabled:opacity-60"
          >
            {bulkBusy ? "Tasdiqlanmoqda..." : `Tanlanganlarni tasdiqlash (${selected.size})`}
          </button>
        )}
      </div>

      <div className="mt-6 flex gap-2">
        {TABS.map((t) => (
          <button
            key={t.key}
            onClick={() => setTab(t.key)}
            className={`rounded-full px-4 py-1.5 text-sm font-medium transition ${
              tab === t.key ? "bg-primary text-white" : "bg-surface border border-border text-text-secondary"
            }`}
          >
            {t.label}
          </button>
        ))}
      </div>

      {error && <div className="mt-4 rounded-xl bg-danger-tint px-4 py-3 text-sm text-danger">{error}</div>}

      <div className="mt-5">
        {loading ? (
          <div className="py-16 text-center text-sm text-text-muted">Yuklanmoqda...</div>
        ) : !page || page.items.length === 0 ? (
          <div className="py-16 text-center text-sm text-text-muted">Bu yerda hozircha hech narsa yo'q</div>
        ) : (
          <div className="space-y-2">
            {page.items.map((p) => {
              const eff = effectiveFields(p);
              return (
                <div
                  key={p.id}
                  className="flex items-center gap-4 rounded-xl bg-surface border border-border px-4 py-3 card-shadow"
                >
                  {tab === "pending" && (
                    <input
                      type="checkbox"
                      checked={selected.has(p.id)}
                      onChange={() => toggleSelect(p.id)}
                      className="h-4 w-4"
                    />
                  )}
                  <div className="h-12 w-12 shrink-0 rounded-lg overflow-hidden bg-background border border-border">
                    {eff.thumb_url || eff.image_url ? (
                      <img
                        src={eff.thumb_url ?? eff.image_url ?? undefined}
                        alt={eff.name}
                        className="h-full w-full object-cover"
                      />
                    ) : null}
                  </div>
                  <button className="flex-1 min-w-0 text-left" onClick={() => setDetail(p)}>
                    <div className="flex items-center gap-2">
                      <span className="truncate text-sm font-medium text-text-primary">{eff.name}</span>
                      {hasPendingEdit(p) && (
                        <span className="shrink-0 rounded-full bg-primary-light px-2 py-0.5 text-[10px] font-medium text-primary">
                          o'zgartirilgan
                        </span>
                      )}
                    </div>
                    <div className="mt-0.5 text-xs text-text-muted">
                      {p.shop_name ?? "—"} · {timeAgo(p.submitted_at)}
                    </div>
                  </button>
                  <div className="shrink-0 text-sm text-text-secondary">
                    {p.price ? `${p.price} so'm` : "—"}
                  </div>
                  <button
                    onClick={() => setDetail(p)}
                    className="shrink-0 rounded-lg border border-border px-3 py-1.5 text-xs font-medium text-text-secondary hover:bg-background"
                  >
                    Batafsil
                  </button>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {detail && (
        <ProductDetailModal
          product={detail}
          categories={categories}
          onClose={() => setDetail(null)}
          onUpdated={handleUpdated}
        />
      )}
    </div>
  );
}
