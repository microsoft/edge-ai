const MARKDOWN_LINK = /\[([^\]\r\n]+)\]\(\s*https?:\/\/(?:[^\s()]|\([^\r\n)]*\))+(?:\s+(?:"[^"\r\n]*"|'[^'\r\n]*'|\([^\r\n)]*\)))?\s*\)/gi
const ZERO_WIDTH_FORMAT = /[\u200B-\u200D\u2060\uFEFF]/g

export function toSpeechText(markdown: string): string {
  return markdown
    .replace(ZERO_WIDTH_FORMAT, '')
    .replace(/^\s*\[\d+\]:[^\r\n]*(?:\r?\n|$)/gm, '')
    .replace(MARKDOWN_LINK, (_link, label: string) => /^\d+$/.test(label.trim()) ? '' : label)
    .replace(/\[\d+\]/g, '')
    .replace(/https?:\/\/[^\s<>()[\]{}]+/gi, '')
    .replace(/\(\s*\)|\[\s*\]|\{\s*\}/g, ' ')
    .replace(/\s+([,.;:!?])/g, '$1')
    .replace(/\s+/g, ' ')
    .trim()
}