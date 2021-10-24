.PHONY: test format lint

test:
	cmake ./test -B ./test/build -DCMAKE_BUILD_TYPE:STRING=Debug -G Ninja
	cmake --build ./test/build --config Debug

format:
	clang-format -i ./test/*.cpp
	cmake-format --in-place ./Index.cmake ./src/*.cmake

lint:
	cmake-lint ./Index.cmake ./src/*.cmake

clean:
ifeq ($(OS), Windows_NT)
	cmd /c 'if exist test/build (rmdir /s /q test/build)'
else
	rm -rf ./tset/build
endif