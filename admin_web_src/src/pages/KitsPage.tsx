import { useEffect, useState } from "react";
import type { ApiError } from "../api/client";
import { listKits, type KitOut } from "../api/kits";
import { KitForm } from "../components/KitForm";

const SHOP_ID = 1;

export function KitsPage() {
  const [kits, setKits] = useState<KitOut[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [editing, setEditing] = useState<KitOut | null>(null);
  const [creating, setCreating] = useState(false);

  async function load() {
    setLoading(true);
    setError(null);
    try {
      setKits(await listKits(SHOP_ID));
    } catch (e) {
      setError((e as ApiError).message || "Yuklashda xato");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load();
  }, []);

  function handleSaved(saved: KitOut) {
    setKits((prev) => {
      const exists = prev.some((k) => k.id === saved.id);
      return exists ? prev.map((k) => (k.id === saved.id ? saved : k)) : [saved, ...prev];
    });
    setEditing(saved);
  }

  function handleDeleted(id: number) {
    setKits((prev) => prev.filter((k) => k.id !== id));
  }

  return (
    <div className="p-8">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-semibold" style={{ letterSpacing: "-0.4px" }}>
            To'plamlar
          </h1>
          <p className="mt-1 text-sm text-text-muted">{kits.length} ta to'plam</p>
        </div>
        <button onClick={() => setCreating(true)} className="btn-primary rounded-xl px-4 py-2 text-sm font-semibold">
          + Yangi to'plam
        </button>
      </div>

      {error && <div className="mt-4 rounded-xl bg-danger-tint px-4 py-3 text-sm text-danger">{error}</div>}

      <div className="mt-5 space-y-2">
        {loading ? (
          <div className="py-16 text-center text-sm text-text-muted">Yuklanmoqda...</div>
        ) : kits.length === 0 ? (
          <div className="py-16 text-center text-sm text-text-muted">Hali to'plam yo'q</div>
        ) : (
          kits.map((k) => (
            <button
              key={k.id}
              onClick={() => setEditing(k)}
              className="flex w-full items-center gap-4 rounded-xl bg-surface border border-border px-4 py-3 text-left card-shadow hover:bg-background/50"
            >
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2">
                  <span className="text-sm font-medium text-text-primary">{k.name}</span>
                  {!k.is_active && (
                    <span className="rounded-full bg-background px-2 py-0.5 text-[10px] text-text-muted">Yashirilgan</span>
                  )}
                  {k.status !== "approved" && (
                    <span className="rounded-full bg-primary-light px-2 py-0.5 text-[10px] text-primary">{k.status}</span>
                  )}
                </div>
                <div className="mt-0.5 text-xs text-text-muted">
                  {k.grade_level ? `${k.grade_level}-sinf · ` : ""}
                  {k.items.length} ta mahsulot
                </div>
              </div>
              <div className="shrink-0 text-sm text-text-secondary">{k.total} so'm</div>
            </button>
          ))
        )}
      </div>

      {editing && (
        <KitForm kit={editing} shopId={SHOP_ID} onClose={() => setEditing(null)} onSaved={handleSaved} onDeleted={handleDeleted} />
      )}
      {creating && (
        <KitForm kit={null} shopId={SHOP_ID} onClose={() => setCreating(false)} onSaved={handleSaved} onDeleted={handleDeleted} />
      )}
    </div>
  );
}
