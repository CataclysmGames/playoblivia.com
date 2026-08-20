# Deploys the latest game build: bumps the patch version in VERSION,
# rewrites the repo's single release commit with all changes, and
# force-pushes to main (which triggers the Render deploy).
#
# History is deliberately kept to one commit — index.pck is ~90MB, so
# accumulating a copy per release would grow the repo without bound.
# Version tags are not used for the same reason (a tag would pin the
# old 90MB snapshot on the remote forever).
#
# The version lives in the VERSION file. Normally each deploy bumps
# the patch. To jump minor/major (e.g. 0.9.x -> 1.0.0), edit VERSION
# to the version you want first: if VERSION differs from the last
# commit, deploy ships it verbatim instead of bumping the patch.

VERSION_FILE := VERSION

CURRENT_VERSION := $(shell cat $(VERSION_FILE))
BUMPED_VERSION := $(shell echo $(CURRENT_VERSION) | awk -F. '{printf "%d.%d.%d", $$1, $$2, $$3 + 1}')
# If VERSION was hand-edited since the last release, ship it verbatim;
# otherwise bump the patch.
DEPLOY_VERSION := $(shell git diff --quiet HEAD -- $(VERSION_FILE) 2>/dev/null && echo $(BUMPED_VERSION) || cat $(VERSION_FILE))

# Set by the game repo's `make deploy-web` to the short hash of the source
# commit that produced this build; recorded in the release commit message.
SOURCE_COMMIT ?=
RELEASE_MSG := Release v$(DEPLOY_VERSION)$(if $(SOURCE_COMMIT), (source $(SOURCE_COMMIT)))

.PHONY: deploy version next-version

# Prints the version the next `make deploy` will ship (bump-or-verbatim),
# so the game repo can stamp the identical version into the build.
next-version:
	@echo "$(DEPLOY_VERSION)"

deploy:
	@if [ -z "$$(git status --porcelain)" ]; then echo "No changes to deploy."; exit 1; fi
	@echo "$(DEPLOY_VERSION)" > $(VERSION_FILE)
	@git add -A
	git commit --amend -m "$(RELEASE_MSG)"
	git push --force origin main
	@git reflog expire --expire=now --all
	@git gc --prune=now --quiet
	@echo "Deployed v$(DEPLOY_VERSION)"

version:
	@echo "current: v$(CURRENT_VERSION)"
	@echo "next:    v$(BUMPED_VERSION)"
