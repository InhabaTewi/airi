import type { ContextMessage } from '../../../types/chat'

import { ContextUpdateStrategy } from '@proj-airi/server-sdk'
import { nanoid } from 'nanoid'

const DATETIME_CONTEXT_ID = 'system:datetime'

function getPreferredLanguage() {
  if (typeof localStorage !== 'undefined') {
    const fromSettings = localStorage.getItem('settings/language')
    if (fromSettings)
      return fromSettings
  }

  if (typeof navigator !== 'undefined' && navigator.language)
    return navigator.language

  return 'en'
}

function isChineseLanguage() {
  return getPreferredLanguage().toLowerCase().startsWith('zh')
}

/**
 * Creates a context message containing the current datetime information.
 * This context is injected before each chat message to provide temporal awareness.
 */
export function createDatetimeContext(): ContextMessage {
  const now = new Date()
  const preferredChinese = isChineseLanguage()

  return {
    id: nanoid(),
    contextId: DATETIME_CONTEXT_ID,
    strategy: ContextUpdateStrategy.ReplaceSelf,
    text: preferredChinese
      ? `当前时间: ${now.toISOString()} (${now.toLocaleString()})\n当前语言设置为中文，请使用中文回复。`
      : `Current datetime: ${now.toISOString()} (${now.toLocaleString()})`,
    createdAt: Date.now(),
  }
}
