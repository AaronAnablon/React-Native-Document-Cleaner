# Automated Publishing Guide

This repository includes automated publishing capabilities for the `react-native-document-scanner-ai` package. Publishing can be done both locally and through GitHub Actions.

## 🚀 Quick Start

### Local Publishing (Recommended for Development)

**Windows (PowerShell):**
```powershell
# Check for changes and publish if found
npm run auto-publish:windows

# Dry run to see what would be published
npm run auto-publish:windows:dry-run

# Force publish regardless of changes
powershell -ExecutionPolicy Bypass -File scripts/auto-publish.ps1 -Force
```

**Unix/Linux/macOS:**
```bash
# Check for changes and publish if found
npm run auto-publish

# Dry run to see what would be published
npm run auto-publish:dry-run

# Force publish regardless of changes
npm run auto-publish:force
```

### GitHub Actions (Automatic)

The repository includes a GitHub Actions workflow that automatically:
- Detects changes in `src/`, `lib/`, or `package.json`
- Runs tests (lint, typecheck, unit tests)
- Builds the package
- Creates a new release with conventional changelog
- Publishes to NPM

## 📋 Prerequisites

### For Local Publishing

1. **Git configuration:**
   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "your.email@example.com"
   ```

2. **NPM authentication:**
   ```bash
   npm login
   # or set NPM_TOKEN environment variable
   ```

3. **GitHub token (for releases):**
   Set `GITHUB_TOKEN` environment variable or configure `gh` CLI

### For GitHub Actions

Set the following secrets in your GitHub repository:
- `NPM_TOKEN`: Your NPM automation token
- `GITHUB_TOKEN`: Automatically provided by GitHub

## 🔧 How It Works

### Local Scripts

The automation scripts (`auto-publish.js` and `auto-publish.ps1`) perform these steps:

1. **Change Detection:**
   - Checks for uncommitted changes (fails if found)
   - Compares current branch with `origin/main`
   - Checks for changes since last tag in `src/`, `lib/`, `package.json`

2. **Quality Checks:**
   - Runs ESLint (`npm run lint`)
   - Runs TypeScript type checking (`npm run typecheck`)
   - Runs Jest tests (`npm test`)

3. **Build & Release:**
   - Builds the package (`npm run prepare`)
   - Uses `release-it` to create version, tag, and GitHub release
   - Publishes to NPM

### GitHub Actions Workflow

The workflow (`.github/workflows/publish.yml`) triggers on:
- Pushes to `main` branch
- New tags matching `v*`
- Manual dispatch (with optional dry-run)

## 📝 Scripts Reference

### Local Scripts

| Command | Description |
|---------|-------------|
| `npm run auto-publish` | Auto-detect changes and publish (Unix/Linux/macOS) |
| `npm run auto-publish:dry-run` | Dry run mode - see what would happen |
| `npm run auto-publish:force` | Force publish even without detected changes |
| `npm run auto-publish:windows` | Auto-detect changes and publish (Windows) |
| `npm run auto-publish:windows:dry-run` | Dry run mode for Windows |

### Script Options

**Node.js script (`scripts/auto-publish.js`):**
```bash
node scripts/auto-publish.js [options]

Options:
  --dry-run, -d     Run in dry-run mode
  --force, -f       Force publish even if no changes detected
  --skip-tests      Skip running tests
  --help, -h        Show help message
```

**PowerShell script (`scripts/auto-publish.ps1`):**
```powershell
.\scripts\auto-publish.ps1 [options]

Options:
  -DryRun      Run in dry-run mode
  -Force       Force publish even if no changes detected
  -SkipTests   Skip running tests
  -Help        Show help message
```

## 🔄 Workflow Examples

### Development Workflow

1. Make changes to your code
2. Commit and push to your feature branch
3. Create pull request to `main`
4. After merge, GitHub Actions automatically publishes

### Manual Release

1. **Check what would be released:**
   ```bash
   npm run auto-publish:dry-run
   ```

2. **Publish if everything looks good:**
   ```bash
   npm run auto-publish
   ```

### Emergency Release

If you need to publish immediately:
```bash
npm run auto-publish:force
```

## 🛠️ Configuration

### Release-it Configuration

The `release-it` configuration in `package.json` handles:
- Conventional changelog generation
- GitHub release creation
- NPM publishing
- Git tagging

### GitHub Actions Configuration

The workflow can be customized by editing `.github/workflows/publish.yml`:
- Change trigger conditions
- Modify build steps
- Add additional quality checks

## 🐛 Troubleshooting

### Common Issues

1. **"No changes detected"**
   - Use `--force` flag if you need to publish anyway
   - Check if your changes are in tracked directories (`src/`, `lib/`, `package.json`)

2. **NPM authentication failed**
   - Run `npm login` locally
   - Check `NPM_TOKEN` secret in GitHub repository settings

3. **Git authentication failed**
   - Check `GITHUB_TOKEN` environment variable
   - Verify Git configuration

4. **Tests failing**
   - Fix the failing tests
   - Use `--skip-tests` flag only for emergency releases

### Debug Mode

For detailed output, run scripts directly:
```bash
# Node.js (with debug output)
DEBUG=* node scripts/auto-publish.js

# PowerShell (with verbose output)
.\scripts\auto-publish.ps1 -Verbose
```

## 📚 Related Documentation

- [release-it documentation](https://github.com/release-it/release-it)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [NPM Publishing Guide](https://docs.npmjs.com/packages-and-modules/contributing-packages-to-the-registry)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

## 🔐 Security Notes

- Never commit NPM tokens or other secrets to the repository
- Use GitHub's built-in secrets management for sensitive data
- Regularly rotate authentication tokens
- Review release notes before publishing to production
