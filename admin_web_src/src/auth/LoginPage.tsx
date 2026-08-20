import { useState } from "react";
import { useAuth } from "./AuthContext";

export function LoginPage() {
  const { login, cancelLogin, state, logout } = useAuth();
  const [pending, setPending] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleLogin() {
    setError(null);
    setPending(true);
    try {
      await login();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Kirishda xato yuz berdi");
    } finally {
      setPending(false);
    }
  }

  const forbidden = state.status === "forbidden";

  return (
    <div className="min-h-screen flex items-center justify-center bg-background px-4">
      <div className="w-full max-w-sm rounded-[22px] bg-surface border border-border card-shadow p-8 text-center">
        <div className="mx-auto mb-5 flex h-14 w-14 items-center justify-center rounded-2xl btn-primary text-lg font-bold">
          F
        </div>
        <h1 className="text-xl font-semibold text-text-primary" style={{ letterSpacing: "-0.4px" }}>
          Fargonam Admin
        </h1>
        <p className="mt-2 text-sm text-text-muted" style={{ lineHeight: 1.45 }}>
          Faqat admin huquqiga ega Telegram hisobi orqali kirish mumkin.
        </p>

        {forbidden && (
          <div className="mt-5 rounded-xl bg-danger-tint border border-danger/20 px-4 py-3 text-sm text-danger">
            Sizda admin huquqi yo'q.{" "}
            <button className="underline" onClick={logout}>
              Boshqa hisob bilan kirish
            </button>
          </div>
        )}

        {error && (
          <div className="mt-5 rounded-xl bg-danger-tint border border-danger/20 px-4 py-3 text-sm text-danger">
            {error}
          </div>
        )}

        {!forbidden && (
          <button
            onClick={handleLogin}
            disabled={pending}
            className="btn-primary mt-6 w-full rounded-xl py-3 text-[15px] font-semibold disabled:opacity-60"
          >
            {pending ? "Kutilmoqda..." : "Telegram orqali kirish"}
          </button>
        )}

        {pending && (
          <button
            onClick={() => {
              cancelLogin();
              setPending(false);
            }}
            className="mt-3 text-sm text-text-muted underline"
          >
            Bekor qilish
          </button>
        )}
      </div>
    </div>
  );
}
