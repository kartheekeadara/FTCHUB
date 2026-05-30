// Serves email verification success HTML with IP rate limiting (public GET)

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import {
  corsHeaders,
  enforceRateLimit,
} from "../_shared/rateLimit.ts"
import { methodNotAllowedResponse } from "../_shared/validation.ts"

const ENDPOINT = "serve-verification-page"
// 120 requests per minute per IP for static HTML
const IP_MAX = 120
const IP_WINDOW = 60

const HTML_CONTENT = `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Email Verified - FTC HUB</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Roboto', sans-serif;
            background: #f0f4f8;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .container {
            background: white;
            border-radius: 16px;
            padding: 40px;
            max-width: 480px;
            width: 100%;
            box-shadow: 0 10px 40px rgba(0, 0, 0, 0.1);
            text-align: center;
        }
        h1 { font-size: 28px; color: #2d3748; margin-bottom: 12px; }
        .subtitle { font-size: 16px; color: #718096; margin-bottom: 24px; }
        .message {
            background: #f7fafc;
            border-radius: 12px;
            padding: 24px;
            color: #4a5568;
            font-size: 15px;
            line-height: 1.6;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>You're All Set!</h1>
        <p class="subtitle">Your email has been successfully verified</p>
        <div class="message">
            <p><strong>Thank you for verifying your email address!</strong><br><br>
            Your account is now active. Please return to the FTC HUB app and log in.</p>
        </div>
    </div>
</body>
</html>`

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders })
  }

  if (req.method !== "GET") {
    return methodNotAllowedResponse()
  }

  const limited = await enforceRateLimit(req, {
    endpoint: ENDPOINT,
    ipMax: IP_MAX,
    ipWindowSeconds: IP_WINDOW,
  })
  if (limited) return limited

  return new Response(HTML_CONTENT, {
    headers: {
      "Content-Type": "text/html; charset=utf-8",
      "Cache-Control": "public, max-age=3600",
    },
  })
})
