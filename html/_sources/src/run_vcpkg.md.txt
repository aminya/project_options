# `run_vcpkg`

Install vcpkg and vcpkg dependencies:

```cmake
run_vcpkg()
```

Or by specifying the options

```cmake
run_vcpkg(
    VCPKG_URL "https://github.com/microsoft/vcpkg.git"
    VCPKG_REV "33c8f025390f8682811629b6830d2d66ecedcaa5"
    ENABLE_VCPKG_UPDATE
)
```

Note that it should be called before defining `project()`.

Named Option:

- `ENABLE_VCPKG_UPDATE`: (Disabled by default). If enabled, the vcpkg registry is updated before building (using `git pull`).

  If `VCPKG_REV` is set to a specific commit sha, no rebuilds are triggered.
  If `VCPKG_REV` is not specified or is a branch, enabling `ENABLE_VCPKG_UPDATE` will rebuild your updated vcpkg dependencies.

Named String:

- `VCPKG_DIR`: (Defaults to `~/vcpkg`). You can provide the vcpkg installation directory using this optional parameter.
  If the directory does not exist, it will automatically install vcpkg in this directory.

- `VCPKG_URL`: (Defaults to `https://github.com/microsoft/vcpkg.git`). This option allows setting the URL of the vcpkg repository. By default, the official vcpkg repository is used.

- `VCPKG_REV`: This option allows checking out a specific branch name or a commit sha.
If `VCPKG_REV` is set to a specific commit sha, the builds will become reproducible because that exact commit is always used for the builds. To make sure that this commit sha is pulled, enable `ENABLE_VCPKG_UPDATE`
