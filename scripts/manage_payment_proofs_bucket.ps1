# PowerShell script to manage payment proofs bucket storage
# This script demonstrates how to work with the payment proofs bucket

param(
    [string]$Action = "status",
    [string]$UserId = "",
    [string]$OrderId = "",
    [switch]$Help
)

function Show-Help {
    Write-Host "Payment Proofs Bucket Management Script"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "USAGE:"
    Write-Host "    .\manage_payment_proofs_bucket.ps1 -Action <action> [parameters]"
    Write-Host ""
    Write-Host "ACTIONS:"
    Write-Host "    status          Show bucket status and structure"
    Write-Host "    create-user     Create user directory: -UserId <user_id>"
    Write-Host "    create-order    Create order directory: -UserId <user_id> -OrderId <order_id>"
    Write-Host "    list-user       List user's payment proofs: -UserId <user_id>"
    Write-Host "    list-order      List order payment proofs: -UserId <user_id> -OrderId <order_id>"
    Write-Host "    cleanup         Clean up old payment proofs"
    Write-Host ""
    Write-Host "EXAMPLES:"
    Write-Host "    .\manage_payment_proofs_bucket.ps1 -Action status"
    Write-Host "    .\manage_payment_proofs_bucket.ps1 -Action create-user -UserId 'user123'"
    Write-Host "    .\manage_payment_proofs_bucket.ps1 -Action create-order -UserId 'user123' -OrderId 'order456'"
    Write-Host "    .\manage_payment_proofs_bucket.ps1 -Action list-user -UserId 'user123'"
    Write-Host ""
}

function Get-BucketPath {
    return Join-Path $PSScriptRoot "..\supabase\buckets\payment_proofs"
}

function Show-BucketStatus {
    $bucketPath = Get-BucketPath

    Write-Host "Payment Proofs Bucket Status"
    Write-Host "============================"

    if (!(Test-Path $bucketPath)) {
        Write-Host "❌ Bucket directory does not exist: $bucketPath"
        return
    }

    Write-Host "✅ Bucket path: $bucketPath"

    $userDirs = Get-ChildItem -Path $bucketPath -Directory
    Write-Host "📁 User directories: $($userDirs.Count)"

    $totalFiles = 0
    $totalSize = 0

    foreach ($userDir in $userDirs) {
        Write-Host "  👤 User: $($userDir.Name)"

        $orderDirs = Get-ChildItem -Path $userDir.FullName -Directory
        Write-Host "    📂 Orders: $($orderDirs.Count)"

        foreach ($orderDir in $orderDirs) {
            $files = Get-ChildItem -Path $orderDir.FullName -File
            $totalFiles += $files.Count
            $dirSize = ($files | Measure-Object -Property Length -Sum).Sum
            $totalSize += $dirSize

            Write-Host "      📄 Order $($orderDir.Name): $($files.Count) files ($([math]::Round($dirSize / 1MB, 2)) MB)"
        }
    }

    Write-Host ""
    Write-Host "Summary:"
    Write-Host "  - Total users: $($userDirs.Count)"
    Write-Host "  - Total files: $totalFiles"
    Write-Host "  - Total size: $([math]::Round($totalSize / 1MB, 2)) MB"
}

function New-UserDirectory {
    param([string]$UserId)

    if ([string]::IsNullOrEmpty($UserId)) {
        Write-Host "❌ UserId is required for create-user action"
        return
    }

    $userPath = Join-Path (Get-BucketPath) $UserId

    if (Test-Path $userPath) {
        Write-Host "ℹ️  User directory already exists: $userPath"
    } else {
        New-Item -ItemType Directory -Path $userPath -Force | Out-Null
        Write-Host "✅ Created user directory: $userPath"
    }
}

function New-OrderDirectory {
    param([string]$UserId, [string]$OrderId)

    if ([string]::IsNullOrEmpty($UserId) -or [string]::IsNullOrEmpty($OrderId)) {
        Write-Host "❌ Both UserId and OrderId are required for create-order action"
        return
    }

    $userPath = Join-Path (Get-BucketPath) $UserId
    $orderPath = Join-Path $userPath $OrderId

    # Ensure user directory exists first
    if (!(Test-Path $userPath)) {
        New-Item -ItemType Directory -Path $userPath -Force | Out-Null
        Write-Host "✅ Created user directory: $userPath"
    }

    if (Test-Path $orderPath) {
        Write-Host "ℹ️  Order directory already exists: $orderPath"
    } else {
        New-Item -ItemType Directory -Path $orderPath -Force | Out-Null
        Write-Host "✅ Created order directory: $orderPath"
    }
}

