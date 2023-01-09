FROM ubuntu:22.04 AS base

ARG setup_cpp_linux_version="0.24.0"

# add setup_cpp
ADD https://github.com/aminya/setup-cpp/releases/download/v${setup_cpp_linux_version}/setup_cpp_linux /setup_cpp_linux
RUN chmod +x /setup_cpp_linux


FROM base AS setup

ARG compiler="gcc"
# install cmake, ninja, and ccache
RUN /setup_cpp_linux --compiler $compiler --llvm true --cmake true --ninja true --ccache true --cppcheck true --vcpkg true --conan true --task true


COPY ./docker/entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT [ "/docker-entrypoint.sh" ]


FROM setup AS build
COPY . /home/project_options
WORKDIR /home/project_options
CMD ["/bin/bash", "-c", "task minimal:build"]


FROM setup AS test
COPY . /home/project_options
WORKDIR /home/project_options
CMD ["/bin/bash", "-c", "task main:test"]

