# BookArchivist Test Runner Makefile
# Cross-platform test execution

# Detect OS
ifeq ($(OS),Windows_NT)
    DETECTED_OS := Windows
else
    UNAME_S := $(shell uname -s)
    ifeq ($(UNAME_S),Linux)
        DETECTED_OS := Linux
    endif
    ifeq ($(UNAME_S),Darwin)
        DETECTED_OS := macOS
    endif
endif

# Mechanic paths (adjust if your setup is different)
# Override with: make MECHANIC_DIR=/path/to/mechanic setup-mechanic
MECHANIC_DIR ?= ../../_dev_/Mechanic
MECHANIC_REPO := https://github.com/Falkicon/Mechanic.git

# Check if mech is in PATH first, otherwise use local venv
ifeq ($(DETECTED_OS),Windows)
    MECH_IN_PATH := $(shell where mech.exe 2>nul)
    ifneq ($(MECH_IN_PATH),)
        MECHANIC_CLI := mech.exe
    else
        MECHANIC_CLI := $(MECHANIC_DIR)/desktop/venv/Scripts/mech.exe
    endif
else
    MECH_IN_PATH := $(shell which mech 2>/dev/null)
    ifneq ($(MECH_IN_PATH),)
        MECHANIC_CLI := mech
    else
        MECHANIC_CLI := $(MECHANIC_DIR)/desktop/venv/bin/mech
    endif
endif

# Set test command based on OS
ifeq ($(DETECTED_OS),Windows)
    TEST_CMD := pwsh -ExecutionPolicy Bypass -File Tests/run-tests.ps1
    CHMOD :=
else
    TEST_CMD := ./Tests/run-tests.sh
    CHMOD := chmod +x Tests/run-tests.sh &&
endif

# Pattern variable for filtering tests
PATTERN ?=

.PHONY: help test test-detailed test-errors test-verbose test-pattern clean setup-mechanic check-mechanic validate lint output sync sandbox

help:
ifeq ($(DETECTED_OS),Windows)
	@pwsh -NoProfile -Command "Write-Host 'BookArchivist Test Suite - Makefile' -ForegroundColor Cyan"
	@pwsh -NoProfile -Command "Write-Host ''"
	@pwsh -NoProfile -Command "Write-Host 'Detected OS: $(DETECTED_OS)' -ForegroundColor Yellow"
	@pwsh -NoProfile -Command "Write-Host ''"
	@pwsh -NoProfile -Command "Write-Host 'Mechanic Integration:' -ForegroundColor White"
	@pwsh -NoProfile -Command "Write-Host '  make check-mechanic  - Verify Mechanic CLI is available' -ForegroundColor Gray"
	@pwsh -NoProfile -Command "Write-Host '  make setup-mechanic  - Clone and install Mechanic (if needed)' -ForegroundColor Gray"
	@pwsh -NoProfile -Command "Write-Host '  make validate        - Validate addon structure (.toc, files)' -ForegroundColor Gray"
	@pwsh -NoProfile -Command "Write-Host '  make lint            - Run Luacheck linter' -ForegroundColor Gray"
	@pwsh -NoProfile -Command "Write-Host '  make output          - Get addon output (errors, tests, logs)' -ForegroundColor Gray"
	@pwsh -NoProfile -Command "Write-Host '  make sync            - Sync addon to WoW clients' -ForegroundColor Gray"
	@pwsh -NoProfile -Command "Write-Host '  make sandbox         - Run sandbox tests (fast ~30ms)' -ForegroundColor Gray"
	@pwsh -NoProfile -Command "Write-Host ''"
	@pwsh -NoProfile -Command "Write-Host 'Test Targets:' -ForegroundColor White"
	@pwsh -NoProfile -Command "Write-Host '  make test            - Run all tests (summary only)' -ForegroundColor Gray"
	@pwsh -NoProfile -Command "Write-Host '  make test-detailed   - Show all test results (JUnit-style)' -ForegroundColor Gray"
	@pwsh -NoProfile -Command "Write-Host '  make test-errors     - Show full error stack traces' -ForegroundColor Gray"
	@pwsh -NoProfile -Command "Write-Host '  make test-verbose    - Show raw busted output' -ForegroundColor Gray"
	@pwsh -NoProfile -Command "Write-Host '  make test-pattern    - Run specific tests (use PATTERN=name)' -ForegroundColor Gray"
	@pwsh -NoProfile -Command "Write-Host ''"
	@pwsh -NoProfile -Command "Write-Host 'Examples:' -ForegroundColor White"
	@pwsh -NoProfile -Command "Write-Host '  make setup-mechanic' -ForegroundColor Green"
	@pwsh -NoProfile -Command "Write-Host '  make test' -ForegroundColor Green"
	@pwsh -NoProfile -Command "Write-Host '  make test-detailed' -ForegroundColor Green"
	@pwsh -NoProfile -Command "Write-Host '  make test-pattern PATTERN=Base64' -ForegroundColor Green"
	@pwsh -NoProfile -Command "Write-Host ''"
