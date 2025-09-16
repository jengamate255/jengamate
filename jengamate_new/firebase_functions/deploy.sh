#!/bin/bash

echo "🚀 Deploying Firebase Functions for Supabase Integration"
echo ""

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found. Installing..."
    npm install -g firebase-tools
fi

# Check if user is logged in
if ! firebase projects:list &> /dev/null; then
    echo "🔐 Please login to Firebase:"
    firebase login
fi

# Check if functions are initialized
if [ ! -d "functions" ]; then
    echo "📁 Initializing Firebase Functions..."
    firebase init functions
fi

# Install dependencies
echo "📦 Installing dependencies..."
cd functions
npm install

# Deploy functions
echo "🚀 Deploying functions..."
cd ..
firebase deploy --only functions

echo ""
echo "✅ Firebase Functions deployed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Go to Supabase Dashboard → Settings → Authentication → Third-Party Auth"
echo "2. Add Firebase Auth integration with your Firebase Project ID"
echo "3. Test the integration in your Flutter app"
echo ""
echo "🔗 Useful links:"
echo "- Firebase Console: https://console.firebase.google.com"
echo "- Supabase Dashboard: https://supabase.com/dashboard"
echo "- Function logs: https://console.firebase.google.com/project/_/functions/logs"
