import type { UserContext } from '../shared/types.js'

declare global {
  namespace Express {
    interface Request {
      user: UserContext
      ssoToken?: string
    }
  }
}
