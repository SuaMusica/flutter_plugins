.PHONY: pub-get

PUBSPEC_DIRS := $(sort $(dir $(wildcard packages/*/pubspec.yaml)))

## Run flutter pub get in all packages containing pubspec.yaml
pub-get:
	@failed=""; \
	for dir in $(PUBSPEC_DIRS); do \
		echo "=> pub get: $$dir"; \
		(cd $$dir && flutter pub get) || failed="$$failed $$dir"; \
	done; \
	echo ""; \
	if [ -n "$$failed" ]; then \
		echo "FAILED in:$$failed"; \
		exit 1; \
	else \
		echo "All packages updated!"; \
	fi
