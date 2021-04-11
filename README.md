zpp_mk
======

A really simple makefile based build system.

Table of Contents
-----------------
* [Motivation](#motivation)
* [First Project](#first-project)
* [Projecct Configuration](#project-configuration)
* [Project Settings Section](#project-settings-section)
* [Project Flags Section](#project-flags-section)
* [Project Rules Section](#project-rules-section)
* [Toolchain Settings Section](#toolchain-settings-section)
* [Cleaning and Rebuilding](#cleaning-and-rebuilding)
* [Multi Project Setup](#multi-project-setup)
* [Debug and Release Builds](#debug-and-release-builds)
* [Useful Variables set by `zpp.mk`](#useful-variables-set-by-zppmk)
* [Appendix](#appendix)

Motivation
----------
1. Requires just GNU make.
2. Minimal amount of settings.
3. Direct access to compiler flags.
4. Very flexible and customizable.
5. Short - just 200 lines of code.

First Project
-------------
Given the following file:
```cpp
#include <iostream>

int main()
{
    std::cout << "Hello World\n";
}
```
Create the following directory tree:
```
project
- src
  - main.cpp
- zpp.mk
- zpp_project.mk
```

The `zpp.mk` file contains the build system logic which is not intended to be modified.
The `zpp_project.mk` file contains project settings, compilation flags, and toolchain configuraion.

Run `make -f zpp.mk` or execute `./zpp.mk` to build the project.
The output will be like so:
```
Building 'default/output' in 'debug' mode...
Compiling 'src/main.cpp'...
Linking './out/debug/default/output'...
Built 'default/output'.
```

More on the `debug`/`default` directory names will be given later.

Project Configuration
---------------------
In order to configure the project, we need to understand and edit the contents of `zpp_project.mk` file.

### Project Settings Section
The first section of `zpp_project.mk` file contains some basic project configuration variables:
```make
ifeq ($(ZPP_PROJECT_SETTINGS), true)
ZPP_TARGET_NAME := output
ZPP_TARGET_TYPES := default
ZPP_LINK_TYPE := default
ZPP_CPP_MODULES_TYPE :=
ZPP_OUTPUT_DIRECTORY_ROOT := ./out
ZPP_INTERMEDIATE_DIRECTORY_ROOT = ./obj
ZPP_SOURCE_DIRECTORIES := ./src
ZPP_SOURCE_FILES :=
ZPP_INCLUDE_PROJECTS :=
ZPP_COMPILE_COMMANDS_JSON := compile_commands.json
endif
```
The content of this section must be enclosed with `ZPP_PROJECT_SETTINGS` condition
as shown to be selectively included when appropriate.

`ZPP_TARGET_NAME` is name of the output file that is produced from the build:

Example:
```make
ZPP_TARGET_NAME := hello_world_app
```

One or more target types for the build can be set via `ZPP_TARGET_TYPES`.
This can be used to repeat the build process with multiple configurations or architectures.
The build will loop the `ZPP_TARGET_TYPES` variable, allowing to access the current target
type using the `ZPP_TARGET_TYPE` variable. The `ZPP_TARGET_TYPE` is used as the name
of the output subdirectory of every target.

Example:
```make
ZPP_TARGET_TYPES := x86_64 aarch64
```
And checking is done via:
```make
ifeq ($(ZPP_TARGET_TYPE), x86_64)
    # Configure to compile for x86.
else ($(ZPP_TARGET_TYPE), aarch64)
    # Configure to compile for aarch64.
endif
```
You may pick a specific target type to build by adding `target_type=value` to the `make` command.

Next, is the `ZPP_LINK_TYPE`, which determines the strategy to link the final target file.
This variable may contain one of the following values:
* default - to use the compiler for linking, which is the most common way to link.
* ld - to use ld like interface directly for linking.
* link - to use link like interface for linking.
* ar - to use ar like interface for linking.

Example:
```make
ZPP_LINK_TYPE := default
```

The `ZPP_CPP_MODULES_TYPE` controls implementation type of C++20 modules. If empty, C++ modules
are disabled, otherwise, the only supported value is `ZPP_CPP_MODULES_TYPE := clang` which enables
clang modules. You will need to also set the `ZPP_CXXFLAGS` to include the `-fmodules` flag.

The current implementation is highly experimental, and turned off by default.
The following are known limitations of the current implementation:
1. Only clang is supported (tested clang-11 and above).
2. Currently there is no support for module partitions.
3. There is no optimization around finding module interfaces, any `C++` file is searched to
check if it a module interface (the `cppm` extension however was added as a valid `C++` file)

Example:
```make
ZPP_CPP_MODULES_TYPE := clang
```

The `ZPP_OUTPUT_DIRECTORY_ROOT` and `ZPP_INTERMEDIATE_DIRECTORY_ROOT` control the root directory
of the target output files and the intermediate files (object files, dependency, etc) respectively.

Example:
```make
# Note that this can be used to move the output directory to
# the parent folder to be able to organize multiple subproject outputs
# to the same place.
ZPP_OUTPUT_DIRECTORY_ROOT := ../out
ZPP_INTERMEDIATE_DIRECTORY_ROOT = ./obj
```

The `ZPP_SOURCE_DIRECTORIES` is a list of directories that will be searched by the build system
for source files ending with the following extensions: `*.cpp;*.cc;*.c;*.S`

Example:
```
ZPP_SOURCE_DIRECTORIES := ./src ../some_library/src
```

The `ZPP_SOURCE_FILES` allows to explicitly add additional source files to the build:

Example:
```
ZPP_SOURCE_FILES := ../external/src/external_lib.cpp ./src/main.cpp
```

The `ZPP_INCLUDE_PROJECTS` allows to use the main `zpp.mk` makefile to directly build multiple
projects and thereby ignore any other field that appears in the `zpp_project.mk`, while immediately
building the mentioned projects.
Example:
```
# Each project in this example is a subdirectory.
ZPP_INCLUDE_PROJECTS := project1 project2 project3
```

The `ZPP_COMPILE_COMMANDS_JSON` allows to control whether or not a `compile_commands.json` is generated.
This variable accepts the value of the compile commands file relative path.
If this variable is empty, no compile commands is generated.
It is possible to ask to generate the compile commands in the intermediate directories, for this, assign
the `intermediate` as the value of the variable.
Example:
```
# Place the compile commands inside the source tree.
ZPP_COMPILE_COMMANDS_JSON := compile_commands.json

# Place the compile commands in the intermediate directories.
ZPP_COMPILE_COMMANDS_JSON := intermediate

# Do not generate compile commands.
ZPP_COMPILE_COMMANDS_JSON :=
```

### Project Flags Section
This section which must be enclosed by the `ZPP_PROJECT_FLAGS` variable,
controls the compiler and linker flags, leaving most of the work to the
user so that it is as flexible as possible.

The following examples contains some basic flags for simple projects.
```make
ifeq ($(ZPP_PROJECT_FLAGS), true)
ZPP_FLAGS := \
	$(patsubst %, -I%, $(shell find . -type d -name "include")) \
	-pedantic -Wall -Wextra -Werror -fPIE
ZPP_FLAGS_DEBUG := -g
ZPP_FLAGS_RELEASE := \
	-O2 -flto -ffunction-sections \
	-fdata-sections -fvisibility=hidden
ZPP_CFLAGS := $(ZPP_FLAGS) -std=c11
ZPP_CFLAGS_DEBUG := $(ZPP_FLAGS_DEBUG)
ZPP_CFLAGS_RELEASE := $(ZPP_FLAGS_RELEASE)
ZPP_CXXFLAGS := $(ZPP_FLAGS) -std=c++17 -stdlib=libc++
ZPP_CXXFLAGS_DEBUG := $(ZPP_FLAGS_DEBUG)
ZPP_CXXFLAGS_RELEASE := $(ZPP_FLAGS_RELEASE)
ZPP_CXXMFLAGS := -fPIE
ZPP_CXXMFLAGS_DEBUG := -g
ZPP_CXXMFLAGS_RELEASE :=
ZPP_ASFLAGS := $(ZPP_FLAGS) -x assembler-with-cpp
ZPP_ASFLAGS_DEBUG := $(ZPP_FLAGS_DEBUG)
ZPP_ASFLAGS_RELEASE := $(ZPP_FLAGS_RELEASE)
ZPP_LFLAGS := $(ZPP_FLAGS) $(ZPP_CXXFLAGS) -pie -Wl,--no-undefined
ZPP_LFLAGS_DEBUG := $(ZPP_FLAGS_DEBUG)
ZPP_LFLAGS_RELEASE := $(ZPP_FLAGS_RELEASE) \
	-Wl,--strip-all -Wl,-flto -Wl,--gc-sections
ZPP_POSTLINK_COMMANDS :=
endif
```

The `ZPP_FLAGS` variable typically contains generic flags that will be passed to compilers.
This is a placeholder to be reused with the more specific C/C++/Assembly/Linker flags.
The following example shows how to add all directories named `include` with proper
include directory flags, as well as providing more generic compilation flags.
```make
ZPP_FLAGS := \
	$(patsubst %, -I%, $(shell find . -type d -name "include")) \
	-pedantic -Wall -Wextra -Werror -fPIE
```

The `ZPP_FLAGS_DEBUG`/`ZPP_FLAGS_RELEASE` are similar to `ZPP_FLAGS` only they are
specific to `debug`/`release` configurations, more on that later.

```make
# Generate debug information.
ZPP_FLAGS_DEBUG := -g

# Use optimizations and more typical release flags.
ZPP_FLAGS_RELEASE := \
	-O2 -flto -ffunction-sections \
	-fdata-sections -fvisibility=hidden
```

Next, are the `ZPP_CFLAGS`, `ZPP_CFLAGS_DEBUG`, and `ZPP_CFLAGS_RELEASE` which behave
similarily to `ZPP_FLAGS`, except they are to be used to compile C files.
Note that it is very common to add the generic flags prior to the C specific flags:
```make
ZPP_CFLAGS := $(ZPP_FLAGS) -std=c11
ZPP_CFLAGS_DEBUG := $(ZPP_FLAGS_DEBUG)
ZPP_CFLAGS_RELEASE := $(ZPP_FLAGS_RELEASE)
```

The `ZPP_CXXFLAGS`, `ZPP_CXXFLAGS_DEBUG`, and `ZPP_CXXFLAGS_RELEASE` are similar to their
C counterparts, only for C++:
```make
ZPP_CXXFLAGS := $(ZPP_FLAGS) -std=c++17 -stdlib=libc++
ZPP_CXXFLAGS_DEBUG := $(ZPP_FLAGS_DEBUG)
ZPP_CXXFLAGS_RELEASE := $(ZPP_FLAGS_RELEASE)
```

The `ZPP_CXXMFLAGS`, `ZPP_CXXMFLAGS_DEBUG`, and `ZPP_CXXMFLAGS_RELEASE` are used when
translating precompiled module files to object files.
```make
ZPP_CXXMFLAGS := -fPIE
ZPP_CXXMFLAGS_DEBUG := -g
ZPP_CXXMFLAGS_RELEASE :=
```

And again, for assembly files:
```make
ZPP_ASFLAGS := $(ZPP_FLAGS) -x assembler-with-cpp
ZPP_ASFLAGS_DEBUG := $(ZPP_FLAGS_DEBUG)
ZPP_ASFLAGS_RELEASE := $(ZPP_FLAGS_RELEASE)
```

The `ZPP_LFLAGS`, `ZPP_LFLAGS_DEBUG` and `ZPP_LFLAGS_RELEASE` are the flags
passed in the final link phase, again, generic ones, and debug/release specific ones:
```make
ZPP_LFLAGS := $(ZPP_FLAGS) $(ZPP_CXXFLAGS) -pie -Wl,--no-undefined
ZPP_LFLAGS_DEBUG := $(ZPP_FLAGS_DEBUG)

# In release, strip the output, and use link time optimizations.
ZPP_LFLAGS_RELEASE := $(ZPP_FLAGS_RELEASE) \
	-Wl,--strip-all -Wl,-flto -Wl,--gc-sections
```

The `ZPP_POSTLINK_COMMANDS` allows to run custom shell commands after linking,
for your convenience.

### Project Rules Section
The project rules section is a reserved space for custom rules that needs to take
place in some cases. This section must be enclosed with the `ZPP_PROJECT_RULES` variable.
Example of use of this section is to rebuild certain files whenever a manual dependency
on a file is needed, such as when an assembly file uses the `.incbin` directive and includes
a file from the filesystem:
```asm
; ./src/photo.S
photo:
   .incbin "../resources/photo.jpg"
```
The idea is that whenever `../resources/photo.jpg` changes, the assembly file has to
be rebuilt.
The following rules section achieves that:

```make
ifeq ($(ZPP_PROJECT_RULES), true)

$(ZPP_INTERMEDIATE_DIRECTORY)/./src/photo.o: \
	./resources/photo.jpg

endif
```

### Toolchain Settings Section
This section which must be enclosed by the `ZPP_TOOLCHAIN_SETTINGS` variable, has to export
the following functional tools:
* `ZPP_CC` - a C compiler.
* `ZPP_CXX` - a C++ compiler.
* `ZPP_AS` - an Assembly compiler.
* `ZPP_LINK` - a linker.
* `ZPP_AR` - the archiver.

A simple configuration to use normal installed clang compiler
would be:
```make
ifeq ($(ZPP_TOOLCHAIN_SETTINGS), true)
ZPP_CC := clang
ZPP_CXX := clang++
ZPP_AS := $(ZPP_CC)
ZPP_LINK := $(ZPP_CXX)
ZPP_AR := ar
ZPP_PYTHON := python3
endif
```
Note that here we use the `ZPP_CC` as assembly compiler as well, and
that we use `ZPP_CXX` as the linker.
Although this section is quite short, it can be made more complicated and allow
nice cross compilation solution.
One way to complicate this section without much overhead is to add an include
to the a proper toolchain configuration, for instance:
```make
ifeq ($(ZPP_TOOLCHAIN_SETTINGS), true)

ifeq ($(ZPP_TARGET_TYPE), x86_64-windows)
include win64_toolchain.mk
else ifeq ($(ZPP_TARGET_TYPE), aarch64-android)
include android_aarch64_toolchain.mk
else
include default_toolchain.mk
endif

endif
```

The `ZPP_PYTHON` is only required if the project settings ask to build the `compile_commands.json` file.

At the appendix section there is an example for a possible windows `toolchain.mk` file.

Cleaning and Rebuilding
-----------------------
To clean or rebuild the project, use `make -f zpp.mk clean`,
or `make -f zpp.mk rebuild` commands respectively.

Multi Project Setup
-------------------
Multi project set up is quite natural using this utility, it can even
be done in multiple ways. The idea is
to have a top level makefile that calls the bottom ones.

The easiest way is to just have the following tree:
```
solution:
- project1
  - include
  - src
  - zpp_project.mk
- project2
  - include
  - src
  - zpp_project.mk
- zpp.mk
```
Invoke the following command `make -f zpp.mk projects='project1 project2`.
Another way is to have a `zpp_project.mk` in the top level directory and define the
`ZPP_INCLUDE_PROJECTS` appropriately.

A more manual do-it-yourself way is to have the following project tree:
```
solution:
- project1
  - include
  - src
  - zpp_project.mk
- project2
  - include
  - src
  - zpp_project.mk
- zpp.mk
- makefile
```
The contents of the top level makefile can be:
```make
PROJECTS = project1 project2
all:
	@for project in $(PROJECTS) ; do \
		$(MAKE) -s -f ../zpp.mk -C $$project; \
	done

clean:
	@for project in $(PROJECTS) ; do \
		$(MAKE) -s -f ../zpp.mk -C $$project clean; \
	done

rebuild:
	@for project in $(PROJECTS) ; do \
		$(MAKE) -s -f ../zpp.mk -C $$project rebuild; \
	done
```

Remember you can set the following variable in every
`zpp_project.mk` file such that the output will be on the solution
folder rather than a separate output directory for each project.
```make
ZPP_OUTPUT_DIRECTORY_ROOT := ../out
```

Use `make -j` and observe the output.
```
Compiling 'src/main.cpp'...
Linking '../out/debug/default/output1'...
Built 'default/output1'.
Building 'default/output2' in 'debug' mode...
Compiling 'src/main.cpp'...
Linking '../out/debug/default/output2'...
Built 'default/output2'.
```

Debug and Release Builds
------------------------
You can add `mode=debug` or `mode=release` when compiling using the `make` command.
This way you can change between debug and release configuration. If unspecified, debug
configuration is selected.

Useful Variables set by `zpp.mk`
------------------------------------
Here are some useful variables to use inside the `zpp_project.mk`

* `ZPP_CONFIGURATION` - is either debug or release depending on the build configuration.
Available in all sections.
* `ZPP_INTERMEDIATE_DIRECTORY` - the intermediate files directory, not available on the
project settings section.
* `ZPP_OUTPUT_DIRECTORY` - the output directory, not availble on the project settings section.

Appendix
--------
A windows cross compile `toolchain.mk` file can look like this:
```make
# Sets VISUAL_STUDIO_ROOT, WINDOWS_KITS_ROOT, and WINDOWS_KITS_VERSION.
include windows_environment.config

ifeq ($(ZPP_TARGET_TYPE), x86)
	MICROSOFT_DEFINES := -D_MT -D_WIN32 -D_X86_
	VISUAL_STUDIO_PROCESSOR := x86
	WINDOWS_KITS_PROCESSOR := x86
else ifeq ($(ZPP_TARGET_TYPE), x86_64)
	MICROSOFT_DEFINES := -D_MT -D_WIN32 -D_WIN64 -D_AMD64_
	VISUAL_STUDIO_PROCESSOR := x64
	WINDOWS_KITS_PROCESSOR := x64
else
$(error Unsupported target)
endif

EMPTY :=
SPACE := $(EMPTY) $(EMPTY)

VISUAL_STUDIO_ROOT := $(subst $(SPACE),+,$(VISUAL_STUDIO_ROOT))
WINDOWS_KITS_ROOT := $(subst $(SPACE),+,$(WINDOWS_KITS_ROOT))

VISUAL_STUDIO_INCLUDES := $(VISUAL_STUDIO_ROOT)/include
VISUAL_STUDIO_LIBRARIES := $(VISUAL_STUDIO_ROOT)/lib/$(VISUAL_STUDIO_PROCESSOR)

WINDOWS_KITS_INCLUDES := \
	$(WINDOWS_KITS_ROOT)/Include/$(WINDOWS_KITS_VERSION)/km \
	$(WINDOWS_KITS_ROOT)/Include/$(WINDOWS_KITS_VERSION)/ucrt \
	$(WINDOWS_KITS_ROOT)/Include/$(WINDOWS_KITS_VERSION)/um \
	$(WINDOWS_KITS_ROOT)/Include/$(WINDOWS_KITS_VERSION)/shared \
	$(WINDOWS_KITS_ROOT)/Include/$(WINDOWS_KITS_VERSION)/winrt

WINDOWS_KITS_LIBRARIES := \
	$(WINDOWS_KITS_ROOT)/Lib/$(WINDOWS_KITS_VERSION)/ucrt/$(WINDOWS_KITS_PROCESSOR) \
	$(WINDOWS_KITS_ROOT)/Lib/$(WINDOWS_KITS_VERSION)/um/$(WINDOWS_KITS_PROCESSOR) \
	$(WINDOWS_KITS_ROOT)/Lib/$(WINDOWS_KITS_VERSION)/km/$(WINDOWS_KITS_PROCESSOR)

ENVIRONMENT_INCLUDES := $(WINDOWS_KITS_INCLUDES) $(VISUAL_STUDIO_INCLUDES)
ENVIRONMENT_LIBRARIES := $(VISUAL_STUDIO_LIBRARIES) $(WINDOWS_KITS_LIBRARIES)

ENVIRONMENT_INCLUDES := $(patsubst %, -isystem %, $(ENVIRONMENT_INCLUDES))
ENVIRONMENT_LIBRARIES := $(patsubst %, -L %, $(ENVIRONMENT_LIBRARIES))

ENVIRONMENT_INCLUDES := $(subst +,$(SPACE),$(ENVIRONMENT_INCLUDES))
ENVIRONMENT_LIBRARIES := $(subst +,$(SPACE),$(ENVIRONMENT_LIBRARIES))

ENVIRONMENT_FLAGS := \
	-target $(CLANG_TARGET) \
	-nostdinc \
	-D_CRT_SECURE_NO_WARNINGS \
	-D_CRT_SECURE_NO_DEPRECATE \
	-D_NO_CRT_STDIO_INLINE \
	$(MICROSOFT_DEFINES) \
	-U__GNUC__ \
	-U__gnu_linux__ \
	-U__GNUC_MINOR__ \
	-U__GNUC_PATCHLEVEL__ \
	-U__GNUC_STDC_INLINE__

ENVIRONMENT_LINK_FLAGS := \
	-fuse-ld=lld \
	-Wl,-ignore:4217

ZPP_CC := \
	clang \
	$(ENVIRONMENT_INCLUDES) \
	$(ENVIRONMENT_FLAGS)

ZPP_CXX := \
	clang++ \
	$(ENVIRONMENT_INCLUDES) \
	$(ENVIRONMENT_FLAGS)

ZPP_AS := $(ZPP_CC)
ZPP_LINK := \
	clang++ \
	-target $(CLANG_TARGET) \
	$(ENVIRONMENT_LIBRARIES) \
	$(ENVIRONMENT_LINK_FLAGS)
```

