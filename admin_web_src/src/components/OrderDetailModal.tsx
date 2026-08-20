import { useState } from "react";
import type { ApiError } from "../api/client";
import { updateOrderStatus, type OrderOut, type OrderStatus } from "../api/orders";

const STATUS_LABEL: Record<OrderStatus, string> = {
  pending: "Qabul qilindi",
  paid: "To'landi",
  preparing: "Tayyorlanmoqda",
  ready: "Tayyor",
  shipped: "Kuryerda",
  delivered: "Yetkazildi",
  cancelled: "Bekor qilindi",
};

export function OrderDetailModal({
  order: initialOrder,
  onClose,
  onUpdated,
}: {
  order: OrderOut;
  onClose: () => void;
  onUpdated: (o: OrderOut) => void;
}) {
  const [order, setOrder] = useState(initialOrder);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleChangeStatus(status: OrderStatus) {
    setBusy(true);
    setError(null);
    try {
      const updated = await updateOrderStatus(order.id, status);
      setOrder(updated);
      onUpdated(updated);
    } catch (e) {
      setError((e as ApiError).message || "Holatni o'zgartirishda xato");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="fixed inset-0 z-40 flex items-center justify-center bg-black/40 p-4">
      <div className="w-full max-w-lg max-h-[90vh] overflow-y-auto rounded-2xl bg-surface card-shadow">
        <div className="flex items-center justify-between border-b border-border px-6 py-4">
          <h2 className="text-base font-semibold">Buyurtma #{order.id}</h2>
          <button onClick={onClose} className="text-text-muted hover:text-text-primary text-xl leading-none">
            &times;
          </button>
        </div>
        <div className="p-6 space-y-4">
          <div className="grid grid-cols-2 gap-x-4 gap-y-1 rounded-xl bg-background px-4 py-3 text-xs text-text-muted">
            <span>Xaridor: {order.customer_name ?? "—"}</span>
            <span>Telefon: {order.customer_phone ?? "—"}</span>
            <span>To'lov: {order.payment_method}</span>
            <span>Yetkazish: {order.delivery_type}</span>
            <span className="col-span-2">Manzil: {order.delivery_address ?? "—"}</span>
            {order.pickup_code && <span>Kod: {order.pickup_code}</span>}
            {order.note && <span className="col-span-2">Izoh: {order.note}</span>}
            {order.cancel_reason && <span className="col-span-2 text-danger">Bekor sababi: {order.cancel_reason}</span>}
          </div>

          <div className="rounded-xl border border-border overflow-hidden">
            {order.items.map((it) => (
              <div key={it.id} className="flex items-center justify-between border-b border-border last:border-0 px-3 py-2 text-xs">
                <span>{it.product_name ?? "?"} — {it.variant_name}</span>
                <span className="text-text-muted">
                  {it.quantity} × {it.price_at_purchase} so'm
                </span>
              </div>
            ))}
            <div className="flex justify-between bg-background px-3 py-2 text-xs font-medium">
              <span>Jami</span>
              <span>{order.total} so'm</span>
            </div>
          </div>

          <div>
            <label className="text-xs font-medium text-text-muted">Holat</label>
            <select
              value={order.status}
              onChange={(e) => handleChangeStatus(e.target.value as OrderStatus)}
              disabled={busy}
              className="mt-1 w-full rounded-lg border border-border px-3 py-2 text-sm bg-surface disabled:opacity-60"
            >
              {Object.entries(STATUS_LABEL).map(([k, v]) => (
                <option key={k} value={k}>
                  {v}
                </option>
              ))}
            </select>
          </div>

          {order.status !== "cancelled" && order.status !== "delivered" && (
            <button
              onClick={() => handleChangeStatus("cancelled")}
              disabled={busy}
              className="w-full rounded-xl border border-danger/30 px-4 py-2 text-sm font-medium text-danger hover:bg-danger-tint disabled:opacity-60"
            >
              Buyurtmani bekor qilish
            </button>
          )}

          {error && <div className="rounded-lg bg-danger-tint px-3 py-2 text-xs text-danger">{error}</div>}
        </div>
      </div>
    </div>
  );
}
