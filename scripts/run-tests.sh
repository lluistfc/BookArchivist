#!/usr/bin/env bash
# BookArchivist Test Runner (Unix/macOS)
# Quick and easy test execution with readable output

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
WHITE='\033[0;97m'
NC='\033[0m' # No Color

# Parse arguments
VERBOSE=false
DETAILED=false
SHOW_ERRORS=false
PATTERN=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -d|--detailed)
            DETAILED=true
            shift
            ;;
        -e|--show-errors)
            SHOW_ERRORS=true
            shift
            ;;
        -p|--pattern)
            PATTERN="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [-v|--verbose] [-d|--detailed] [-e|--show-errors] [-p|--pattern PATTERN]"
            exit 1
            ;;
    esac
done

# Script is in scripts/ folder, addon root is parent
ADDON_PATH="$(cd "$(dirname "$0")/.." && pwd)"

echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  BookArchivist Test Suite${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Check if busted is available
if ! command -v busted &> /dev/null; then
    echo -e "${RED}❌ Busted not found in PATH${NC}"
    echo -e "\n${YELLOW}Please ensure luarocks bin directory is in PATH:${NC}"
    echo -e "${GRAY}  ~/.luarocks/bin${NC}\n"
    exit 1
fi

# Build command
CMD="busted"
ARGS=()

if [ -n "$PATTERN" ]; then
    ARGS+=("--pattern=$PATTERN")
fi

# Run tests
echo -e "${YELLOW}Running tests...${NC}"
if [ -n "$PATTERN" ]; then
    echo -e "${GRAY}Pattern: $PATTERN${NC}"
fi
echo -e "${GRAY}Command: busted ${ARGS[*]}${NC}\n"

cd "$ADDON_PATH"

if $VERBOSE; then
    # Verbose mode: show full busted output
    busted "${ARGS[@]}"
elif $DETAILED; then
    # Detailed mode: show each test with pass/fail (JUnit-style)
    OUTPUT=$(busted --output=json "${ARGS[@]}" 2>&1)
    EXIT_CODE=$?
    
    if [ $EXIT_CODE -eq 0 ] || [ -n "$OUTPUT" ]; then
        # Parse JSON using jq if available, fallback to python
        if command -v jq &> /dev/null; then
            PASSED=$(echo "$OUTPUT" | jq '.successes | length')
            FAILED=$(echo "$OUTPUT" | jq '.failures | length')
            ERRORS=$(echo "$OUTPUT" | jq '.errors | length')
            DURATION=$(echo "$OUTPUT" | jq '.duration')
        elif command -v python3 &> /dev/null; then
            RESULT=$(python3 -c "
import json, sys
data = json.loads('''$OUTPUT''')
print(len(data.get('successes', [])))
print(len(data.get('failures', [])))
print(len(data.get('errors', [])))
print(round(data.get('duration', 0), 2))
")
            PASSED=$(echo "$RESULT" | sed -n '1p')
            FAILED=$(echo "$RESULT" | sed -n '2p')
            ERRORS=$(echo "$RESULT" | sed -n '3p')
            DURATION=$(echo "$RESULT" | sed -n '4p')
        else
            echo -e "${RED}❌ JSON parsing requires 'jq' or 'python3'${NC}"
            exit 1
        fi
        
        TOTAL=$((PASSED + FAILED + ERRORS))
        
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${CYAN}  TEST RESULTS${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
        
        # Show all successful tests
        if command -v jq &> /dev/null; then
            echo "$OUTPUT" | jq -r '.successes[] | "  ✓ \(.name)"' | while read -r line; do
                echo -e "${GREEN}$line${NC}"
            done
            
            # Show failures
            FAILURE_COUNT=$(echo "$OUTPUT" | jq '.failures | length')
            if [ "$FAILURE_COUNT" -gt 0 ]; then
                echo "$OUTPUT" | jq -r '.failures[] | "✗|\(.name)|\(.trace.message)"' | while IFS='|' read -r mark name msg; do
                    echo -e "${RED}  $mark $name${NC}"
                    if $SHOW_ERRORS; then
                        echo -e "${GRAY}    Message: $msg${NC}"
                        echo "$OUTPUT" | jq -r ".failures[] | select(.name==\"$name\") | .trace.traceback" | head -5 | while read -r trace; do
                            echo -e "${GRAY}    $trace${NC}"
                        done
                        echo ""
                    else
                        echo -e "${GRAY}    $msg${NC}"
                    fi
                done
            fi
            
            # Show errors
            ERROR_COUNT=$(echo "$OUTPUT" | jq '.errors | length')
            if [ "$ERROR_COUNT" -gt 0 ]; then
                echo "$OUTPUT" | jq -r '.errors[] | "⚠|\(.name)|\(.trace.message)"' | while IFS='|' read -r mark name msg; do
                    echo -e "${YELLOW}  $mark $name${NC}"
                    if $SHOW_ERRORS; then
                        echo -e "${GRAY}    Error: $msg${NC}"
                        echo "$OUTPUT" | jq -r ".errors[] | select(.name==\"$name\") | .trace.traceback" | head -5 | while read -r trace; do
                            echo -e "${GRAY}    $trace${NC}"
                        done
                        echo ""
                    fi
                done
            fi
        fi
        
        # Summary
        echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${CYAN}  SUMMARY${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${WHITE}  Total:  $TOTAL tests${NC}"
        echo -e "${GREEN}  Passed: $PASSED tests${NC}"
        if [ $((FAILED + ERRORS)) -eq 0 ]; then
            echo -e "${GREEN}  Failed: $((FAILED + ERRORS)) tests${NC}"
        else
            echo -e "${RED}  Failed: $((FAILED + ERRORS)) tests${NC}"
        fi
        echo -e "${GRAY}  Duration: ${DURATION}s${NC}\n"
        
        # Exit code
        if [ $((FAILED + ERRORS)) -gt 0 ]; then
            exit 1
        else
            echo -e "${GREEN}✓ All tests passed!${NC}"
            echo ""
            exit 0
        fi
    else
        echo -e "${RED}❌ Tests failed to run${NC}"
        exit 1
    fi
else
    # Normal mode: parse and format output
    OUTPUT=$(busted --output=json "${ARGS[@]}" 2>&1)
    EXIT_CODE=$?
    
    if [ $EXIT_CODE -eq 0 ] || [ -n "$OUTPUT" ]; then
        # Parse JSON using jq if available, fallback to python
        if command -v jq &> /dev/null; then
            PASSED=$(echo "$OUTPUT" | jq '.successes | length')
            FAILED=$(echo "$OUTPUT" | jq '.failures | length')
            ERRORS=$(echo "$OUTPUT" | jq '.errors | length')
            DURATION=$(echo "$OUTPUT" | jq '.duration')
        elif command -v python3 &> /dev/null; then
            RESULT=$(python3 -c "
import json, sys
data = json.loads('''$OUTPUT''')
print(len(data.get('successes', [])))
print(len(data.get('failures', [])))
print(len(data.get('errors', [])))
print(round(data.get('duration', 0), 2))
")
            PASSED=$(echo "$RESULT" | sed -n '1p')
            FAILED=$(echo "$RESULT" | sed -n '2p')
            ERRORS=$(echo "$RESULT" | sed -n '3p')
            DURATION=$(echo "$RESULT" | sed -n '4p')
        else
            echo -e "${RED}❌ JSON parsing requires 'jq' or 'python3'${NC}"
            exit 1
        fi
        
        TOTAL=$((PASSED + FAILED + ERRORS))
        
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${CYAN}  SUMMARY${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${WHITE}  Total:  $TOTAL tests${NC}"
        echo -e "${GREEN}  Passed: $PASSED tests${NC}"
        if [ $((FAILED + ERRORS)) -eq 0 ]; then
            echo -e "${GREEN}  Failed: $((FAILED + ERRORS)) tests${NC}"
        else
            echo -e "${RED}  Failed: $((FAILED + ERRORS)) tests${NC}"
        fi
        echo -e "${GRAY}  Duration: ${DURATION}s${NC}\n"
        
        # Show failures if any
        if [ "$FAILED" -gt 0 ]; then
            echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${RED}  FAILURES${NC}"
            echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            
            if command -v jq &> /dev/null; then
                echo "$OUTPUT" | jq -r '.failures[] | "✗|\(.name)|\(.trace.message)"' | while IFS='|' read -r mark name msg; do
                    echo -e "${RED}  $mark $name${NC}"
                    if $SHOW_ERRORS; then
                        echo -e "${GRAY}    Message: $msg${NC}"
                        echo "$OUTPUT" | jq -r ".failures[] | select(.name==\"$name\") | .trace.traceback" | head -5 | while read -r trace; do
                            echo -e "${GRAY}    $trace${NC}"
                        done
                        echo ""
                    else
                        echo -e "${GRAY}    $msg${NC}"
                    fi
                done
            fi
            echo ""
        fi
        
        # Show errors if any
        if [ "$ERRORS" -gt 0 ]; then
            echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${YELLOW}  ERRORS (InGame tests - expected to fail)${NC}"
            echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${GRAY}  $ERRORS InGame tests require WoW runtime${NC}"
            echo -e "${GRAY}  These will work once converted to native WoW tests${NC}\n"
        fi
        
        # Exit code
        if [ "$FAILED" -gt 0 ]; then
            exit 1
        else
            echo -e "${GREEN}✓ All Sandbox + Desktop tests passed!${NC}"
            echo ""
            exit 0
        fi
    else
        echo -e "${RED}❌ Tests failed to run${NC}"
        exit 1
    fi
fi
