import { useState } from "react";
import type { ApiError } from "../api/client";
import { createSeller, type ShopAdminOut } from "../api/shops";

export function SellerCreateModal({
  onClose,
  onCreated,
}: {
  onClose: () => void;
  onCreated: (s: ShopAdminOut) => void;
}) {
  const [fullName, setFullName] = useState("");
  const [telegramId, setTelegramId] = useState("");
  const [phone, setPhone] = useState("");
  const [shopName, setShopName] = useState("");
  const [shopDescription, setShopDescription] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleCreate() {
    if (!fullName.trim() || !telegramId.trim() || !shopName.trim()) {
      setError("F.I.Sh, Telegram ID va do'kon nomi to'ldirilishi shart");
      return;
    }
    setBusy(true);
    setError(null);
    try {
      const created = await createSeller({
        full_name: fullName.trim(),
        telegram_id: Number(telegramId),
        phone: phone || null,
        shop_name: shopName.trim(),
        shop_description: shopDescription || null,
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
          <h2 className="text-base font-semibold">Yangi sotuvchi</h2>
          <button onClick={onClose} className="text-text-muted hover:text-text-primary text-xl leading-none">
            &times;
          </button>
        </div>
        <div className="p-6 space-y-4">
          <div>
            <label className="text-xs font-medium text-text-muted">F.I.Sh</label>
            <input
              value={fullName}
              onChange={(e) => setFullName(e.target.value)}
              className="mt-1 w-full rounded-lg border border-border px-3 py-2 text-sm"
            />
          </div>
          <div>
            <label className="text-xs font-medium text-text-muted">Telegram ID (raqam)</label>
            <input
              value={telegramId}
              onChange={(e) => setTelegramId(e.target.value)}
              inputMode="numeric"
              placeholder="masalan: 123456789"
              className="mt-1 w-full rounded-lg border border-border px-3 py-2 text-sm"
            />
            <p className="mt-1 text-[11px] text-text-muted">
              Sotuvchi keyin shu ID bilan Telegram orqali kirsa, avtomatik shu hisobga ulanadi.
            </p>
          </div>
          <div>
            <label className="text-xs font-medium text-text-muted">Telefon (ixtiyoriy)</label>
            <input
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              placeholder="+998 90 123 45 67"
              className="mt-1 w-full rounded-lg border border-border px-3 py-2 text-sm"
            />
          </div>
          <div>
            <label className="text-xs font-medium text-text-muted">Do'kon nomi</label>
            <input
              value={shopName}
              onChange={(e) => setShopName(e.target.value)}
              className="mt-1 w-full rounded-lg border border-border px-3 py-2 text-sm"
            />
          </div>
          <div>
            <label className="text-xs font-medium text-text-muted">Do'kon tavsifi</label>
            <textarea
              value={shopDescription}
              onChange={(e) => setShopDescription(e.target.value)}
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
