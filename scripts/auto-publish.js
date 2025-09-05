#!/usr/bin/env node

const { execSync, spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

console.log('🚀 React Native Document Scanner AI - Auto Publisher');
console.log('================================================\n');

function run(command, options = {}) {
  try {
    const result = execSync(command, { 
      stdio: 'pipe', 
      encoding: 'utf8',
      ...options 
    });
    return result.trim();
  } catch (error) {
    throw new Error(`Command failed: ${command}\n${error.message}`);
  }
}

function hasChanges() {
  try {
    // Check if there are uncommitted changes
    const status = run('git status --porcelain');
    if (status) {
      console.log('❌ You have uncommitted changes. Please commit or stash them first.');
      return false;
    }

    // Check if we're ahead of origin
    const ahead = run('git rev-list --count HEAD ^origin/main 2>/dev/null || echo "0"');
    if (parseInt(ahead) > 0) {
      console.log(`✅ Found ${ahead} commit(s) ahead of origin/main`);
      return true;
    }

    // Check if there are changes since last tag
    try {
      const lastTag = run('git describe --tags --abbrev=0 2>/dev/null');
      const changesSinceTag = run(`git diff --quiet ${lastTag} HEAD -- src/ lib/ package.json; echo $?`);
      if (changesSinceTag === '1') {
        console.log(`✅ Found changes since last tag: ${lastTag}`);
        return true;
      }
    } catch (e) {
      console.log('✅ No previous tags found, assuming first release');
      return true;
    }

    console.log('ℹ️  No changes detected that require publishing');
    return false;
  } catch (error) {
    console.error('❌ Error checking for changes:', error.message);
    return false;
  }
}

function runTests() {
  console.log('🧪 Running tests...');
  try {
    run('yarn lint');
    console.log('✅ Linting passed');
    
    run('yarn typecheck');
    console.log('✅ Type checking passed');
    
    run('yarn test --passWithNoTests');
    console.log('✅ Tests passed');
    
    return true;
  } catch (error) {
    console.error('❌ Tests failed:', error.message);
    return false;
  }
}

function buildPackage() {
  console.log('🔨 Building package...');
  try {
    run('yarn prepare');
    console.log('✅ Package built successfully');
    return true;
  } catch (error) {
    console.error('❌ Build failed:', error.message);
    return false;
  }
}

function publishPackage(dryRun = false) {
  console.log(dryRun ? '🔍 Running dry-run release...' : '📦 Publishing package...');
  
  try {
    const command = dryRun ? 'yarn release --dry-run' : 'yarn release';
    
    if (dryRun) {
      run(command);
      console.log('✅ Dry-run completed successfully');
    } else {
      // For actual release, show output in real-time
      const child = spawn('yarn', ['release'], {
        stdio: 'inherit',
        shell: true
      });
      
      return new Promise((resolve, reject) => {
        child.on('close', (code) => {
          if (code === 0) {
            console.log('✅ Package published successfully');
            resolve(true);
          } else {
            reject(new Error(`Release process failed with code ${code}`));
          }
        });
      });
    }
    
    return true;
  } catch (error) {
    console.error('❌ Publishing failed:', error.message);
    return false;
  }
}

async function main() {
  // Parse command line arguments
  const args = process.argv.slice(2);
  const dryRun = args.includes('--dry-run') || args.includes('-d');
  const force = args.includes('--force') || args.includes('-f');
  const skipTests = args.includes('--skip-tests');

  if (args.includes('--help') || args.includes('-h')) {
    console.log(`
Usage: node scripts/auto-publish.js [options]

Options:
  --dry-run, -d     Run in dry-run mode (no actual publishing)
  --force, -f       Force publish even if no changes detected
  --skip-tests      Skip running tests
  --help, -h        Show this help message

Examples:
  node scripts/auto-publish.js              # Check for changes and publish if found
  node scripts/auto-publish.js --dry-run    # See what would be published
  node scripts/auto-publish.js --force      # Force publish regardless of changes
    `);
    process.exit(0);
  }

  try {
    // Check for changes (unless forced)
    if (!force && !hasChanges()) {
      process.exit(0);
    }

    // Run tests (unless skipped)
    if (!skipTests && !runTests()) {
      process.exit(1);
    }

    // Build package
    if (!buildPackage()) {
      process.exit(1);
    }

    // Publish package
    const success = await publishPackage(dryRun);
    if (!success) {
      process.exit(1);
    }

    console.log(`\n🎉 ${dryRun ? 'Dry-run' : 'Publishing'} completed successfully!`);
    
    if (!dryRun) {
      console.log('\n📋 Next steps:');
      console.log('  • Check the GitHub release: https://github.com/AaronAnablon/React-Native-Document-Cleaner/releases');
      console.log('  • Verify the package on NPM: https://www.npmjs.com/package/react-native-document-scanner-ai');
    }

  } catch (error) {
    console.error('❌ Auto-publish failed:', error.message);
    process.exit(1);
  }
}

if (require.main === module) {
  main().catch(console.error);
}

module.exports = { hasChanges, runTests, buildPackage, publishPackage };
