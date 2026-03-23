/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_POSTHOG_PROJECT_KEY_WEB?: string
  readonly VITE_POSTHOG_PROJECT_KEY_DESKTOP?: string
  readonly VITE_POSTHOG_PROJECT_KEY_POCKET?: string
  readonly VITE_POSTHOG_PROJECT_KEY_DOCS?: string
  readonly VITE_DEFAULT_CHAT_PROVIDER?: string
  readonly VITE_DEFAULT_CHAT_MODEL?: string
  readonly VITE_DEFAULT_CHAT_API_KEY?: string
  readonly VITE_DEFAULT_CHAT_BASE_URL?: string
  readonly VITE_FORCE_DEFAULT_CHAT_CONFIGURATION?: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
