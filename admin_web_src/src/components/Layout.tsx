import { NavLink, Outlet } from "react-router-dom";
import { useAuth } from "../auth/AuthContext";

const NAV_ITEMS = [
  { to: "/moderation", label: "Moderatsiya", enabled: true },
  { to: "/products", label: "Mahsulotlar", enabled: false },
  { to: "/categories", label: "Kategoriyalar", enabled: false },
  { to: "/kits", label: "To'plamlar", enabled: false },
  { to: "/orders", label: "Buyurtmalar", enabled: false },
  { to: "/shops", label: "Sotuvchilar", enabled: false },
  { to: "/users", label: "Foydalanuvchilar", enabled: false },
  { to: "/version", label: "Versiya", enabled: false },
];

export function Layout() {
  const { state, logout } = useAuth();
  const user = state.status === "signed-in" ? state.user : null;

  return (
    <div className="min-h-screen flex bg-background">
      <aside className="w-64 shrink-0 bg-primary text-white flex flex-col">
        <div className="px-5 py-6">
          <div className="text-lg font-semibold" style={{ letterSpacing: "-0.4px" }}>
            Fargonam
          </div>
          <div className="text-xs text-white/60 mt-0.5">Admin panel</div>
        </div>
        <nav className="flex-1 px-3 space-y-1">
          {NAV_ITEMS.map((item) =>
            item.enabled ? (
              <NavLink
                key={item.to}
                to={item.to}
                className={({ isActive }) =>
                  `block rounded-xl px-3 py-2.5 text-sm font-medium transition ${
                    isActive ? "bg-white/10 text-white" : "text-white/70 hover:bg-white/5 hover:text-white"
                  }`
                }
              >
                {item.label}
              </NavLink>
            ) : (
              <div
                key={item.to}
                className="flex items-center justify-between rounded-xl px-3 py-2.5 text-sm text-white/30 cursor-not-allowed"
              >
                <span>{item.label}</span>
                <span className="text-[10px] rounded-full bg-white/10 px-2 py-0.5">Tez orada</span>
              </div>
            ),
          )}
        </nav>
        <div className="px-3 py-4 border-t border-white/10">
          <div className="px-3 py-2 text-sm text-white/70 truncate">{user?.full_name ?? "Admin"}</div>
          <button
            onClick={logout}
            className="w-full text-left rounded-xl px-3 py-2 text-sm text-white/60 hover:bg-white/5 hover:text-white"
          >
            Chiqish
          </button>
        </div>
      </aside>
      <main className="flex-1 min-w-0">
        <Outlet />
      </main>
    </div>
  );
}
