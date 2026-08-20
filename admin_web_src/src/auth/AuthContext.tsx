import { createContext, useContext, useEffect, useRef, useState, type ReactNode } from "react";
import { apiFetch, clearTokens, getAccessToken, setTokens } from "../api/client";
import type { MeUser } from "../api/types";

type AuthState =
  | { status: "loading" }
  | { status: "signed-out" }
  | { status: "signed-in"; user: MeUser }
  | { status: "forbidden"; user: MeUser };

type AuthContextValue = {
  state: AuthState;
  login: () => Promise<void>;
  cancelLogin: () => void;
  logout: () => void;
};

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [state, setState] = useState<AuthState>({ status: "loading" });
  const cancelledRef = useRef(false);

  async function refreshMe() {
    if (!getAccessToken()) {
      setState({ status: "signed-out" });
      return;
    }
    try {
      const user = await apiFetch<MeUser>("/auth/me");
      setState(user.role === "admin" ? { status: "signed-in", user } : { status: "forbidden", user });
    } catch {
      clearTokens();
      setState({ status: "signed-out" });
    }
  }

  useEffect(() => {
    refreshMe();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  async function login() {
    cancelledRef.current = false;
    const popup = window.open("about:blank", "_blank");
    const session = await apiFetch<{ session_id: string; bot_url: string }>(
      "/auth/telegram/session?role=admin",
      { method: "POST" },
    );
    if (popup) popup.location.href = session.bot_url;

    for (let i = 0; i < 150; i++) {
      if (cancelledRef.current) return;
      await new Promise((r) => setTimeout(r, 2000));
      const s = await apiFetch<{
        status: string;
        access_token?: string;
        refresh_token?: string;
      }>(`/auth/telegram/session/${session.session_id}`);
      if (s.status === "confirmed" && s.access_token && s.refresh_token) {
        setTokens(s.access_token, s.refresh_token);
        await refreshMe();
        return;
      }
    }
    throw new Error("Sessiya muddati tugadi, qaytadan urinib ko'ring");
  }

  function cancelLogin() {
    cancelledRef.current = true;
  }

  function logout() {
    clearTokens();
    setState({ status: "signed-out" });
  }

  return (
    <AuthContext.Provider value={{ state, login, cancelLogin, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth AuthProvider ichida ishlatilishi kerak");
  return ctx;
}
