ifeq ($(ZPP_PROJECT_SETTINGS), true)
ZPP_TARGET_NAME := output
ZPP_TARGET_TYPES := default
ZPP_LINK_TYPE := default
ZPP_CPP_MODULES_TYPE :=
ZPP_OUTPUT_DIRECTORY_ROOT := out
ZPP_INTERMEDIATE_DIRECTORY_ROOT = obj
ZPP_SOURCE_DIRECTORIES := src
ZPP_SOURCE_FILES :=
ZPP_INCLUDE_PROJECTS :=
ZPP_COMPILE_COMMANDS_JSON := compile_commands.json
endif

ifeq ($(ZPP_PROJECT_FLAGS), true)
ZPP_FLAGS := \
	$(patsubst %, -I%, $(shell find . -type d -name "inc" -or -name "include")) \
	-pedantic -Wall -Wextra -Werror -fPIE
ZPP_FLAGS_DEBUG := -g
ZPP_FLAGS_RELEASE := \
	-O2 -DNDEBUG -flto -ffunction-sections \
	-fdata-sections -fvisibility=hidden
ZPP_CFLAGS := $(ZPP_FLAGS) -std=c11
ZPP_CFLAGS_DEBUG := $(ZPP_FLAGS_DEBUG)
ZPP_CFLAGS_RELEASE := $(ZPP_FLAGS_RELEASE)
ZPP_CXXFLAGS := $(ZPP_FLAGS) -std=c++20 -stdlib=libc++
ZPP_CXXFLAGS_DEBUG := $(ZPP_FLAGS_DEBUG)
ZPP_CXXFLAGS_RELEASE := $(ZPP_FLAGS_RELEASE)
ZPP_CXXMFLAGS := -fPIE
ZPP_CXXMFLAGS_DEBUG := -g
ZPP_CXXMFLAGS_RELEASE :=
ZPP_ASFLAGS := $(ZPP_FLAGS) -x assembler-with-cpp
ZPP_ASFLAGS_DEBUG := $(ZPP_FLAGS_DEBUG)
ZPP_ASFLAGS_RELEASE := $(ZPP_FLAGS_RELEASE)
ZPP_LFLAGS := $(ZPP_FLAGS) $(ZPP_CXXFLAGS) -fuse-ld=lld -Wl,-pie
ZPP_LFLAGS_DEBUG := $(ZPP_FLAGS_DEBUG)
ZPP_LFLAGS_RELEASE := $(ZPP_FLAGS_RELEASE) \
	-Wl,--strip-all -Wl,-flto -Wl,--gc-sections
endif

ifeq ($(ZPP_PROJECT_RULES), true)
endif

ifeq ($(ZPP_TOOLCHAIN_SETTINGS), true)
ZPP_CC := clang
ZPP_CXX := clang++
ZPP_AS := $(ZPP_CC)
ZPP_LINK := $(ZPP_CXX)
ZPP_AR := ar
ZPP_PYTHON := python3
ZPP_POSTLINK_COMMANDS :=
endif

