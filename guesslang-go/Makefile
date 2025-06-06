.PHONY: build clean test install integration-test

# Build the guesslang-autodetect binary
build:
	@echo "Building guesslang-autodetect..."
	mkdir -p bin
	go build -o bin/guesslang-autodetect ./cmd/guesslang-autodetect

# Install the binary to system PATH (requires sudo on Linux)
install: build
	@echo "Installing guesslang-autodetect to /usr/local/bin..."
	sudo cp bin/guesslang-autodetect /usr/local/bin/
	@echo "Installation complete!"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -rf bin/

# Test the functionality
test: build
	@echo "Testing guesslang-autodetect..."
	@echo "def hello():" > test.py
	@echo "    print('Hello World')" >> test.py
	@echo "Testing Python detection:"
	./bin/guesslang-autodetect test.py
	@echo ""
	@echo "function hello() {" > test.js
	@echo "    console.log('Hello World');" >> test.js
	@echo "}" >> test.js
	@echo "Testing JavaScript detection:"
	./bin/guesslang-autodetect test.js
	@echo ""
	@echo "Cleaning test files..."
	rm -f test.py test.js

# Run comprehensive integration tests (requires installation)
integration-test:
	@echo "Running integration tests..."
	chmod +x test-integration.sh
	./test-integration.sh

# Create necessary directories
bin:
	mkdir -p bin
