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

.PHONY: help test test-detailed test-errors test-verbose test-pattern clean

help:
ifeq ($(DETECTED_OS),Windows)
	@pwsh -NoProfile -Command "Write-Host 'BookArchivist Test Suite - Makefile' -ForegroundColor Cyan"
	@pwsh -NoProfile -Command "Write-Host ''"
	@pwsh -NoProfile -Command "Write-Host 'Detected OS: $(DETECTED_OS)' -ForegroundColor Yellow"
	@pwsh -NoProfile -Command "Write-Host ''"
	@pwsh -NoProfile -Command "Write-Host 'Available targets:' -ForegroundColor White"
	@pwsh -NoProfile -Command "Write-Host '  make test            - Run all tests (summary only)' -ForegroundColor Gray"
	@pwsh -NoProfile -Command "Write-Host '  make test-detailed   - Show all test results (JUnit-style)' -ForegroundColor Gray"
	@pwsh -NoProfile -Command "Write-Host '  make test-errors     - Show full error stack traces' -ForegroundColor Gray"
	@pwsh -NoProfile -Command "Write-Host '  make test-verbose    - Show raw busted output' -ForegroundColor Gray"
	@pwsh -NoProfile -Command "Write-Host '  make test-pattern    - Run specific tests (use PATTERN=name)' -ForegroundColor Gray"
	@pwsh -NoProfile -Command "Write-Host ''"
	@pwsh -NoProfile -Command "Write-Host 'Examples:' -ForegroundColor White"
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
	@echo "  make test            - Run all tests (summary only)"
	@echo "  make test-detailed   - Show all test results (JUnit-style)"
	@echo "  make test-errors     - Show full error stack traces"
	@echo "  make test-verbose    - Show raw busted output"
	@echo "  make test-pattern    - Run specific tests (use PATTERN=name)"
	@echo ""
	@echo "Examples:"
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
