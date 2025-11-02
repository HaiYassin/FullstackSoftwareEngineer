#!/bin/bash
# generate-i18n-structure.sh

LANGUAGES=("en" "fr" "ja")
CATEGORIES=("architecture" "development" "infrastructure")

for lang in "${LANGUAGES[@]}"; do
    mkdir -p "docs/$lang"
    
    for category in "${CATEGORIES[@]}"; do
        mkdir -p "docs/$lang/$category"
    done
    
    # Créer le README pour chaque langue
    cat > "docs/$lang/README.md" << EOF
# Documentation ($lang)

> 🌍 [English](../en/README.md) | [Français](../fr/README.md) | [日本語](../ja/README.md)

## Table of Contents

<!-- Add your language-specific content here -->
EOF
done

echo "✅ Structure created for languages: ${LANGUAGES[*]}"
