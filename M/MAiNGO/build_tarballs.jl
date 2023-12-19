# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MAiNGO"
version = v"0.7.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://git.rwth-aachen.de/avt-svt/public/maingo.git", "252733413a29dbe5b84a4cdaf53e60e9934f372f"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/maingo/
git remote set-url origin https://git.rwth-aachen.de/avt-svt/public/maingo.git
mkdir build
cd build
git submodule init
git submodule update -j 1


if [[ "${target}" == x86_64-apple-darwin* ]]; then
    export MACOSX_DEPLOYMENT_TARGET=10.15
    toolchain_file=${CMAKE_/TARGET_TOOLCHAIN%.*}_gcc.cmake
elif [[ "${target}" == *-freebsd* ]]; then
    toolchain_file=${CMAKE_/TARGET_TOOLCHAIN%.*}_gcc.cmake
else
    toolchain_file=${CMAKE_TARGET_TOOLCHAIN}
fi

cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${toolchain_file} \
      -DCMAKE_BUILD_TYPE=Release \
      -DMAiNGO_build_standalone=True \
      -DMAiNGO_build_shared_c_api=True \
      -DMAiNGO_build_parser=True \
      -DMAiNGO_use_cplex=False \
      -DMAiNGO_use_melon=False \
      ..


cmake --build . --config Release --parallel ${nproc}
install -Dvm 755 "MAiNGO${exeext}" "${bindir}/MAiNGO${exeext}"
install -Dvm 755 "MAiNGOcpp${exeext}" "${bindir}/MAiNGOcpp${exeext}"
install -Dvm 755 "libmaingo-c-api.${dlext}" "${libdir}/libmaingo-c-api.${dlext}"
install_license ../LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line


#Auditor complains about avx1.
#Without march the Auditor detects avx2
#but with march="avx2" avx512 is detected, so we build without march
#We expand only to gfortan 4 and 5 (others seem not to have std::variant)
#MacOS is in principle supported but requires newer SDK
#see https://github.com/JuliaPackaging/BinaryBuilder.jl/issues/1263 (wee need std::shared_ptr and std::weak_ptr with array support that needs XCode 12.0)
#FreeBsd builds only with gcc, that platform has not yet been sufficiently tested for inclusion.
platforms = [
    Platform("x86_64", "linux", libgfortran_version=v"4"),
    Platform("x86_64", "linux", libgfortran_version=v"5"),
    Platform("x86_64", "Windows", libgfortran_version=v"4"),
    Platform("x86_64", "Windows", libgfortran_version=v"5")]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libmaingo-c-api", :libmaingo_c_api),
    ExecutableProduct("MAiNGOcpp", :MAiNGOcpp),
    ExecutableProduct("MAiNGO", :MAiNGO)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"9")
