# React Native Document Scanner AI - Auto Publisher (PowerShell)
# Usage: .\scripts\auto-publish.ps1 [-DryRun] [-Force] [-SkipTests] [-Help]

param(
    [switch]$DryRun,
    [switch]$Force,
    [switch]$SkipTests,
    [switch]$Help
)

function Write-ColoredOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Show-Help {
    Write-ColoredOutput "React Native Document Scanner AI - Auto Publisher" "Cyan"
    Write-ColoredOutput "=====================================================" "Cyan"
    Write-ColoredOutput ""
    Write-ColoredOutput "Usage: .\scripts\auto-publish.ps1 [options]" "Yellow"
    Write-ColoredOutput ""
    Write-ColoredOutput "Options:" "Yellow"
    Write-ColoredOutput "  -DryRun      Run in dry-run mode (no actual publishing)" "Gray"
    Write-ColoredOutput "  -Force       Force publish even if no changes detected" "Gray"
    Write-ColoredOutput "  -SkipTests   Skip running tests" "Gray"
    Write-ColoredOutput "  -Help        Show this help message" "Gray"
    Write-ColoredOutput ""
    Write-ColoredOutput "Examples:" "Yellow"
    Write-ColoredOutput "  .\scripts\auto-publish.ps1              # Check for changes and publish if found" "Gray"
    Write-ColoredOutput "  .\scripts\auto-publish.ps1 -DryRun      # See what would be published" "Gray"
    Write-ColoredOutput "  .\scripts\auto-publish.ps1 -Force       # Force publish regardless of changes" "Gray"
}

function Test-Changes {
    try {
        # Check if there are uncommitted changes
        $status = git status --porcelain
        if ($status) {
            Write-ColoredOutput "❌ You have uncommitted changes. Please commit or stash them first." "Red"
            return $false
        }

        # Check if we're ahead of origin
        $ahead = git rev-list --count HEAD ^origin/main 2>$null
        if (-not $ahead) { $ahead = "0" }
        if ([int]$ahead -gt 0) {
            Write-ColoredOutput "✅ Found $ahead commit(s) ahead of origin/main" "Green"
            return $true
        }

        # Check if there are changes since last tag
        try {
            $lastTag = git describe --tags --abbrev=0 2>$null
            if ($lastTag) {
                git diff --quiet $lastTag HEAD -- src/ lib/ package.json
                if ($LASTEXITCODE -eq 1) {
                    Write-ColoredOutput "✅ Found changes since last tag: $lastTag" "Green"
                    return $true
                }
            } else {
                Write-ColoredOutput "✅ No previous tags found, assuming first release" "Green"
                return $true
            }
        } catch {
            Write-ColoredOutput "✅ No previous tags found, assuming first release" "Green"
            return $true
        }

        Write-ColoredOutput "ℹ️  No changes detected that require publishing" "Cyan"
        return $false
    } catch {
        Write-ColoredOutput "❌ Error checking for changes: $($_.Exception.Message)" "Red"
        return $false
    }
}

function Invoke-Tests {
    Write-ColoredOutput "🧪 Running tests..." "Yellow"
    
    try {
        yarn lint
        if ($LASTEXITCODE -ne 0) { throw "Linting failed" }
        Write-ColoredOutput "✅ Linting passed" "Green"
        
        yarn typecheck
        if ($LASTEXITCODE -ne 0) { throw "Type checking failed" }
        Write-ColoredOutput "✅ Type checking passed" "Green"
        
        yarn test --passWithNoTests
        if ($LASTEXITCODE -ne 0) { throw "Tests failed" }
        Write-ColoredOutput "✅ Tests passed" "Green"
        
        return $true
    } catch {
        Write-ColoredOutput "❌ Tests failed: $($_.Exception.Message)" "Red"
        return $false
    }
}

function Build-Package {
    Write-ColoredOutput "🔨 Building package..." "Yellow"
    
    try {
        yarn prepare
        if ($LASTEXITCODE -ne 0) { throw "Build failed" }
        Write-ColoredOutput "✅ Package built successfully" "Green"
        return $true
    } catch {
        Write-ColoredOutput "❌ Build failed: $($_.Exception.Message)" "Red"
        return $false
    }
}

function Publish-Package {
    param([bool]$IsDryRun = $false)
    
    $action = if ($IsDryRun) { "🔍 Running dry-run release..." } else { "📦 Publishing package..." }
    Write-ColoredOutput $action "Yellow"
    
    try {
        $command = if ($IsDryRun) { "yarn release --dry-run" } else { "yarn release" }
        
        Invoke-Expression $command
        if ($LASTEXITCODE -ne 0) { throw "Release process failed" }
        
        $successMessage = if ($IsDryRun) { "✅ Dry-run completed successfully" } else { "✅ Package published successfully" }
        Write-ColoredOutput $successMessage "Green"
        return $true
    } catch {
        Write-ColoredOutput "❌ Publishing failed: $($_.Exception.Message)" "Red"
        return $false
    }
}

# Main execution
try {
    Write-ColoredOutput "🚀 React Native Document Scanner AI - Auto Publisher" "Cyan"
    Write-ColoredOutput "================================================" "Cyan"
    Write-ColoredOutput ""

    if ($Help) {
        Show-Help
        exit 0
    }

    # Check for changes (unless forced)
    if (-not $Force -and -not (Test-Changes)) {
        exit 0
    }

    # Run tests (unless skipped)
    if (-not $SkipTests -and -not (Invoke-Tests)) {
        exit 1
    }

    # Build package
    if (-not (Build-Package)) {
        exit 1
    }

    # Publish package
    if (-not (Publish-Package -IsDryRun $DryRun)) {
        exit 1
    }

    $completionMessage = if ($DryRun) { "🎉 Dry-run completed successfully!" } else { "🎉 Publishing completed successfully!" }
    Write-ColoredOutput "" 
    Write-ColoredOutput $completionMessage "Green"
    
    if (-not $DryRun) {
        Write-ColoredOutput ""
        Write-ColoredOutput "📋 Next steps:" "Yellow"
        Write-ColoredOutput "  • Check the GitHub release: https://github.com/AaronAnablon/React-Native-Document-Cleaner/releases" "Gray"
        Write-ColoredOutput "  • Verify the package on NPM: https://www.npmjs.com/package/react-native-document-scanner-ai" "Gray"
    }

} catch {
    Write-ColoredOutput "❌ Auto-publish failed: $($_.Exception.Message)" "Red"
    exit 1
}
