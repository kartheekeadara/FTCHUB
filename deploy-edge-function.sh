#!/bin/bash
# Edge Function Deployment Script for FTC Hub
# Run this script after logging in to Supabase CLI
#
# Required environment variables (never commit real values):
#   SUPABASE_PROJECT_REF
#   SUPABASE_URL
#   SUPABASE_SERVICE_ROLE_KEY

set -e

echo "Deploying Edge Function for Account Deletion..."
echo ""

# OWASP: load secrets from environment only — never hardcode service_role keys
PROJECT_REF="${SUPABASE_PROJECT_REF:-}"
SUPABASE_URL="${SUPABASE_URL:-}"
SERVICE_ROLE_KEY="${SUPABASE_SERVICE_ROLE_KEY:-}"

if [ -z "$PROJECT_REF" ] || [ -z "$SUPABASE_URL" ] || [ -z "$SERVICE_ROLE_KEY" ]; then
    echo "Error: Missing required environment variables."
    echo "  Set SUPABASE_PROJECT_REF, SUPABASE_URL, and SUPABASE_SERVICE_ROLE_KEY"
    echo "  See deploy-edge-function.sh.example"
    exit 1
fi

cd "$(dirname "$0")"

echo "Step 1: Checking Supabase CLI..."
if ! command -v supabase &> /dev/null && ! command -v npx &> /dev/null; then
    echo "Error: Neither 'supabase' nor 'npx' found. Please install Node.js first."
    exit 1
fi

SUPABASE_CMD="supabase"
if ! command -v supabase &> /dev/null; then
    SUPABASE_CMD="npx supabase"
    echo "   Using npx supabase (local install)"
else
    echo "   Using global supabase CLI"
fi

echo ""
echo "Step 2: Verifying Supabase is initialized..."
if [ ! -f "supabase/config.toml" ]; then
    echo "   Initializing Supabase..."
    $SUPABASE_CMD init --no-vscode --no-intellij
else
    echo "   Already initialized"
fi

echo ""
echo "Step 3: Linking to Supabase project..."
$SUPABASE_CMD link --project-ref "$PROJECT_REF"

echo ""
echo "Step 4: Setting environment secrets..."
# Supabase CLI disallows secret names starting with SUPABASE_; use PROJECT_URL / SERVICE_ROLE_KEY
$SUPABASE_CMD secrets set PROJECT_URL="$SUPABASE_URL"
$SUPABASE_CMD secrets set SERVICE_ROLE_KEY="$SERVICE_ROLE_KEY"

echo ""
echo "Step 5: Verifying Edge Function files exist..."
for fn in delete-auth-user serve-verification-page; do
    if [ ! -f "supabase/functions/$fn/index.ts" ]; then
        echo "Error: Edge Function not found at supabase/functions/$fn/index.ts"
        exit 1
    fi
done
echo "   Edge Function files found"

echo ""
echo "Step 6: Deploying Edge Functions..."
$SUPABASE_CMD functions deploy delete-auth-user
$SUPABASE_CMD functions deploy serve-verification-page

echo ""
echo "Step 7: Verifying deployment..."
$SUPABASE_CMD functions list

echo ""
echo "Deployment complete!"
echo "delete-auth-user: https://${PROJECT_REF}.supabase.co/functions/v1/delete-auth-user"
echo "serve-verification-page: https://${PROJECT_REF}.supabase.co/functions/v1/serve-verification-page"
