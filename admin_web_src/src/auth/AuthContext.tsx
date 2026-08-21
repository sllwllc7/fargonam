import { createContext, useContext, useEffect, useState, type ReactNode } from "react";
import { apiFetch, clearTokens, getAccessToken, setTokens } from "../api/client";
import type { MeUser } from "../api/types";

type AuthState =
  | { status: "loading" }
  | { status: "signed-out" }
  | { status: "signed-in"; user: MeUser }
  | { status: "forbidden"; user: MeUser };

type AuthContextValue = {
  state: AuthState;
  login: (login: string, password: string) => Promise<void>;
  logout: () => void;
};

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [state, setState] = useState<AuthState>({ status: "loading" });

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

  async function login(loginValue: string, password: string) {
    const res = await apiFetch<{ access_token: string; refresh_token: string }>("/auth/admin-login", {
      method: "POST",
      body: JSON.stringify({ login: loginValue, password }),
    });
    setTokens(res.access_token, res.refresh_token);
    await refreshMe();
  }

  function logout() {
    clearTokens();
    setState({ status: "signed-out" });
  }

  return (
    <AuthContext.Provider value={{ state, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth AuthProvider ichida ishlatilishi kerak");
  return ctx;
}
