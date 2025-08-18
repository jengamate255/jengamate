param(
  [ValidateSet('run','build')] [string]$Action = 'run',
  [string]$Platform = 'web',
  [string]$EnvFile = '.env',
  [string]$Device = 'chrome',
  [switch]$TestCrash
)

if (!(Test-Path $EnvFile)) {
  Write-Host "Env file not found: $EnvFile" -ForegroundColor Red
  exit 1
}

$dartDefineArg = "--dart-define-from-file=$EnvFile"
$extraDefines = @()
if ($TestCrash) {
  $extraDefines += "--dart-define=TEST_CRASH_ON_START=true"
}

switch ($Platform) {
  'web' {
    if ($Action -eq 'run') {
      flutter run -d $Device $dartDefineArg @extraDefines
    } else {
      flutter build web $dartDefineArg @extraDefines
    }
  }
  'android' {
    if ($Action -eq 'run') {
      flutter run -d android $dartDefineArg @extraDefines
    } else {
      flutter build apk $dartDefineArg @extraDefines
    }
  }
  'ios' {
    if ($Action -eq 'run') {
      flutter run -d ios $dartDefineArg @extraDefines
    } else {
      flutter build ios $dartDefineArg @extraDefines
    }
  }
  'windows' {
    if ($Action -eq 'run') {
      flutter run -d windows $dartDefineArg @extraDefines
    } else {
      flutter build windows $dartDefineArg @extraDefines
    }
  }
  default {
    Write-Host "Unsupported platform: $Platform" -ForegroundColor Red
    exit 1
  }
}
