import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

// Manba shu papkada, build natijasi ../admin_web ga tushadi — backendning
// `StaticFiles` mounti ayni shu papkani /admin-web ostida xizmat qiladi
// (backend/app/main.py). Bu tayyor infratuzilmaga hech narsa o'zgartirmaydi.
export default defineConfig({
  plugins: [react(), tailwindcss()],
  base: '/admin-web/',
  build: {
    outDir: '../admin_web',
    emptyOutDir: true,
  },
  server: {
    port: 5173,
    proxy: {
      '/auth': 'http://localhost:8000',
      '/admin': 'http://localhost:8000',
      '/categories': 'http://localhost:8000',
      '/products': 'http://localhost:8000',
      '/app': 'http://localhost:8000',
      '/static': 'http://localhost:8000',
    },
  },
})
