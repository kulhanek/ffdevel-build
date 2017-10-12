# ffdevel-build
Utilities for testing and building of the [FFDevel](https://github.com/kulhanek/ffdevel) package.

## Building and Installation

### Testing Mode
```bash
$ git clone --recursive https://github.com/kulhanek/ffdevel-build.git
$ cd ffdevel-build
$ ./build-utils/00.init-links.sh
$ ./01.pull-code.sh
$ ./04.build-inline.sh      # build the code inline in src/
```

### Production Build into the Infinity software repository
```bash
$ git clone --recursive https://github.com/kulhanek/ffdevel-build.git
$ cd ffdevel-build
$ ./build-utils/00.init-links.sh
$ ./01.pull-code.sh
$ ./10.build-final.sh
```

