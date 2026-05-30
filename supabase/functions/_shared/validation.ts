// OWASP API10:2023 — Unsafe Consumption of APIs / improper input filtering
// Schema-based validation with Zod; rejects unknown fields via .strict().

import { z } from "https://deno.land/x/zod@v3.22.4/mod.ts"
import { corsHeaders } from "./rateLimit.ts"

const MAX_JSON_BODY_BYTES = 1024

export const deleteAuthUserBodySchema = z
  .object({
    userId: z.string().uuid(),
  })
  .strict()

export type DeleteAuthUserBody = z.infer<typeof deleteAuthUserBodySchema>

/** Parse JSON body with size cap; returns validated data or error Response. */
export async function parseDeleteAuthUserBody(
  req: Request,
): Promise<{ data: DeleteAuthUserBody } | { error: Response }> {
  const contentLength = req.headers.get("content-length")
  if (contentLength && parseInt(contentLength, 10) > MAX_JSON_BODY_BYTES) {
    return {
      error: validationErrorResponse("Request body too large", 400),
    }
  }

  let raw: unknown
  try {
    const text = await req.text()
    if (text.length > MAX_JSON_BODY_BYTES) {
      return { error: validationErrorResponse("Request body too large", 400) }
    }
    raw = text.length === 0 ? {} : JSON.parse(text)
  } catch {
    return { error: validationErrorResponse("Invalid JSON body", 400) }
  }

  const result = deleteAuthUserBodySchema.safeParse(raw)
  if (!result.success) {
    const details = result.error.issues.map((i) => ({
      path: i.path.join("."),
      message: i.message,
    }))
    return {
      error: validationErrorResponse("Validation failed", 400, details),
    }
  }

  return { data: result.data }
}

export function validationErrorResponse(
  error: string,
  status: number,
  details?: unknown,
): Response {
  return new Response(
    JSON.stringify({ error, ...(details ? { details } : {}) }),
    {
      status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    },
  )
}

export function methodNotAllowedResponse(): Response {
  return new Response(
    JSON.stringify({ error: "Method not allowed" }),
    {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    },
  )
}