function Get-UserPaymentProofs {
    param([string]$UserId)

    if ([string]::IsNullOrEmpty($UserId)) {
        Write-Host "❌ UserId is required for list-user action"
        return
    }

    $userPath = Join-Path (Get-BucketPath) $UserId

    if (!(Test-Path $userPath)) {
        Write-Host "❌ User directory does not exist: $userPath"
        return
    }

    Write-Host "Payment proofs for user: $UserId"
    Write-Host "================================"

    $orderDirs = Get-ChildItem -Path $userPath -Directory

    if ($orderDirs.Count -eq 0) {
        Write-Host "📭 No payment proofs found for this user"
        return
    }

    foreach ($orderDir in $orderDirs) {
        Write-Host "📂 Order: $($orderDir.Name)"

        $files = Get-ChildItem -Path $orderDir.FullName -File
        if ($files.Count -eq 0) {
            Write-Host "  📭 No payment proofs for this order"
        } else {
            foreach ($file in $files) {
                $fileSizeMB = [math]::Round($file.Length / 1MB, 2)
                Write-Host "  File: $($file.Name) ($fileSizeMB MB) - $($file.LastWriteTime)"
            }
        }
    }
}

function Get-OrderPaymentProofs {
    param([string]$UserId, [string]$OrderId)

    if ([string]::IsNullOrEmpty($UserId) -or [string]::IsNullOrEmpty($OrderId)) {
        Write-Host "❌ Both UserId and OrderId are required for list-order action"
        return
    }

    $orderPath = Join-Path (Get-BucketPath) "$UserId\$OrderId"

    if (!(Test-Path $orderPath)) {
        Write-Host "❌ Order directory does not exist: $orderPath"
        return
    }

    Write-Host "Payment proofs for order: $OrderId (User: $UserId)"
    Write-Host "=================================================="

    $files = Get-ChildItem -Path $orderPath -File

    if ($files.Count -eq 0) {
        Write-Host "📭 No payment proofs found for this order"
        return
    }

    $totalSize = 0
    foreach ($file in $files) {
        $fileSizeMB = [math]::Round($file.Length / 1MB, 2)
        $totalSize += $file.Length
        Write-Host "📄 $($file.Name) ($fileSizeMB MB) - $($file.LastWriteTime)"
    }

    Write-Host ""
    Write-Host "📊 Total files: $($files.Count), Total size: $([math]::Round($totalSize / 1MB, 2)) MB"
}

function Clear-OldPaymentProofs {
    $bucketPath = Get-BucketPath
    $cutoffDate = (Get-Date).AddDays(-90) # 90 days retention

    Write-Host "Cleaning up payment proofs older than $($cutoffDate.ToShortDateString())"
    Write-Host "================================================================="

    $oldFiles = Get-ChildItem -Path $bucketPath -File -Recurse |
        Where-Object { $_.LastWriteTime -lt $cutoffDate }

    if ($oldFiles.Count -eq 0) {
        Write-Host "✅ No old payment proofs to clean up"
        return
    }

    $totalSize = ($oldFiles | Measure-Object -Property Length -Sum).Sum

    Write-Host "📁 Found $($oldFiles.Count) old files to remove ($([math]::Round($totalSize / 1MB, 2)) MB)"

    foreach ($file in $oldFiles) {
        Write-Host "🗑️  Removing: $($file.FullName)"
        Remove-Item -Path $file.FullName -Force
    }

    Write-Host "✅ Cleanup completed. Removed $($oldFiles.Count) files ($([math]::Round($totalSize / 1MB, 2)) MB saved)"
}

# Main script logic
if ($Help) {
    Show-Help
    exit
}

switch ($Action.ToLower()) {
    "status" {
        Show-BucketStatus
    }
    "create-user" {
        New-UserDirectory -UserId $UserId
    }
    "create-order" {
        New-OrderDirectory -UserId $UserId -OrderId $OrderId
    }
    "list-user" {
        Get-UserPaymentProofs -UserId $UserId
    }
    "list-order" {
        Get-OrderPaymentProofs -UserId $UserId -OrderId $OrderId
    }
    "cleanup" {
        Clear-OldPaymentProofs
    }
    default {
        Write-Host "❌ Unknown action: $Action"
        Write-Host ""
        Show-Help
    }
}