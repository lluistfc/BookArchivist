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

.PHONY: help test test-detailed test-errors test-verbose test-pattern clean setup-mechanic check-mechanic

help:
ifeq ($(DETECTED_OS),Windows)
	@pwsh -NoProfile -Command "Write-Host 'BookArchivist Test Suite - Makefile' -ForegroundColor Cyan"
	@pwsh -NoProfile -Command "Write-Host ''"
	@pwsh -NoProfile -Command "Write-Host 'Detected OS: $(DETECTED_OS)' -ForegroundColor Yellow"
	@pwsh -NoProfile -Command "Write-Host ''"
	@pwsh -NoProfile -Command "Write-Host 'Available targets:' -ForegroundColor White"
	@pwsh -NoProfile -Command "Write-Host '  make setup-mechanic  - Install/setup Mechanic if not found' -ForegroundColor Gray"
	@pwsh -NoProfile -Command "Write-Host '  make check-mechanic  - Verify Mechanic installation' -ForegroundColor Gray"
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
	@echo "Detected OS: $(DETECTED_OS)"
	@echo ""
	@echo "Available targets:"
	@echo "  make setup-mechanic  - Install/setup Mechanic if not found"
	@echo "  make check-mechanic  - Verify Mechanic installation"
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
	@pwsh -NoProfile -Command "Write-Host 'Setting up Mechanic...' -ForegroundColor Cyan"
	@pwsh -NoProfile -Command "if (Test-Path '$(MECHANIC_DIR)') { Write-Host '✓ Mechanic directory already exists' -ForegroundColor Green } else { Write-Host 'Cloning Mechanic from $(MECHANIC_REPO)...' -ForegroundColor Yellow; git clone $(MECHANIC_REPO) $(MECHANIC_DIR) }"
	@pwsh -NoProfile -Command "Write-Host 'Installing Python dependencies...' -ForegroundColor Yellow"
	@pwsh -NoProfile -Command "cd $(MECHANIC_DIR)/desktop; if (-not (Test-Path 'venv')) { python -m venv venv }; .\\venv\\Scripts\\Activate.ps1; pip install --upgrade pip; pip install -e ."
	@pwsh -NoProfile -Command "Write-Host '✓ Mechanic setup complete!' -ForegroundColor Green"
	@pwsh -NoProfile -Command "Write-Host 'Mechanic CLI available at: $(MECHANIC_CLI)' -ForegroundColor Cyan"
else
	@echo "Setting up Mechanic..."
	@if [ -d "$(MECHANIC_DIR)" ]; then \
		echo "✓ Mechanic directory already exists"; \
	else \
		echo "Cloning Mechanic from $(MECHANIC_REPO)..."; \
		git clone $(MECHANIC_REPO) $(MECHANIC_DIR); \
	fi
	@echo "Installing Python dependencies..."
	@cd $(MECHANIC_DIR)/desktop && \
		if [ ! -d "venv" ]; then python3 -m venv venv; fi && \
		. venv/bin/activate && \
		pip install --upgrade pip && \
		pip install -e .
	@echo "✓ Mechanic setup complete!"
	@echo "Mechanic CLI available at: $(MECHANIC_CLI)"
endif
