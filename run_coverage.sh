#!/bin/bash

# Coverage script for cue
# Runs Flutter tests with coverage and generates an HTML report (if lcov/genhtml available)


# Parse arguments
OPEN_HTML=false
for arg in "$@"; do
    if [[ "$arg" == "--open" ]]; then
        OPEN_HTML=true
    fi
done

set -e

echo "🧪 Running tests with coverage for cue"
echo "============================================"

# Clean previous coverage data
rm -rf coverage
mkdir -p coverage

# Run tests with coverage (prefer flutter, fall back to dart if available)
if command -v flutter >/dev/null 2>&1; then
    echo "Using Flutter: running 'flutter test --coverage'..."
    flutter test --coverage
elif command -v dart >/dev/null 2>&1; then
    echo "Flutter not found; using Dart: running 'dart test --coverage'..."
    dart test --coverage
else
    echo "⚠️  Neither 'flutter' nor 'dart' were found in PATH. Install Flutter or Dart and retry."
    exit 1
fi

echo ""
echo "📊 Coverage data generated!"
echo "============================================"

# Prefer genhtml (from lcov) for HTML generation
if command -v genhtml >/dev/null 2>&1; then
    echo "📈 Generating HTML coverage report with genhtml..."
    genhtml coverage/lcov.info -o coverage/html --quiet || true

    echo ""
    echo "✅ HTML coverage report generated at: coverage/html/index.html"
    echo ""

    # Open the report in the default browser (macOS/Linux) only if --open is passed
    if [ "$OPEN_HTML" = true ]; then
      if [[ "${OSTYPE:-}" == "darwin"* ]]; then
          echo "🌐 Opening coverage report in browser..."
          open coverage/html/index.html || true
      elif [[ "${OSTYPE:-}" == "linux-gnu"* ]]; then
          echo "🌐 Opening coverage report in browser..."
          xdg-open coverage/html/index.html || true
      fi
    fi
else
    echo ""
    echo "⚠️  'genhtml' (lcov) not found. To generate an HTML report install lcov:" 
    echo "   macOS: brew install lcov"
    echo "   Debian/Ubuntu: sudo apt-get install lcov"
    echo ""
    echo "📄 Raw coverage data is available at: coverage/lcov.info"
fi

echo ""
echo "📋 Coverage Summary:" 
echo "============================================"

# Show coverage summary if lcov is available
if command -v lcov >/dev/null 2>&1; then
    lcov --summary coverage/lcov.info 2>/dev/null || true
else
    # Fallback: compute simple line coverage percentage from lcov.info
    if [ -f coverage/lcov.info ]; then
        total_lines=$(grep -c "^DA:" coverage/lcov.info 2>/dev/null || echo "0")
        covered_lines=$(grep "^DA:" coverage/lcov.info 2>/dev/null | grep -v ",0$" | wc -l || echo "0")
        if [ "${total_lines}" -gt 0 ]; then
            percentage=$((covered_lines * 100 / total_lines))
            echo "Lines: ${covered_lines} / ${total_lines} (${percentage}%)"
        else
            echo "No DA: records found in coverage/lcov.info"
        fi
    else
        echo "coverage/lcov.info not found"
    fi
fi

echo ""
echo "🎉 Done!"
