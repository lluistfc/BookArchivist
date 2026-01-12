# Code Coverage with Luacov

## Installation

```powershell
luarocks install luacov
```

## Running Tests with Coverage

### Method 1: Direct Busted Command

```powershell
# Run all tests with coverage
busted --coverage

# Run specific pattern with coverage
busted --coverage --pattern=ListSort

# Run with detailed output and coverage
busted --coverage --output=json
```

### Method 2: PowerShell Script

```powershell
# Run with coverage flag
.\scripts\run-tests.ps1 -Coverage

# Run specific pattern with coverage
.\scripts\run-tests.ps1 -Pattern "ListSort" -Coverage

# Run detailed with coverage
.\scripts\run-tests.ps1 -Detailed -Coverage
```

### Method 3: Make Commands

```bash
# Simple test with coverage
pwsh -File scripts/run-tests.ps1 -Coverage

# Detailed with coverage
pwsh -File scripts/run-tests.ps1 -Detailed -Coverage

# Pattern with coverage  
pwsh -File scripts/run-tests.ps1 -Pattern "ListSort" -Coverage
```

## Viewing Coverage Results

After running tests with `--coverage`, luacov generates:

1. **luacov.stats.out** - Raw coverage data
2. **luacov.report.out** - Human-readable coverage report

```powershell
# View coverage report
Get-Content luacov.report.out | Select-Object -First 50
```

## Coverage Report Format

```
==============================================================================
core/BookArchivist_Core.lua
==============================================================================
  1    local BookArchivist = BookArchivist or {}
  2    BookArchivist.Core = BookArchivist.Core or {}
  3*   
  4    local Core = BookArchivist.Core
...
```

- Lines with numbers: executed
- Lines with `*`: not executed
- Lines with `-`: not relevant (comments, blank lines)

## Configuration

Create `.luacov` config file to customize coverage:

```lua
return {
  -- Exclude test files from coverage
  exclude = {
    "Tests",
    "tests",
  },
  
  -- Include only addon files
  include = {
    "core",
    "ui",
  },
}
```

## Cleanup

```powershell
# Remove coverage files
Remove-Item luacov.stats.out, luacov.report.out -ErrorAction SilentlyContinue
```

## CI/CD Integration

```yaml
# GitHub Actions example
- name: Run tests with coverage
  run: busted --coverage

- name: Upload coverage report
  uses: actions/upload-artifact@v3
  with:
    name: coverage-report
    path: luacov.report.out
```

## Tips

- Run coverage periodically, not on every test run (slows down tests)
- Focus on core logic files, not UI wiring
- Aim for >80% coverage on core modules
- Use coverage to find untested edge cases
- Don't chase 100% - diminishing returns
