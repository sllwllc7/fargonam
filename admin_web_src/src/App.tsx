import type { ReactElement } from "react";
import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom";
import { AuthProvider, useAuth } from "./auth/AuthContext";
import { LoginPage } from "./auth/LoginPage";
import { Layout } from "./components/Layout";
import { CategoriesPage } from "./pages/CategoriesPage";
import { KitsPage } from "./pages/KitsPage";
import { ModerationProductsPage } from "./pages/ModerationProductsPage";
import { OrdersPage } from "./pages/OrdersPage";
import { ProductsPage } from "./pages/ProductsPage";
import { SellersPage } from "./pages/SellersPage";
import { UsersPage } from "./pages/UsersPage";
import { VersionPage } from "./pages/VersionPage";

function Gate({ children }: { children: ReactElement }) {
  const { state } = useAuth();
  if (state.status === "loading") {
    return <div className="min-h-screen flex items-center justify-center text-text-muted">Yuklanmoqda...</div>;
  }
  if (state.status !== "signed-in") return <LoginPage />;
  return children;
}

export default function App() {
  return (
    <BrowserRouter basename="/admin-web">
      <AuthProvider>
        <Routes>
          <Route
            path="/"
            element={
              <Gate>
                <Layout />
              </Gate>
            }
          >
            <Route index element={<Navigate to="/moderation" replace />} />
            <Route path="moderation" element={<ModerationProductsPage />} />
            <Route path="categories" element={<CategoriesPage />} />
            <Route path="products" element={<ProductsPage />} />
            <Route path="kits" element={<KitsPage />} />
            <Route path="orders" element={<OrdersPage />} />
            <Route path="shops" element={<SellersPage />} />
            <Route path="users" element={<UsersPage />} />
            <Route path="version" element={<VersionPage />} />
          </Route>
        </Routes>
      </AuthProvider>
    </BrowserRouter>
  );
}
