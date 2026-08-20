import { useEffect, useState } from "react";
import type { ApiError } from "../api/client";
import { listOrders, type OrderOut, type OrderStatus } from "../api/orders";
import type { Page } from "../api/types";
import { OrderDetailModal } from "../components/OrderDetailModal";

const STATUS_LABEL: Record<OrderStatus, string> = {
  pending: "Qabul qilindi",
  paid: "To'landi",
  preparing: "Tayyorlanmoqda",
  ready: "Tayyor",
  shipped: "Kuryerda",
  delivered: "Yetkazildi",
  cancelled: "Bekor qilindi",
};

export function OrdersPage() {
  const [status, setStatus] = useState<OrderStatus | "">("");
  const [page, setPage] = useState<Page<OrderOut> | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [detail, setDetail] = useState<OrderOut | null>(null);

  async function load() {
    setLoading(true);
    setError(null);
    try {
      setPage(await listOrders({ status: status || undefined }));
    } catch (e) {
      setError((e as ApiError).message || "Yuklashda xato");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [status]);

  function handleUpdated(updated: OrderOut) {
    setPage((prev) => (prev ? { ...prev, items: prev.items.map((o) => (o.id === updated.id ? updated : o)) } : prev));
  }

  return (
    <div className="p-8">
      <div>
        <h1 className="text-xl font-semibold" style={{ letterSpacing: "-0.4px" }}>
          Buyurtmalar
        </h1>
        <p className="mt-1 text-sm text-text-muted">{page ? `${page.total} ta buyurtma` : "..."}</p>
      </div>

      <div className="mt-5 flex flex-wrap gap-2">
        <button
          onClick={() => setStatus("")}
          className={`rounded-full px-4 py-1.5 text-sm font-medium ${status === "" ? "bg-primary text-white" : "bg-surface border border-border text-text-secondary"}`}
        >
          Hammasi
        </button>
        {Object.entries(STATUS_LABEL).map(([k, v]) => (
          <button
            key={k}
            onClick={() => setStatus(k as OrderStatus)}
            className={`rounded-full px-4 py-1.5 text-sm font-medium ${status === k ? "bg-primary text-white" : "bg-surface border border-border text-text-secondary"}`}
          >
            {v}
          </button>
        ))}
      </div>

      {error && <div className="mt-4 rounded-xl bg-danger-tint px-4 py-3 text-sm text-danger">{error}</div>}

      <div className="mt-5 space-y-2">
        {loading ? (
          <div className="py-16 text-center text-sm text-text-muted">Yuklanmoqda...</div>
        ) : !page || page.items.length === 0 ? (
          <div className="py-16 text-center text-sm text-text-muted">Buyurtma yo'q</div>
        ) : (
          page.items.map((o) => (
            <button
              key={o.id}
              onClick={() => setDetail(o)}
              className="flex w-full items-center gap-4 rounded-xl bg-surface border border-border px-4 py-3 text-left card-shadow hover:bg-background/50"
            >
              <div className="flex-1 min-w-0">
                <div className="text-sm font-medium text-text-primary">
                  #{o.id} · {o.customer_name ?? "—"}
                </div>
                <div className="mt-0.5 text-xs text-text-muted">
                  {STATUS_LABEL[o.status]} · {new Date(o.created_at).toLocaleString("uz-UZ")}
                </div>
              </div>
              <div className="shrink-0 text-sm text-text-secondary">{o.total} so'm</div>
            </button>
          ))
        )}
      </div>

      {detail && <OrderDetailModal order={detail} onClose={() => setDetail(null)} onUpdated={handleUpdated} />}
    </div>
  );
}
