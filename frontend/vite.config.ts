import path from 'path'
import tailwindcss from '@tailwindcss/vite'
import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

/**
 * Producción (Herd/Laravel): estáticos en /spa/*; Laravel sirve spa/index.html vía fallback.
 * Desarrollo: base / para usar http://localhost:5173 sin subruta.
 */
export default defineConfig(({ command }) => ({
  base: command === 'build' ? '/spa/' : '/',
  plugins: [react(), tailwindcss()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  build: {
    outDir: path.resolve(__dirname, '../public/spa'),
    emptyOutDir: true,
  },
  server: {
    proxy: {
      '/api': {
        target: 'http://feriasv2r.test',
        changeOrigin: true,
        cookieDomainRewrite: 'localhost',
      },
      '/sanctum': {
        target: 'http://feriasv2r.test',
        changeOrigin: true,
        cookieDomainRewrite: 'localhost',
      },
    },
  },
}))
