import { apiFetch } from "./client";

export type AppVersionOut = {
  version: string;
  build: number;
  apk_url: string;
  notes: string;
  force: boolean;
};

export function getAppVersion(app: "user" | "seller") {
  return apiFetch<AppVersionOut>(`/app/version?app=${app}`);
}

export function updateAppVersion(payload: AppVersionOut & { app: "user" | "seller" }) {
  return apiFetch<AppVersionOut>(`/admin/app-version`, { method: "PUT", body: JSON.stringify(payload) });
}
