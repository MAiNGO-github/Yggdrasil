# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MAiNGO"
version = v"0.7.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://git.rwth-aachen.de/avt-svt/public/maingo.git", "252733413a29dbe5b84a4cdaf53e60e9934f372f"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd maingo/
git remote set-url origin https://git.rwth-aachen.de/avt-svt/public/maingo.git
mkdir build
cd build
git submodule init
git submodule update -j 1
if [[ "${target}" == x86_64-apple-darwin* ]]; then
    export MACOSX_DEPLOYMENT_TARGET=10.15
    export CXXFLAGS="-mmacosx-version-min=10.15"
fi    
cmake -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DMAiNGO_build_standalone=True -DMAiNGO_build_shared_c_api=True -DMAiNGO_build_parser=True -DMAiNGO_use_cplex=False -DMAiNGO_use_melon=False  ..
cmake --build . --config Release --parallel ${nproc} > make_out.txt
mkdir -p ${libdir}
mkdir -p ${bindir}
find . -type f -name "*maingo-c-api.*" ! -name "*.cpp*" -exec cp '{}' ${libdir}/ \;
find . -type f -name "MAiNGO*" !  -name "*.cpp*" -exec cp '{}' ${bindir}/ \;
install_license ../LICENSE
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "windows"; ),
    Platform("x86_64", "linux"; libc = "musl")
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libmaingo-c-api", :libmaingo_c_api),
    ExecutableProduct("MAiNGOcpp", :MAiNGOcpp),
    ExecutableProduct("MAiNGO", :MAiNGO)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"13.2.0")