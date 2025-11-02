.PHONY: translate-check translate-sync

# Vérifier l'état des traductions
translate-check:
	@echo "📋 Translation Status:"
	@for file in docs/en/**/*.md; do \
		base=$$(basename $$file); \
		echo "\n📄 $$base:"; \
		[ -f "docs/fr/$${file#docs/en/}" ] && echo "  🇫🇷 ✅" || echo "  🇫🇷 ❌"; \
		[ -f "docs/ja/$${file#docs/en/}" ] && echo "  🇯🇵 ✅" || echo "  🇯🇵 ❌"; \
	done

# Créer les fichiers manquants avec un template
translate-sync:
	@echo "🔄 Creating missing translation files..."
	@for file in docs/en/**/*.md; do \
		for lang in fr ja; do \
			target="docs/$$lang/$${file#docs/en/}"; \
			if [ ! -f "$$target" ]; then \
				mkdir -p "$$(dirname $$target)"; \
				echo "# TODO: Translate from English" > "$$target"; \
				echo "⏳ Created: $$target"; \
			fi; \
		done; \
	done
