import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig(({ mode }) => {
  let base = '/'

  if (mode === 'test') {
    base = '/svg-encoder/'
  }

  return {
    plugins: [react()],
    base,
  }
})
