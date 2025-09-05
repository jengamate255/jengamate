# PowerShell script to deploy Firebase indexes
Write-Host "🚀 Deploying Firebase Firestore indexes..." -ForegroundColor Green

# Set the project ID (update this with your actual project ID)
$projectId = "jengamate"

# Navigate to the project directory
Set-Location -Path "jengamate_new"

# Check Firebase CLI availability
if (-not (Get-Command firebase -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Firebase CLI not found. Please install Firebase CLI first:" -ForegroundColor Red
    Write-Host "npm install -g firebase-tools" -ForegroundColor Yellow
    exit 1
}

# Check if user is logged in
try {
    $loginStatus = firebase projects:list 2>$null
    Write-Host "✅ Firebase CLI authenticated" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Firebase CLI not authenticated. Please login:" -ForegroundColor Yellow
    firebase login --no-localhost
}

# Deploy the indexes
try {
    Write-Host "📊 Deploying indexes to project: $projectId" -ForegroundColor Cyan
    firebase deploy --only firestore:indexes --project $projectId

    if ($LastExitCode -eq 0) {
        Write-Host "✅ Firebase indexes deployed successfully!" -ForegroundColor Green
    } else {
        Write-Host "❌ Deploy failed with error: $LastExitCode" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Deploy error: $_" -ForegroundColor Red
    Write-Host "💡 Alternative: Create index manually in Firebase Console using:" -ForegroundColor Yellow
    Write-Host "   https://console.firebase.google.com/v1/r/project/jengamate/firestore/indexes?create_composite=Ckhwcm9qZWN0cy9qZW5nYW1hdGUvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL3F1b3Rlcy9pbmRleGVzL18QAROJCgVyZnFJZBABGg0KCWNyZWFOZWRBdBACGgwKCF9f" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "🔍 Current firestore.indexes.json contents:" -ForegroundColor Blue
Get-Content -Path "firestore.indexes.json" | ConvertFrom-Json | ConvertTo-Json -Depth 4

Write-Host ""
Write-Host "💡 Next steps:" -ForegroundColor Cyan
Write-Host "1. Run this script after authenticating Firebase CLI" -ForegroundColor White
Write-Host "2. Or use the Firebase Console link above" -ForegroundColor White
Write-Host "3. Index creation may take 5-10 minutes to complete" -ForegroundColor White
