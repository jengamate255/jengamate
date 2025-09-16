# Simple Payment Proofs Bucket Manager
# This script manages the local payment proofs bucket storage

param(
    [string]$Action = "status"
)

$bucketPath = "$PSScriptRoot\..\supabase\buckets\payment_proofs"

function Show-Status {
    Write-Host "Payment Proofs Bucket Status" -ForegroundColor Green
    Write-Host "============================" -ForegroundColor Green

    if (!(Test-Path $bucketPath)) {
        Write-Host "Bucket directory does not exist: $bucketPath" -ForegroundColor Red
        return
    }

    Write-Host "Bucket path: $bucketPath" -ForegroundColor Yellow

    $userDirs = Get-ChildItem -Path $bucketPath -Directory -ErrorAction SilentlyContinue
    Write-Host "User directories: $($userDirs.Count)" -ForegroundColor Cyan

    $totalFiles = 0
    $totalSize = 0

    foreach ($userDir in $userDirs) {
        Write-Host "User: $($userDir.Name)" -ForegroundColor Magenta

        $orderDirs = Get-ChildItem -Path $userDir.FullName -Directory -ErrorAction SilentlyContinue
        Write-Host "  Orders: $($orderDirs.Count)" -ForegroundColor Blue

        foreach ($orderDir in $orderDirs) {
            $files = Get-ChildItem -Path $orderDir.FullName -File -ErrorAction SilentlyContinue
            $totalFiles += $files.Count
            $dirSize = ($files | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
            $totalSize += $dirSize

            $sizeMB = [math]::Round($dirSize / 1MB, 2)
            Write-Host "    Order $($orderDir.Name): $($files.Count) files ($sizeMB MB)" -ForegroundColor White
        }
    }

    Write-Host ""
    Write-Host "Summary:" -ForegroundColor Green
    Write-Host "  Total users: $($userDirs.Count)" -ForegroundColor Yellow
    Write-Host "  Total files: $totalFiles" -ForegroundColor Yellow
    $totalSizeMB = [math]::Round($totalSize / 1MB, 2)
    Write-Host "  Total size: $totalSizeMB MB" -ForegroundColor Yellow
}

function Create-SampleData {
    Write-Host "Creating sample bucket data..." -ForegroundColor Green

    # Create sample user directory
    $sampleUserPath = Join-Path $bucketPath "demo_user_001"
    if (!(Test-Path $sampleUserPath)) {
        New-Item -ItemType Directory -Path $sampleUserPath -Force | Out-Null
        Write-Host "Created user directory: demo_user_001" -ForegroundColor Yellow
    }

    # Create sample order directory
    $sampleOrderPath = Join-Path $sampleUserPath "demo_order_001"
    if (!(Test-Path $sampleOrderPath)) {
        New-Item -ItemType Directory -Path $sampleOrderPath -Force | Out-Null
        Write-Host "Created order directory: demo_order_001" -ForegroundColor Yellow
    }

    # Create sample files
    $sampleFile1 = Join-Path $sampleOrderPath "payment_receipt_001.jpg"
    if (!(Test-Path $sampleFile1)) {
        "Sample payment receipt - would contain actual image data" | Out-File -FilePath $sampleFile1 -Encoding UTF8
        Write-Host "Created sample payment receipt" -ForegroundColor Yellow
    }

    $sampleFile2 = Join-Path $sampleOrderPath "bank_statement_001.pdf"
    if (!(Test-Path $sampleFile2)) {
        "Sample bank statement - would contain actual PDF data" | Out-File -FilePath $sampleFile2 -Encoding UTF8
        Write-Host "Created sample bank statement" -ForegroundColor Yellow
    }

    Write-Host "Sample data creation completed!" -ForegroundColor Green
}

function Show-Help {
    Write-Host "Payment Proofs Bucket Manager" -ForegroundColor Green
    Write-Host "============================" -ForegroundColor Green
    Write-Host ""
    Write-Host "ACTIONS:" -ForegroundColor Yellow
    Write-Host "  status      Show bucket status and contents"
    Write-Host "  sample      Create sample bucket data for testing"
    Write-Host "  help        Show this help message"
    Write-Host ""
    Write-Host "USAGE:" -ForegroundColor Yellow
    Write-Host "  .\bucket_manager.ps1 -Action <action>"
    Write-Host ""
    Write-Host "EXAMPLES:" -ForegroundColor Yellow
    Write-Host "  .\bucket_manager.ps1 -Action status"
    Write-Host "  .\bucket_manager.ps1 -Action sample"
    Write-Host ""
}

# Main script logic
switch ($Action.ToLower()) {
    "status" {
        Show-Status
    }
    "sample" {
        Create-SampleData
    }
    "help" {
        Show-Help
    }
    default {
        Write-Host "Unknown action: $Action" -ForegroundColor Red
        Write-Host ""
        Show-Help
    }
}