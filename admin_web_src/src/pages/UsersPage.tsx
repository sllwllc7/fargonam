import { useEffect, useState } from "react";
import type { ApiError } from "../api/client";
import { broadcastMessage, listUsers, updateUser, type UserOut, type UserRole } from "../api/users";
import type { Page } from "../api/types";

const ROLE_LABEL: Record<UserRole, string> = { buyer: "Xaridor", seller: "Sotuvchi", admin: "Admin" };

function BroadcastPanel({ singleUser }: { singleUser: UserOut | null }) {
  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const [target, setTarget] = useState<"all" | "buyers" | "sellers" | "user_ids">(singleUser ? "user_ids" : "all");
  const [busy, setBusy] = useState(false);
  const [result, setResult] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function handleSend() {
    if (!title.trim() || !body.trim()) {
      setError("Sarlavha va matn to'ldirilishi shart");
      return;
    }
    setBusy(true);
    setError(null);
    setResult(null);
    try {
      const res = await broadcastMessage({
        title: title.trim(),
        body: body.trim(),
        target,
        user_ids: target === "user_ids" && singleUser ? [singleUser.id] : undefined,
      });
      setResult(`${res.total_users} ta foydalanuvchiga yuborildi (${res.push_sent} ta push bilan)`);
      setTitle("");
      setBody("");
    } catch (e) {
      setError((e as ApiError).message || "Yuborishda xato");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="rounded-xl border border-border bg-surface p-4 card-shadow">
      <div className="flex items-center justify-between">
        <h2 className="text-sm font-semibold">
          {singleUser ? `${singleUser.full_name ?? singleUser.phone ?? singleUser.id}ga xabar` : "Bildirishnoma yuborish"}
        </h2>
        {!singleUser && (
          <select
            value={target}
            onChange={(e) => setTarget(e.target.value as typeof target)}
            className="rounded-lg border border-border px-2 py-1 text-xs bg-surface"
          >
            <option value="all">Hammaga</option>
            <option value="buyers">Xaridorlarga</option>
            <option value="sellers">Sotuvchilarga</option>
          </select>
        )}
      </div>
      <input
        value={title}
        onChange={(e) => setTitle(e.target.value)}
        placeholder="Sarlavha"
        className="mt-3 w-full rounded-lg border border-border px-3 py-2 text-sm"
      />
      <textarea
        value={body}
        onChange={(e) => setBody(e.target.value)}
        placeholder="Xabar matni"
        rows={2}
        className="mt-2 w-full rounded-lg border border-border px-3 py-2 text-sm"
      />
      {error && <p className="mt-2 text-xs text-danger">{error}</p>}
      {result && <p className="mt-2 text-xs text-success">{result}</p>}
      <button
        onClick={handleSend}
        disabled={busy}
        className="btn-primary mt-3 rounded-xl px-4 py-2 text-sm font-semibold disabled:opacity-60"
      >
        {busy ? "Yuborilmoqda..." : "Yuborish"}
      </button>
    </div>
  );
}

export function UsersPage() {
  const [q, setQ] = useState("");
  const [role, setRole] = useState<UserRole | "">("");
  const [page, setPage] = useState<Page<UserOut> | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [busyId, setBusyId] = useState<number | null>(null);
  const [messagingUser, setMessagingUser] = useState<UserOut | null>(null);

  async function load() {
    setLoading(true);
    setError(null);
    try {
      setPage(await listUsers({ q: q || undefined, role: role || undefined }));
    } catch (e) {
      setError((e as ApiError).message || "Yuklashda xato");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    const t = setTimeout(load, 300);
    return () => clearTimeout(t);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [q, role]);

  async function handleToggleActive(u: UserOut) {
    setBusyId(u.id);
    try {
      const updated = await updateUser(u.id, { is_active: !u.is_active });
      setPage((prev) => (prev ? { ...prev, items: prev.items.map((x) => (x.id === u.id ? updated : x)) } : prev));
    } catch (e) {
      setError((e as ApiError).message || "Xato yuz berdi");
    } finally {
      setBusyId(null);
    }
  }

  return (
    <div className="p-8">
      <h1 className="text-xl font-semibold" style={{ letterSpacing: "-0.4px" }}>
        Foydalanuvchilar
      </h1>
      <p className="mt-1 text-sm text-text-muted">{page ? `${page.total} ta foydalanuvchi` : "..."}</p>

      <div className="mt-5">
        <BroadcastPanel singleUser={messagingUser} />
      </div>

      <div className="mt-5 flex flex-wrap gap-2">
        <input
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder="Ism yoki telefon..."
          className="w-56 rounded-lg border border-border bg-surface px-3 py-2 text-sm"
        />
        <select
          value={role}
          onChange={(e) => setRole(e.target.value as UserRole | "")}
          className="rounded-lg border border-border bg-surface px-3 py-2 text-sm"
        >
          <option value="">Barcha rollar</option>
          {Object.entries(ROLE_LABEL).map(([k, v]) => (
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
        ) : (
          page?.items.map((u) => (
            <div key={u.id} className="flex items-center gap-4 rounded-xl bg-surface border border-border px-4 py-3 card-shadow">
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2">
                  <span className="text-sm font-medium text-text-primary">{u.full_name ?? "Ism yo'q"}</span>
                  <span className="rounded-full bg-background px-2 py-0.5 text-[10px] text-text-muted">{ROLE_LABEL[u.role]}</span>
                  {!u.is_active && <span className="rounded-full bg-danger-tint px-2 py-0.5 text-[10px] text-danger">Bloklangan</span>}
                </div>
                <div className="mt-0.5 text-xs text-text-muted">{u.phone ?? "telefon yo'q"}</div>
              </div>
              <button
                onClick={() => setMessagingUser(messagingUser?.id === u.id ? null : u)}
                className="rounded-lg border border-border px-3 py-1.5 text-xs font-medium hover:bg-background"
              >
                {messagingUser?.id === u.id ? "Bekor qilish" : "Xabar yuborish"}
              </button>
              <button
                onClick={() => handleToggleActive(u)}
                disabled={busyId === u.id || u.role === "admin"}
                className="rounded-lg border border-danger/30 px-3 py-1.5 text-xs font-medium text-danger hover:bg-danger-tint disabled:opacity-40"
              >
                {u.is_active ? "Bloklash" : "Blokdan chiqarish"}
              </button>
            </div>
          ))
        )}
      </div>
    </div>
  );
}
