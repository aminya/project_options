FROM ubuntu:20.04 AS base

# add setup_cpp
ADD https://github.com/aminya/setup-cpp/releases/download/v0.21.0/setup_cpp_linux /setup_cpp_linux
RUN chmod +x /setup_cpp_linux


FROM base AS setup

ARG compiler="gcc"
# install cmake, ninja, and ccache
RUN /setup_cpp_linux --compiler $compiler --llvm true --cmake true --ninja true --ccache true --doxygen true --cppcheck true --vcpkg true --conan true --task true

# update vcpkg
WORKDIR /root/vcpkg
RUN git pull origin master
RUN ./vcpkg update
WORKDIR /

COPY ./docker/entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT [ "/docker-entrypoint.sh" ]


FROM setup AS build
COPY . /home/project_options
WORKDIR /home/project_options/test
CMD ["/home/project_options/docker/build.sh"]


FROM setup AS test
COPY . /home/project_options
WORKDIR /home/project_options/test
CMD ["/home/project_options/docker/test.sh"]


#FROM gcr.io/distroless/cc AS runner
#COPY --from=build /home/project_options/test/build/Release/ /home/app/
#WORKDIR /home/app/
#ENTRYPOINT ["./build/main"]




FROM setup AS build-alt
COPY . /home/project_options
WORKDIR /home/project_options/test_minimal
CMD ["/home/project_options/docker/build.sh"]


#FROM setup AS test-alt
#COPY . /home/project_options
#WORKDIR /home/project_options/test
#CMD ["/home/project_options/docker/test.sh"]