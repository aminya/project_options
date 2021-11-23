.PHONY: test format lint

test:
	cmake ./test -B ./test/build -DCMAKE_BUILD_TYPE:STRING=Debug
	cmake --build ./test/build --config Debug
	cd ./test/build && ctest -C Debug --verbose

format:
	clang-format -i ./test/*.cpp
	cmake-format --in-place ./Index.cmake ./src/*.cmake

lint:
	cmake-lint ./Index.cmake ./src/*.cmake

clean:
# clean ./test/build
ifeq ($(OS), Windows_NT)
	pwsh -C 'if (Test-Path ./test/build) { rm -r -force ./test/build }'
else
	rm -rf ./test/build
endif