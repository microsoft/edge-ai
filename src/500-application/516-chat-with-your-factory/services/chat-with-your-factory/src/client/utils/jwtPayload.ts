/** Decode the payload of a JWT without verifying the signature. */
export function decodeJwtPayload(token: string): Record<string, unknown> {
  let base64 = token.split('.')[1]
    .replace(/-/g, '+')
    .replace(/_/g, '/')
  const pad = base64.length % 4
  if (pad) base64 += '='.repeat(4 - pad)
  const binary = Uint8Array.from(atob(base64), c => c.charCodeAt(0))
  return JSON.parse(new TextDecoder().decode(binary))
}
