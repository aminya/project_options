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
CMD ["/bin/bash", "-c", "task build_minimal"]


FROM setup AS test
COPY . /home/project_options
WORKDIR /home/project_options
CMD ["/bin/bash", "-c", "task test"]


#FROM setup AS build_release
#COPY . /home/project_options
#WORKDIR /home/project_options
#CMD ["task build_release"]
#FROM gcr.io/distroless/cc AS runner
#COPY --from=build_release /home/project_options/test/build/Release/ /home/app/
#WORKDIR /home/app/
#ENTRYPOINT ["./build/main"]
