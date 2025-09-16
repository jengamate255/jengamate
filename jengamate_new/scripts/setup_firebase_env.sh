#!/bin/bash

echo "🔧 Firebase Custom Claims Setup Helper"
echo "====================================="
echo ""

# Function to extract values from Firebase service account JSON
extract_firebase_credentials() {
    if [ -f "$1" ]; then
        echo "📄 Reading Firebase service account JSON..."

        # Extract values using jq if available, otherwise use grep/sed
        if command -v jq &> /dev/null; then
            PROJECT_ID=$(jq -r '.project_id' "$1")
            PRIVATE_KEY=$(jq -r '.private_key' "$1")
            CLIENT_EMAIL=$(jq -r '.client_email' "$1")
        else
            echo "⚠️  jq not found, using grep (less reliable)"
            PROJECT_ID=$(grep '"project_id"' "$1" | cut -d'"' -f4)
            PRIVATE_KEY=$(grep '"private_key"' "$1" | sed 's/.*"private_key"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
            CLIENT_EMAIL=$(grep '"client_email"' "$1" | cut -d'"' -f4)
        fi

        echo "✅ Credentials extracted successfully"
    else
        echo "❌ Service account JSON file not found: $1"
        echo ""
        echo "📋 To get your service account JSON:"
        echo "1. Go to Firebase Console → Project Settings → Service Accounts"
        echo "2. Click 'Generate new private key'"
        echo "3. Save the downloaded JSON file"
        echo "4. Run: ./setup_firebase_env.sh /path/to/serviceAccountKey.json"
        exit 1
    fi
}

# Check if file path is provided
if [ $# -eq 0 ]; then
    echo "❌ Please provide path to Firebase service account JSON file"
    echo ""
    echo "Usage: ./setup_firebase_env.sh /path/to/serviceAccountKey.json"
    echo ""
    echo "Example: ./setup_firebase_env.sh ./serviceAccountKey.json"
    exit 1
fi

SERVICE_ACCOUNT_FILE="$1"

# Extract credentials
extract_firebase_credentials "$SERVICE_ACCOUNT_FILE"

# Create .env file
echo "📝 Creating .env file with Firebase credentials..."
cat > .env << EOF
# Firebase Service Account Credentials
FIREBASE_PROJECT_ID="$PROJECT_ID"
FIREBASE_PRIVATE_KEY="$PRIVATE_KEY"
FIREBASE_CLIENT_EMAIL="$CLIENT_EMAIL"
EOF

# Create export script for easy loading
echo "📝 Creating environment loader script..."
cat > load_firebase_env.sh << 'EOF'
#!/bin/bash
# Load Firebase environment variables
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
    echo "✅ Firebase environment variables loaded"
else
    echo "❌ .env file not found. Run setup_firebase_env.sh first"
fi
EOF

chmod +x load_firebase_env.sh

# Test the setup
echo ""
echo "🧪 Testing Firebase connection..."
source load_firebase_env.sh

if [ -n "$FIREBASE_PROJECT_ID" ] && [ -n "$FIREBASE_PRIVATE_KEY" ] && [ -n "$FIREBASE_CLIENT_EMAIL" ]; then
    echo "✅ Environment variables set successfully"
    echo ""
    echo "🚀 Next steps:"
    echo "1. Install dependencies: npm install firebase-admin"
    echo "2. Load environment: source load_firebase_env.sh"
    echo "3. Set custom claims: node set_custom_claims.js"
    echo ""
    echo "📁 Files created:"
    echo "  - .env (Firebase credentials)"
    echo "  - load_firebase_env.sh (Environment loader)"
    echo ""
    echo "⚠️  Important: Keep .env file secure and don't commit to git!"
else
    echo "❌ Failed to set environment variables"
    exit 1
fi