else
	@echo "BookArchivist Test Suite - Makefile"
	@echo ""
	@echo "  make validate        - Validate addon structure (.toc, files)"
	@echo "  make lint            - Run Luacheck linter"
	@echo "  make output          - Get addon output (errors, tests, logs)"
	@echo "  make sync            - Sync addon to WoW clients"
	@echo "  make sandbox         - Run sandbox tests (fast ~30ms)"
	@echo "Detected OS: $(DETECTED_OS)"
	@echo ""
	@echo "Mechanic Integration:"
	@echo "  make check-mechanic  - Verify Mechanic CLI is available"
	@echo "  make setup-mechanic  - Clone and install Mechanic (if needed)"
	@echo ""
	@echo "Test Targets:"
	@echo "  make test            - Run all tests (summary only)"
	@echo "  make test-detailed   - Show all test results (JUnit-style)"
	@echo "  make test-errors     - Show full error stack traces"
	@echo "  make test-verbose    - Show raw busted output"
	@echo "  make test-pattern    - Run specific tests (use PATTERN=name)"
	@echo ""
	@echo "Examples:"
	@echo "  make setup-mechanic"
	@echo "  make test"
	@echo "  make test-detailed"
	@echo "  make test-pattern PATTERN=Base64"
	@echo ""
endif

test:
	@echo "Running tests on $(DETECTED_OS)..."
	@$(CHMOD) $(TEST_CMD)

test-detailed:
	@echo "Running tests (detailed) on $(DETECTED_OS)..."
ifeq ($(DETECTED_OS),Windows)
	@$(TEST_CMD) -Detailed
else
	@$(CHMOD) $(TEST_CMD) -d
endif

test-errors:
	@echo "Running tests (with errors) on $(DETECTED_OS)..."
ifeq ($(DETECTED_OS),Windows)
	@$(TEST_CMD) -Detailed -ShowErrors
else
	@$(CHMOD) $(TEST_CMD) -d -e
endif

test-verbose:
	@echo "Running tests (verbose) on $(DETECTED_OS)..."
ifeq ($(DETECTED_OS),Windows)
	@$(TEST_CMD) -Verbose
else
	@$(CHMOD) $(TEST_CMD) -v
endif

test-pattern:
ifndef PATTERN
	@echo "Error: PATTERN not specified"
	@echo "Usage: make test-pattern PATTERN=Base64"
	@exit 1
endif
	@echo "Running tests matching '$(PATTERN)' on $(DETECTED_OS)..."
ifeq ($(DETECTED_OS),Windows)
	@$(TEST_CMD) -Pattern "$(PATTERN)"
else
	@$(CHMOD) $(TEST_CMD) -p "$(PATTERN)"
endif

# Alias targets
detailed: test-detailed
errors: test-errors
verbose: test-verbose
pattern: test-pattern

# Mechanic setup and verification
check-mechanic:
ifeq ($(DETECTED_OS),Windows)
	@pwsh -NoProfile -Command "Write-Host 'Checking Mechanic installation...' -ForegroundColor Cyan"
	@pwsh -NoProfile -Command "if (Get-Command $(MECHANIC_CLI) -ErrorAction SilentlyContinue) { Write-Host '✓ Mechanic CLI found: $(MECHANIC_CLI)' -ForegroundColor Green; exit 0 } else { Write-Host '✗ Mechanic CLI not found' -ForegroundColor Red; Write-Host 'Run: make setup-mechanic' -ForegroundColor Yellow; exit 1 }"
else
	@echo "Checking Mechanic installation..."
	@if command -v "$(MECHANIC_CLI)" >/dev/null 2>&1; then \
		echo "✓ Mechanic CLI found: $(MECHANIC_CLI)"; \
	else \
		echo "✗ Mechanic CLI not found"; \
		echo "Run: make setup-mechanic"; \
		exit 1; \
	fi
endif

setup-mechanic:
ifeq ($(DETECTED_OS),Windows)
	@pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/setup-mechanic.ps1 "$(MECHANIC_DIR)" "$(MECHANIC_REPO)"
else
	@chmod +x scripts/setup-mechanic.sh
	@./scripts/setup-mechanic.sh "$(MECHANIC_DIR)" "$(MECHANIC_REPO)"
endif

# Mechanic commands
validate:
	@$(MECHANIC_CLI) call addon.validate "{\"addon\": \"BookArchivist\"}"

lint:
	@$(MECHANIC_CLI) call addon.lint "{\"addon\": \"BookArchivist\"}"

output:
	@$(MECHANIC_CLI) call addon.output "{\"addon\": \"BookArchivist\", \"agent_mode\": true}"

sync:
	@$(MECHANIC_CLI) call addon.sync "{\"addon\": \"BookArchivist\"}"

sandbox:
	@$(MECHANIC_CLI) call sandbox.test "{\"addon\": \"BookArchivist\"}"

