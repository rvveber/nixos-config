// Minimal app singleton contract used by app.ts and window constructors.
import type Gdk from "gi://Gdk?version=4.0"

type RequestResponder = (response: unknown) => void

declare const app: {
  get_monitors(): Gdk.Monitor[]
  start(config: {
    css?: string
    main?: () => void
    requestHandler?: (request: unknown, respond: RequestResponder) => void
  }): void
}

export default app
