import { useEffect, useState } from "react";
import type { ApiError } from "../api/client";
import { deleteCategory, listCategories, reorderCategories } from "../api/categories";
import type { CategoryOut } from "../api/types";
import { CategoryForm } from "../components/CategoryForm";
import { CATEGORY_ICON_PATHS } from "../utils/categoryIcons";

export function CategoriesPage() {
  const [categories, setCategories] = useState<CategoryOut[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [formOpen, setFormOpen] = useState(false);
  const [editing, setEditing] = useState<CategoryOut | null>(null);
  const [busyId, setBusyId] = useState<number | null>(null);

  async function load() {
    setLoading(true);
    setError(null);
    try {
      const rows = await listCategories();
      setCategories(rows.sort((a, b) => a.sort_order - b.sort_order));
    } catch (e) {
      setError((e as ApiError).message || "Yuklashda xato");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load();
  }, []);

  async function move(index: number, dir: -1 | 1) {
    const target = index + dir;
    if (target < 0 || target >= categories.length) return;
    const next = [...categories];
    [next[index], next[target]] = [next[target], next[index]];
    setCategories(next);
    try {
      await reorderCategories(next.map((c, i) => ({ id: c.id, sort_order: i * 10 })));
      await load();
    } catch (e) {
      setError((e as ApiError).message || "Tartibni saqlashda xato");
      load();
    }
  }

  async function handleDelete(c: CategoryOut) {
    if (!window.confirm(`"${c.name}" kategoriyasini o'chirasizmi?`)) return;
    setBusyId(c.id);
    setError(null);
    try {
      await deleteCategory(c.id);
      setCategories((prev) => prev.filter((x) => x.id !== c.id));
    } catch (e) {
      setError((e as ApiError).message || "O'chirishda xato");
    } finally {
      setBusyId(null);
    }
  }

  function handleSaved(saved: CategoryOut) {
    setCategories((prev) => {
      const exists = prev.some((c) => c.id === saved.id);
      const next = exists ? prev.map((c) => (c.id === saved.id ? saved : c)) : [...prev, saved];
      return next.sort((a, b) => a.sort_order - b.sort_order);
    });
  }

  return (
    <div className="p-8">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-semibold" style={{ letterSpacing: "-0.4px" }}>
            Kategoriyalar
          </h1>
          <p className="mt-1 text-sm text-text-muted">{categories.length} ta kategoriya</p>
        </div>
        <button
          onClick={() => {
            setEditing(null);
            setFormOpen(true);
          }}
          className="btn-primary rounded-xl px-4 py-2 text-sm font-semibold"
        >
          + Yangi kategoriya
        </button>
      </div>

      {error && <div className="mt-4 rounded-xl bg-danger-tint px-4 py-3 text-sm text-danger">{error}</div>}

      <div className="mt-5 space-y-2">
        {loading ? (
          <div className="py-16 text-center text-sm text-text-muted">Yuklanmoqda...</div>
        ) : (
          categories.map((c, i) => (
            <div
              key={c.id}
              className="flex items-center gap-3 rounded-xl bg-surface border border-border px-4 py-3 card-shadow"
            >
              <div
                className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg"
                style={{ background: (c.color ?? "#16294A") + "1A", color: c.color ?? "#16294A" }}
              >
                {c.icon && CATEGORY_ICON_PATHS[c.icon] ? (
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
                    <path
                      d={CATEGORY_ICON_PATHS[c.icon]}
                      stroke="currentColor"
                      strokeWidth="1.8"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                    />
                  </svg>
                ) : (
                  <span className="text-xs">—</span>
                )}
              </div>
              <div className="flex-1 min-w-0">
                <div className="text-sm font-medium text-text-primary">{c.name}</div>
                <div className="text-xs text-text-muted">
                  {c.slug} · {c.product_count} ta mahsulot
                  {c.parent_id ? ` · ota: ${categories.find((p) => p.id === c.parent_id)?.name ?? c.parent_id}` : ""}
                </div>
              </div>
              <div className="flex shrink-0 items-center gap-1.5">
                <button
                  onClick={() => move(i, -1)}
                  disabled={i === 0}
                  className="rounded-lg border border-border px-2 py-1.5 text-xs disabled:opacity-30"
                >
                  ▲
                </button>
                <button
                  onClick={() => move(i, 1)}
                  disabled={i === categories.length - 1}
                  className="rounded-lg border border-border px-2 py-1.5 text-xs disabled:opacity-30"
                >
                  ▼
                </button>
                <button
                  onClick={() => {
                    setEditing(c);
                    setFormOpen(true);
                  }}
                  className="rounded-lg border border-border px-3 py-1.5 text-xs font-medium hover:bg-background"
                >
                  Tahrirlash
                </button>
                <button
                  onClick={() => handleDelete(c)}
                  disabled={busyId === c.id}
                  className="rounded-lg border border-danger/30 px-3 py-1.5 text-xs font-medium text-danger hover:bg-danger-tint disabled:opacity-60"
                >
                  O'chirish
                </button>
              </div>
            </div>
          ))
        )}
      </div>

      {formOpen && (
        <CategoryForm
          category={editing}
          categories={categories}
          onClose={() => setFormOpen(false)}
          onSaved={handleSaved}
        />
      )}
    </div>
  );
}
