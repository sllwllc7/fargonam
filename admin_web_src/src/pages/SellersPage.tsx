import { useEffect, useState } from "react";
import type { ApiError } from "../api/client";
import { listShops, updateShop, type ShopAdminOut } from "../api/shops";
import { SellerCreateModal } from "../components/SellerCreateModal";

const STATUS_LABEL: Record<string, string> = { pending: "Kutilmoqda", approved: "Tasdiqlangan", rejected: "Rad etilgan" };

export function SellersPage() {
  const [shops, setShops] = useState<ShopAdminOut[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [creating, setCreating] = useState(false);
  const [busyId, setBusyId] = useState<number | null>(null);

  async function load() {
    setLoading(true);
    setError(null);
    try {
      const page = await listShops();
      setShops(page.items);
    } catch (e) {
      setError((e as ApiError).message || "Yuklashda xato");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load();
  }, []);

  async function handleToggleTrusted(s: ShopAdminOut) {
    setBusyId(s.id);
    try {
      const updated = await updateShop(s.id, { is_trusted: !s.is_trusted });
      setShops((prev) => prev.map((x) => (x.id === s.id ? updated : x)));
    } catch (e) {
      setError((e as ApiError).message || "Xato yuz berdi");
    } finally {
      setBusyId(null);
    }
  }

  async function handleToggleActive(s: ShopAdminOut) {
    setBusyId(s.id);
    try {
      const updated = await updateShop(s.id, { is_active: !s.is_active });
      setShops((prev) => prev.map((x) => (x.id === s.id ? updated : x)));
    } catch (e) {
      setError((e as ApiError).message || "Xato yuz berdi");
    } finally {
      setBusyId(null);
    }
  }

  function handleCreated(s: ShopAdminOut) {
    setShops((prev) => [s, ...prev]);
  }

  return (
    <div className="p-8">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-semibold" style={{ letterSpacing: "-0.4px" }}>
            Sotuvchilar
          </h1>
          <p className="mt-1 text-sm text-text-muted">{shops.length} ta do'kon</p>
        </div>
        <button onClick={() => setCreating(true)} className="btn-primary rounded-xl px-4 py-2 text-sm font-semibold">
          + Yangi sotuvchi
        </button>
      </div>

      {error && <div className="mt-4 rounded-xl bg-danger-tint px-4 py-3 text-sm text-danger">{error}</div>}

      <div className="mt-5 space-y-2">
        {loading ? (
          <div className="py-16 text-center text-sm text-text-muted">Yuklanmoqda...</div>
        ) : (
          shops.map((s) => (
            <div key={s.id} className="flex items-center gap-4 rounded-xl bg-surface border border-border px-4 py-3 card-shadow">
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2">
                  <span className="text-sm font-medium text-text-primary">{s.name}</span>
                  <span className="rounded-full bg-background px-2 py-0.5 text-[10px] text-text-muted">
                    {STATUS_LABEL[s.status] ?? s.status}
                  </span>
                  {s.is_trusted && (
                    <span className="rounded-full bg-success-tint px-2 py-0.5 text-[10px] text-success">Ishonchli</span>
                  )}
                  {!s.is_active && <span className="rounded-full bg-danger-tint px-2 py-0.5 text-[10px] text-danger">Bloklangan</span>}
                </div>
                <div className="mt-0.5 text-xs text-text-muted">
                  {s.owner_phone ?? "telefon yo'q"} · {s.product_count} ta mahsulot
                </div>
              </div>
              <button
                onClick={() => handleToggleTrusted(s)}
                disabled={busyId === s.id}
                className="rounded-lg border border-border px-3 py-1.5 text-xs font-medium hover:bg-background disabled:opacity-60"
              >
                {s.is_trusted ? "Ishonchni olib tashlash" : "Ishonchli qilish"}
              </button>
              <button
                onClick={() => handleToggleActive(s)}
                disabled={busyId === s.id}
                className="rounded-lg border border-danger/30 px-3 py-1.5 text-xs font-medium text-danger hover:bg-danger-tint disabled:opacity-60"
              >
                {s.is_active ? "Bloklash" : "Blokdan chiqarish"}
              </button>
            </div>
          ))
        )}
      </div>

      {creating && <SellerCreateModal onClose={() => setCreating(false)} onCreated={handleCreated} />}
    </div>
  );
}
