import { useState } from "react";
import type { ApiError } from "../api/client";
import { createCategory, updateCategory } from "../api/categories";
import type { CategoryOut } from "../api/types";
import { CATEGORY_ICON_KEYS, CATEGORY_ICON_PATHS } from "../utils/categoryIcons";

function slugify(name: string): string {
  return name
    .toLowerCase()
    .replace(/[’‘'`]/g, "")
    .replace(/[^a-z0-9а-яёʻʼ]+/gi, "-")
    .replace(/^-+|-+$/g, "");
}

export function CategoryForm({
  category,
  categories,
  onClose,
  onSaved,
}: {
  category: CategoryOut | null;
  categories: CategoryOut[];
  onClose: () => void;
  onSaved: (c: CategoryOut) => void;
}) {
  const [name, setName] = useState(category?.name ?? "");
  const [slug, setSlug] = useState(category?.slug ?? "");
  const [slugTouched, setSlugTouched] = useState(!!category);
  const [parentId, setParentId] = useState<number | "">(category?.parent_id ?? "");
  const [icon, setIcon] = useState<string | null>(category?.icon ?? null);
  const [color, setColor] = useState(category?.color ?? "#16294A");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSave() {
    if (!name.trim() || !slug.trim()) {
      setError("Nom va slug to'ldirilishi shart");
      return;
    }
    setBusy(true);
    setError(null);
    try {
      const payload = {
        name: name.trim(),
        slug: slug.trim(),
        parent_id: parentId === "" ? null : parentId,
        icon,
        color,
      };
      const saved = category ? await updateCategory(category.id, payload) : await createCategory(payload);
      onSaved(saved);
      onClose();
    } catch (e) {
      setError((e as ApiError).message || "Saqlashda xato");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="fixed inset-0 z-40 flex items-center justify-center bg-black/40 p-4">
      <div className="w-full max-w-md rounded-2xl bg-surface card-shadow">
        <div className="flex items-center justify-between border-b border-border px-6 py-4">
          <h2 className="text-base font-semibold">{category ? "Kategoriyani tahrirlash" : "Yangi kategoriya"}</h2>
          <button onClick={onClose} className="text-text-muted hover:text-text-primary text-xl leading-none">
            &times;
          </button>
        </div>
        <div className="p-6 space-y-4">
          <div>
            <label className="text-xs font-medium text-text-muted">Nomi</label>
            <input
              value={name}
              onChange={(e) => {
                setName(e.target.value);
                if (!slugTouched) setSlug(slugify(e.target.value));
              }}
              className="mt-1 w-full rounded-lg border border-border px-3 py-2 text-sm"
            />
          </div>
          <div>
            <label className="text-xs font-medium text-text-muted">Slug</label>
            <input
              value={slug}
              onChange={(e) => {
                setSlug(e.target.value);
                setSlugTouched(true);
              }}
              className="mt-1 w-full rounded-lg border border-border px-3 py-2 text-sm font-mono"
            />
          </div>
          <div>
            <label className="text-xs font-medium text-text-muted">Ota kategoriya (ixtiyoriy)</label>
            <select
              value={parentId}
              onChange={(e) => setParentId(e.target.value ? Number(e.target.value) : "")}
              className="mt-1 w-full rounded-lg border border-border px-3 py-2 text-sm bg-surface"
            >
              <option value="">—</option>
              {categories
                .filter((c) => c.id !== category?.id)
                .map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.name}
                  </option>
                ))}
            </select>
          </div>
          <div>
            <label className="text-xs font-medium text-text-muted">Rang</label>
            <div className="mt-1 flex items-center gap-2">
              <input
                type="color"
                value={color}
                onChange={(e) => setColor(e.target.value)}
                className="h-9 w-14 rounded border border-border"
              />
              <input
                value={color}
                onChange={(e) => setColor(e.target.value)}
                className="flex-1 rounded-lg border border-border px-3 py-2 text-sm font-mono"
              />
            </div>
          </div>
          <div>
            <label className="text-xs font-medium text-text-muted">Ikonka</label>
            <div className="mt-1 grid grid-cols-6 gap-2">
              {CATEGORY_ICON_KEYS.map((key) => (
                <button
                  key={key}
                  onClick={() => setIcon(icon === key ? null : key)}
                  title={key}
                  className={`flex h-10 items-center justify-center rounded-lg border ${
                    icon === key ? "border-primary bg-primary-light" : "border-border hover:bg-background"
                  }`}
                >
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                    <path
                      d={CATEGORY_ICON_PATHS[key]}
                      stroke="currentColor"
                      strokeWidth="1.8"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                    />
                  </svg>
                </button>
              ))}
            </div>
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
            onClick={handleSave}
            disabled={busy}
            className="btn-primary rounded-xl px-5 py-2 text-sm font-semibold disabled:opacity-60"
          >
            {busy ? "Saqlanmoqda..." : "Saqlash"}
          </button>
        </div>
      </div>
    </div>
  );
}
