import { useEffect, useState } from "react";
import type { ApiError } from "../api/client";
import { getAppVersion, updateAppVersion, type AppVersionOut } from "../api/version";

function AppVersionForm({ app, label }: { app: "user" | "seller"; label: string }) {
  const [version, setVersion] = useState("");
  const [build, setBuild] = useState("");
  const [apkUrl, setApkUrl] = useState("");
  const [notes, setNotes] = useState("");
  const [force, setForce] = useState(false);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [saved, setSaved] = useState(false);

  useEffect(() => {
    getAppVersion(app)
      .then((v: AppVersionOut) => {
        setVersion(v.version);
        setBuild(String(v.build));
        setApkUrl(v.apk_url);
        setNotes(v.notes);
        setForce(v.force);
      })
      .catch(() => {})
      .finally(() => setLoading(false));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  async function handleSave() {
    if (!version.trim() || !build || !apkUrl.trim()) {
      setError("Versiya, build va APK havolasi to'ldirilishi shart");
      return;
    }
    setBusy(true);
    setError(null);
    setSaved(false);
    try {
      await updateAppVersion({ app, version: version.trim(), build: Number(build), apk_url: apkUrl.trim(), notes, force });
      setSaved(true);
    } catch (e) {
      setError((e as ApiError).message || "Saqlashda xato");
    } finally {
      setBusy(false);
    }
  }

  if (loading) return <div className="rounded-xl border border-border bg-surface p-5 text-sm text-text-muted">Yuklanmoqda...</div>;

  return (
    <div className="rounded-xl border border-border bg-surface p-5 card-shadow">
      <h2 className="text-sm font-semibold">{label}</h2>
      <div className="mt-3 grid grid-cols-2 gap-3">
        <div>
          <label className="text-xs font-medium text-text-muted">Versiya</label>
          <input value={version} onChange={(e) => setVersion(e.target.value)} className="mt-1 w-full rounded-lg border border-border px-3 py-2 text-sm" />
        </div>
        <div>
          <label className="text-xs font-medium text-text-muted">Build</label>
          <input value={build} onChange={(e) => setBuild(e.target.value)} inputMode="numeric" className="mt-1 w-full rounded-lg border border-border px-3 py-2 text-sm" />
        </div>
      </div>
      <div className="mt-3">
        <label className="text-xs font-medium text-text-muted">APK havolasi</label>
        <input value={apkUrl} onChange={(e) => setApkUrl(e.target.value)} className="mt-1 w-full rounded-lg border border-border px-3 py-2 text-sm" />
      </div>
      <div className="mt-3">
        <label className="text-xs font-medium text-text-muted">Izoh</label>
        <textarea value={notes} onChange={(e) => setNotes(e.target.value)} rows={2} className="mt-1 w-full rounded-lg border border-border px-3 py-2 text-sm" />
      </div>
      <label className="mt-3 flex items-center gap-2 text-xs text-text-secondary">
        <input type="checkbox" checked={force} onChange={(e) => setForce(e.target.checked)} />
        Majburiy yangilanish
      </label>
      {error && <p className="mt-2 text-xs text-danger">{error}</p>}
      {saved && <p className="mt-2 text-xs text-success">Saqlandi</p>}
      <button onClick={handleSave} disabled={busy} className="btn-primary mt-4 rounded-xl px-4 py-2 text-sm font-semibold disabled:opacity-60">
        {busy ? "Saqlanmoqda..." : "Saqlash"}
      </button>
    </div>
  );
}

export function VersionPage() {
  return (
    <div className="p-8">
      <h1 className="text-xl font-semibold" style={{ letterSpacing: "-0.4px" }}>
        Ilova versiyasi
      </h1>
      <p className="mt-1 text-sm text-text-muted">Konteyner qayta ishga tushmasdan darhol qo'llanadi</p>
      <div className="mt-5 grid grid-cols-2 gap-4">
        <AppVersionForm app="user" label="Fargonam (xaridor)" />
        <AppVersionForm app="seller" label="Fargonam Sotuvchi" />
      </div>
    </div>
  );
}
