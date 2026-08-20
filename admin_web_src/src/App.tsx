import type { ReactElement } from "react";
import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom";
import { AuthProvider, useAuth } from "./auth/AuthContext";
import { LoginPage } from "./auth/LoginPage";
import { Layout } from "./components/Layout";
import { CategoriesPage } from "./pages/CategoriesPage";
import { ModerationProductsPage } from "./pages/ModerationProductsPage";

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
          </Route>
        </Routes>
      </AuthProvider>
    </BrowserRouter>
  );
}
