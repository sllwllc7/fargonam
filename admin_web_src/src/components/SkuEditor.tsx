import { useState } from "react";
import { createVariant, deleteVariant, updateVariant } from "../api/products";
import type { ApiError } from "../api/client";
import type { VariantOut } from "../api/types";
import { comboKey, comboLabel, deriveParamsFromVariants, generateCombos, type ParamDef } from "../utils/skuMatrix";

export function SkuEditor({
  productId,
  variants,
  onVariantsChange,
}: {
  productId: number;
  variants: VariantOut[];
  onVariantsChange: (variants: VariantOut[]) => void;
}) {
  const [params, setParams] = useState<ParamDef[]>(() => deriveParamsFromVariants(variants));
  const [syncing, setSyncing] = useState(false);
  const [syncMsg, setSyncMsg] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [rowDrafts, setRowDrafts] = useState<Record<number, { price: string; stock: string }>>({});
  const [rowBusy, setRowBusy] = useState<number | null>(null);

  function draftFor(v: VariantOut) {
    return rowDrafts[v.id] ?? { price: String(v.price), stock: String(v.stock) };
  }

  function setDraft(v: VariantOut, patch: Partial<{ price: string; stock: string }>) {
    setRowDrafts((prev) => ({ ...prev, [v.id]: { ...draftFor(v), ...patch } }));
  }

  function addParam() {
    setParams((prev) => [...prev, { name: "", values: [] }]);
  }

  function updateParamName(index: number, name: string) {
    setParams((prev) => prev.map((p, i) => (i === index ? { ...p, name } : p)));
  }

  function updateParamValues(index: number, raw: string) {
    const values = raw
      .split(",")
      .map((v) => v.trim())
      .filter(Boolean);
    setParams((prev) => prev.map((p, i) => (i === index ? { ...p, values } : p)));
  }

  function removeParam(index: number) {
    setParams((prev) => prev.filter((_, i) => i !== index));
  }

  async function handleSync() {
    setSyncing(true);
    setError(null);
    setSyncMsg(null);
    try {
      const combos = generateCombos(params);
      const existingByKey = new Map(variants.map((v) => [comboKey(v.attributes ?? {}), v]));
      const targetKeys = new Set(combos.map((c) => comboKey(c)));

      const defaultPrice = variants.find((v) => v.is_active)?.price ?? variants[0]?.price ?? 1000;
      let created = 0;
      let reactivated = 0;
      let deactivated = 0;
      const next = [...variants];

      for (const combo of combos) {
        const key = comboKey(combo);
        const existing = existingByKey.get(key);
        if (!existing) {
          const v = await createVariant(productId, {
            variant_name: comboLabel(combo),
            price: defaultPrice,
            stock: 0,
            attributes: combo,
          });
          next.push(v);
          created++;
        } else if (!existing.is_active) {
          const v = await updateVariant(productId, existing.id, { is_active: true });
          const idx = next.findIndex((x) => x.id === v.id);
          if (idx >= 0) next[idx] = v;
          reactivated++;
        }
      }

      for (const v of variants) {
        const key = comboKey(v.attributes ?? {});
        if (!targetKeys.has(key) && v.is_active) {
          const v2 = await updateVariant(productId, v.id, { is_active: false });
          const idx = next.findIndex((x) => x.id === v2.id);
          if (idx >= 0) next[idx] = v2;
          deactivated++;
        }
      }

      onVariantsChange(next);
      setSyncMsg(`${created} ta yangi, ${reactivated} ta qayta faollashtirildi, ${deactivated} ta nofaol qilindi`);
    } catch (e) {
      setError((e as ApiError).message || "Jadvalni yangilashda xato");
    } finally {
      setSyncing(false);
    }
  }

  async function handleSaveRow(v: VariantOut) {
    const draft = draftFor(v);
    const price = Number(draft.price);
    const stock = Number(draft.stock);
    if (!Number.isFinite(price) || price <= 0) {
      setError("Narx 0 dan katta bo'lishi kerak");
      return;
    }
    if (!Number.isFinite(stock) || stock < 0) {
      setError("Zaxira manfiy bo'lmasligi kerak");
      return;
    }
    setRowBusy(v.id);
    setError(null);
    try {
      const updated = await updateVariant(productId, v.id, { price, stock });
      onVariantsChange(variants.map((x) => (x.id === updated.id ? updated : x)));
      setRowDrafts((prev) => {
        const next = { ...prev };
        delete next[v.id];
        return next;
      });
    } catch (e) {
      setError((e as ApiError).message || "Saqlashda xato");
    } finally {
      setRowBusy(null);
    }
  }

  async function handleToggleActive(v: VariantOut) {
    setRowBusy(v.id);
    setError(null);
    try {
      const updated = await updateVariant(productId, v.id, { is_active: !v.is_active });
      onVariantsChange(variants.map((x) => (x.id === updated.id ? updated : x)));
    } catch (e) {
      setError((e as ApiError).message || "Xato yuz berdi");
    } finally {
      setRowBusy(null);
    }
  }

  async function handleDelete(v: VariantOut) {
    setRowBusy(v.id);
    setError(null);
    try {
      await deleteVariant(productId, v.id);
      onVariantsChange(variants.filter((x) => x.id !== v.id));
    } catch (e) {
      const err = e as ApiError;
      if (err.status === 400) {
        // Backend: buyurtma/savatda ishlatilgan — o'chirib bo'lmaydi, nofaol qilamiz
        await handleToggleActive(v);
      } else {
        setError(err.message || "O'chirishda xato");
      }
    } finally {
      setRowBusy(null);
    }
  }

  return (
    <div className="space-y-3">
      <div>
        <label className="text-xs font-medium text-text-muted">Parametrlar</label>
        <div className="mt-1 space-y-2">
          {params.map((p, i) => (
            <div key={i} className="flex items-center gap-2">
              <input
                value={p.name}
                onChange={(e) => updateParamName(i, e.target.value)}
                placeholder="masalan: rang"
                className="w-28 shrink-0 rounded-lg border border-border px-2 py-1.5 text-xs"
              />
              <input
                value={p.values.join(", ")}
                onChange={(e) => updateParamValues(i, e.target.value)}
                placeholder="qiymatlar, vergul bilan: qizil, ko'k"
                className="flex-1 rounded-lg border border-border px-2 py-1.5 text-xs"
              />
              <button
                onClick={() => removeParam(i)}
                className="shrink-0 rounded-lg border border-border px-2 py-1.5 text-xs text-danger hover:bg-danger-tint"
              >
                O'chirish
              </button>
            </div>
          ))}
          <div className="flex items-center gap-2">
            <button onClick={addParam} className="text-xs font-medium text-primary-mid hover:underline">
              + Parametr qo'shish
            </button>
            <span className="text-text-muted">·</span>
            <button
              onClick={handleSync}
              disabled={syncing}
              className="btn-primary rounded-lg px-3 py-1.5 text-xs font-semibold disabled:opacity-60"
            >
              {syncing ? "Yangilanmoqda..." : "Jadvalni qayta hisoblash"}
            </button>
          </div>
          {syncMsg && <p className="text-[11px] text-success">{syncMsg}</p>}
        </div>
      </div>

      {error && <div className="rounded-lg bg-danger-tint px-3 py-2 text-xs text-danger">{error}</div>}

      <div className="overflow-x-auto rounded-xl border border-border">
        <table className="w-full text-xs">
          <thead>
            <tr className="bg-background text-text-muted">
              <th className="px-3 py-2 text-left font-medium">SKU</th>
              <th className="px-3 py-2 text-left font-medium">Variant</th>
              <th className="px-3 py-2 text-right font-medium">Narx</th>
              <th className="px-3 py-2 text-right font-medium">Zaxira</th>
              <th className="px-3 py-2 text-left font-medium">Holat</th>
              <th className="px-3 py-2"></th>
            </tr>
          </thead>
          <tbody>
            {variants.length === 0 ? (
              <tr>
                <td colSpan={6} className="px-3 py-3 text-center text-text-muted">
                  Variant yo'q
                </td>
              </tr>
            ) : (
              variants.map((v) => {
                const draft = draftFor(v);
                const busy = rowBusy === v.id;
                return (
                  <tr key={v.id} className="border-t border-border">
                    <td className="px-3 py-2 text-text-secondary">{v.sku}</td>
                    <td className="px-3 py-2 text-text-secondary">{v.variant_name}</td>
                    <td className="px-3 py-1.5 text-right">
                      <input
                        value={draft.price}
                        onChange={(e) => setDraft(v, { price: e.target.value })}
                        className="w-20 rounded border border-border px-1.5 py-1 text-right text-xs"
                        inputMode="numeric"
                      />
                    </td>
                    <td className="px-3 py-1.5 text-right">
                      <input
                        value={draft.stock}
                        onChange={(e) => setDraft(v, { stock: e.target.value })}
                        className="w-16 rounded border border-border px-1.5 py-1 text-right text-xs"
                        inputMode="numeric"
                      />
                    </td>
                    <td className="px-3 py-2">
                      {v.is_active ? (
                        <span className="text-success">Faol</span>
                      ) : (
                        <span className="text-text-muted">Nofaol</span>
                      )}
                    </td>
                    <td className="px-3 py-2">
                      <div className="flex justify-end gap-1.5">
                        <button
                          onClick={() => handleSaveRow(v)}
                          disabled={busy}
                          className="rounded-lg border border-border px-2 py-1 text-[11px] font-medium hover:bg-background disabled:opacity-60"
                        >
                          Saqlash
                        </button>
                        <button
                          onClick={() => handleToggleActive(v)}
                          disabled={busy}
                          className="rounded-lg border border-border px-2 py-1 text-[11px] font-medium hover:bg-background disabled:opacity-60"
                        >
                          {v.is_active ? "Nofaol qilish" : "Faollashtirish"}
                        </button>
                        <button
                          onClick={() => handleDelete(v)}
                          disabled={busy}
                          className="rounded-lg border border-danger/30 px-2 py-1 text-[11px] font-medium text-danger hover:bg-danger-tint disabled:opacity-60"
                        >
                          O'chirish
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
