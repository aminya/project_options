FROM ubuntu:22.04 AS base

# add setup-cpp https://github.com/aminya/setup-cpp
RUN apt-get update && apt-get install -y \
  npm \
  && rm -rf /var/lib/apt/lists/*
RUN npm install -g setup-cpp

FROM base AS setup

ARG compiler="gcc"
# install cmake, ninja, and ccache
RUN setup-cpp --compiler $compiler --llvm true --cmake true --doxygen true --ninja true --ccache true --cppcheck true --vcpkg true --conan true --task true


COPY ./docker/entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT [ "/docker-entrypoint.sh" ]

FROM setup AS setup-custom-linker

# install linker
RUN apt-get update && apt-get install -y \
  binutils \
  mold \
  lld \
  && rm -rf /var/lib/apt/lists/*

FROM setup AS build
COPY . /home/project_options
WORKDIR /home/project_options
RUN git submodule update --init
CMD ["/bin/bash", "-c", "task myproj:build"]


FROM setup AS test
COPY . /home/project_options
WORKDIR /home/project_options
RUN git submodule update --init
CMD ["/bin/bash", "-c", "task myproj:test"]


FROM setup-custom-linker AS build-with-custom-linker
COPY . /home/project_options
WORKDIR /home/project_options
RUN git submodule update --init
CMD ["/bin/bash", "-c", "task myproj:build"]