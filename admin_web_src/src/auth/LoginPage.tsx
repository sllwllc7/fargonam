import { useState, type FormEvent } from "react";
import { ApiError } from "../api/client";
import { useAuth } from "./AuthContext";

export function LoginPage() {
  const { login, state, logout } = useAuth();
  const [loginValue, setLoginValue] = useState("");
  const [password, setPassword] = useState("");
  const [pending, setPending] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setPending(true);
    try {
      await login(loginValue.trim(), password);
    } catch (e) {
      setError(
        e instanceof ApiError && e.status === 401
          ? "Login yoki parol noto'g'ri."
          : "Kirishda xato yuz berdi, qayta urining.",
      );
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
          Login va parol bilan kiring.
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
          <form onSubmit={handleSubmit} className="mt-6 text-left">
            <label className="block text-xs font-semibold text-text-secondary mb-1.5" htmlFor="login">
              Login
            </label>
            <input
              id="login"
              type="text"
              autoComplete="username"
              required
              value={loginValue}
              onChange={(e) => setLoginValue(e.target.value)}
              className="w-full rounded-xl border border-border bg-surface px-4 py-3 text-[15px] text-text-primary"
            />
            <label className="block text-xs font-semibold text-text-secondary mb-1.5 mt-3" htmlFor="password">
              Parol
            </label>
            <input
              id="password"
              type="password"
              autoComplete="current-password"
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full rounded-xl border border-border bg-surface px-4 py-3 text-[15px] text-text-primary"
            />
            <button
              type="submit"
              disabled={pending}
              className="btn-primary mt-5 w-full rounded-xl py-3 text-[15px] font-semibold disabled:opacity-60"
            >
              {pending ? "Kirilmoqda..." : "Kirish"}
            </button>
          </form>
        )}
      </div>
    </div>
  );
}
