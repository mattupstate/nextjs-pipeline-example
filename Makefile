SHELL := /bin/bash
CI ?= false
PROJECT_NAME ?= $(shell jq -r '.name' package.json)
PROJECT_VERSION ?= $(shell jq -r '.version' package.json)
GIT_BRANCH ?= $(shell git rev-parse --abbrev-ref HEAD)
GIT_COMMIT_SHA ?= $(shell git rev-parse --verify HEAD)
GIT_COMMIT_SHORT_SHA ?= $(shell git rev-parse --verify --short HEAD)
IMAGE_BASE_NAME ?= mattupstate/$(PROJECT_NAME)
TEST_IMAGE ?= $(IMAGE_BASE_NAME):$(GIT_BRANCH)-test
TEST_IMAGE_BUILD_TARGET ?= test
TEST_CONTAINER_NAME ?= $(PROJECT_NAME)-test
TEST_CONTAINER_SRC_DIR ?= /usr/src/app
ANALYSIS_CONTAINER_NAME ?= $(PROJECT_NAME)-analysis
AUDIT_CONTAINER_NAME ?= $(PROJECT_NAME)-audit
E2E_REPORTS_DIR ?= ./reports/e2e
E2E_REPORTS_SRC_DIR ?= $(TEST_CONTAINER_SRC_DIR)/reports/e2e
DIST_IMAGE_BUILD_TARGET ?= dist
DIST_IMAGE_NAME_VERSIONED ?= $(IMAGE_BASE_NAME):$(PROJECT_VERSION)
DIST_IMAGE_NAME_HASHED ?= $(IMAGE_BASE_NAME):$(GIT_COMMIT_SHORT_SHA)
DIST_IMAGE ?= $(IMAGE_BASE_NAME):$(GIT_BRANCH)
DIST_ARCHIVE_FILENAME ?= dist.tar
DIST_ARCHIVE_CONTAINER_NAME ?= $(PROJECT_NAME)-dist
DIST_ARCHIVE_SRC_DIR ?= /usr/share/app/dist
COVERAGE_DIR ?= ./coverage
LCOV_FILE ?= $(COVERAGE_DIR)/lcov.info
COVERAGE_SRC_DIR ?= $(TEST_CONTAINER_SRC_DIR)/coverage

.PHONY: test-image
test-image:
	docker build --pull --quiet --target $(TEST_IMAGE_BUILD_TARGET) --tag $(TEST_IMAGE) .

.PHONY: dist-image
dist-image:
	docker build --pull --quiet --target $(DIST_IMAGE_BUILD_TARGET) --tag $(DIST_IMAGE) .

.PHONY: dist-archive
dist-archive: dist-image
	@docker rm $(DIST_ARCHIVE_CONTAINER_NAME) 2&>/dev/null || :
	docker create --name $(DIST_ARCHIVE_CONTAINER_NAME) $(DIST_IMAGE)
	docker cp $(DIST_ARCHIVE_CONTAINER_NAME):$(DIST_ARCHIVE_SRC_DIR) - > $(DIST_ARCHIVE_FILENAME)

.PHONY: audit
audit: test-image
	@docker rm $(AUDIT_CONTAINER_NAME) 2&>/dev/null || :
	docker run --name $(AUDIT_CONTAINER_NAME) $(TEST_IMAGE) npm run audit-ci

.PHONY: analysis
analysis: test-image
	@docker rm $(ANALYSIS_CONTAINER_NAME) 2&>/dev/null || :
	docker run --name $(ANALYSIS_CONTAINER_NAME) $(TEST_IMAGE) npm run lint-ci

.PHONY: test
test: test-image
	@docker rm $(TEST_CONTAINER_NAME) 2&>/dev/null || :
	rm -rf $(COVERAGE_DIR)
	[[ "$(CI)" == "true" ]] && ./bin/cc-test-reporter before-build || :
	docker run --name $(TEST_CONTAINER_NAME) $(TEST_IMAGE) npm run test-ci
	docker cp $(TEST_CONTAINER_NAME):$(COVERAGE_SRC_DIR) $(COVERAGE_DIR)
	[[ "$(CI)" == "true" ]] && ./bin/cc-test-reporter format-coverage -o - -t lcov -p $(TEST_CONTAINER_SRC_DIR) $(COVERAGE_DIR)/lcov.info | ./bin/cc-test-reporter upload-coverage -i - || :

.PHONY: e2e
e2e: test-image dist-image
	rm -rf $(E2E_REPORTS_DIR)
	mkdir -p $(dir $(E2E_REPORTS_DIR))
	SELENIUM_CHROME_IMAGE=node-chrome SELENIUM_FIREFOX_IMAGE=node-firefox TEST_IMAGE=$(TEST_IMAGE) DIST_IMAGE=$(DIST_IMAGE) docker-compose down || :
	SELENIUM_CHROME_IMAGE=node-chrome SELENIUM_FIREFOX_IMAGE=node-firefox TEST_IMAGE=$(TEST_IMAGE) DIST_IMAGE=$(DIST_IMAGE) docker-compose up --abort-on-container-exit --exit-code-from webdriverio --force-recreate --remove-orphans --quiet-pull
	docker cp $$(SELENIUM_CHROME_IMAGE=node-chrome SELENIUM_FIREFOX_IMAGE=node-firefox TEST_IMAGE=$(TEST_IMAGE) DIST_IMAGE=$(DIST_IMAGE) docker-compose ps -q webdriverio):$(E2E_REPORTS_SRC_DIR) $(E2E_REPORTS_DIR)

.PHONY: e2e-debug
e2e-debug: dist-image
	SELENIUM_CHROME_IMAGE=node-chrome-debug SELENIUM_FIREFOX_IMAGE=node-firefox-debug docker-compose up chrome firefox webapp

.PHONY: build
build: test analysis audit e2e
	@echo "Build completed:"
	@echo "DOCKER_IMAGE=$(DIST_IMAGE)"

.PHONY: publish-image
publish-image:
	docker tag $(DIST_IMAGE) $(DIST_IMAGE_NAME_VERSIONED)
	docker tag $(DIST_IMAGE) $(DIST_IMAGE_NAME_HASHED)
	docker push $(DIST_IMAGE_NAME_VERSIONED)
	docker push $(DIST_IMAGE_NAME_HASHED)
