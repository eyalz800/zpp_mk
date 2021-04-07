#!/usr/bin/make -f
.SUFFIXES:
.SECONDARY:
.PHONY: \
	all \
	build \
	build_single \
	build_init \
	build_dep_init \
	rebuild \
	rebuild_single \
	clean_mode \
	clean \
	clean_single

mode ?= debug
assembly ?= false
target_type ?=
projects ?=

ifeq ($(filter $(mode), debug release), )
$(error Mode must either be debug or release)
endif

ZPP_CONFIGURATION := $(mode)
ZPP_GENERATE_ASSEMBLY := $(assembly)
ZPP_TARGET_TYPE := $(target_type)

all: build
ZPP_THIS_MAKEFILE := $(lastword $(MAKEFILE_LIST))
ZPP_OUTPUT_DIRECTORY_ROOT := out
ZPP_INTERMEDIATE_DIRECTORY_ROOT := obj

ifeq ($(projects), )
ZPP_PROJECT_SETTINGS := true
include zpp_project.mk
ZPP_PROJECT_SETTINGS := false
endif

ifeq ($(ZPP_INCLUDE_PROJECTS), )
ZPP_INCLUDE_PROJECTS := $(projects)
endif

ifneq ($(ZPP_INCLUDE_PROJECTS), )
ZPP_PROJECTS_DIRECTORIES := $(ZPP_INCLUDE_PROJECTS)
ZPP_INCLUDE_PROJECTS :=

build:
	@for project in $(ZPP_PROJECTS_DIRECTORIES); do \
		$(MAKE) projects= -s -f `realpath $(ZPP_THIS_MAKEFILE) --relative-to $$project` -C $$project; \
	done
clean:
	@for project in $(ZPP_PROJECTS_DIRECTORIES); do \
		$(MAKE) projects= -s -f `realpath $(ZPP_THIS_MAKEFILE) --relative-to $$project` -C $$project clean ZPP_SKIP_DEPENDENCIES=true ; \
	done
rebuild:
	@for project in $(ZPP_PROJECTS_DIRECTORIES); do \
		$(MAKE) projects= -s -f `realpath $(ZPP_THIS_MAKEFILE) --relative-to $$project` -C $$project rebuild ZPP_SKIP_DEPENDENCIES=true ; \
	done

else # ifneq ($(ZPP_INCLUDE_PROJECTS), )
ifeq ($(ZPP_TARGET_TYPE), )
build:
	@for target_type in $(ZPP_TARGET_TYPES); do \
		$(MAKE) -s -f $(ZPP_THIS_MAKEFILE) ZPP_TARGET_TYPE=$$target_type; \
	done
clean:
	@for target_type in $(ZPP_TARGET_TYPES); do \
		$(MAKE) -s -f $(ZPP_THIS_MAKEFILE) clean ZPP_SKIP_DEPENDENCIES=true ZPP_TARGET_TYPE=$$target_type; \
	done
rebuild:
	@for target_type in $(ZPP_TARGET_TYPES); do \
		$(MAKE) -s -f $(ZPP_THIS_MAKEFILE) rebuild ZPP_SKIP_DEPENDENCIES=true ZPP_TARGET_TYPE=$$target_type; \
	done
else
build: build_single
clean: clean_single
rebuild: rebuild_single

ifeq ($(filter $(ZPP_TARGET_TYPE), $(ZPP_TARGET_TYPES)), )
$(error Invalid target type)
endif

ifeq ($(ZPP_SOURCE_DIRECTORIES), )
ZPP_SOURCE_FILES := $(ZPP_SOURCE_FILES)
else
ZPP_SOURCE_FILES := $(ZPP_SOURCE_FILES) \
	$(shell find $(ZPP_SOURCE_DIRECTORIES) -type f -name "*.S") \
	$(shell find $(ZPP_SOURCE_DIRECTORIES) -type f -name "*.c") \
	$(shell find $(ZPP_SOURCE_DIRECTORIES) -type f -name "*.cc") \
	$(shell find $(ZPP_SOURCE_DIRECTORIES) -type f -name "*.cpp") \
	$(shell find $(ZPP_SOURCE_DIRECTORIES) -type f -name "*.cppm")
endif

ifeq ($(strip $(ZPP_SOURCE_FILES)), )
$(error No source files)
endif

ZPP_INTERMEDIATE_DIRECTORY := $(ZPP_INTERMEDIATE_DIRECTORY_ROOT)/$(ZPP_CONFIGURATION)/$(ZPP_TARGET_TYPE)
ZPP_OUTPUT_DIRECTORY := $(ZPP_OUTPUT_DIRECTORY_ROOT)/$(ZPP_CONFIGURATION)/$(ZPP_TARGET_TYPE)
ZPP_COMPILE_COMMANDS_PATHS := $(ZPP_INTERMEDIATE_DIRECTORY)

ZPP_PATH_FROM_ROOT := $(shell echo $(ZPP_SOURCE_FILES) | grep -o "\(\.\./\)*" | sort --unique | tail -n 1)
ifneq ($(ZPP_PATH_FROM_ROOT), )
ZPP_INTERMEDIATE_SUBDIRECTORY := $(shell realpath . --relative-to $(ZPP_PATH_FROM_ROOT))
ZPP_INTERMEDIATE_DIRECTORY := $(ZPP_INTERMEDIATE_DIRECTORY)/$(ZPP_INTERMEDIATE_SUBDIRECTORY)
endif

ifeq ($(ZPP_COMPILE_COMMANDS_JSON), intermediate)
ZPP_COMPILE_COMMANDS_JSON := $(ZPP_INTERMEDIATE_DIRECTORY)/compile_commands.json
endif

ZPP_TOOLCHAIN_SETTINGS := true
include zpp_project.mk
ZPP_TOOLCHAIN_SETTINGS := false

ZPP_PROJECT_FLAGS := true
include zpp_project.mk
ZPP_PROJECT_FLAGS := false

ZPP_COMMA := ,
ZPP_EMPTY :=
ZPP_SPACE := $(ZPP_EMPTY) $(ZPP_EMPTY)

ifeq ($(ZPP_CONFIGURATION), debug)
ZPP_FLAGS := $(ZPP_FLAGS) $(ZPP_FLAGS_DEBUG)
ZPP_CFLAGS := $(ZPP_CFLAGS) $(ZPP_CFLAGS_DEBUG)
ZPP_CXXFLAGS := $(ZPP_CXXFLAGS) $(ZPP_CXXFLAGS_DEBUG)
ZPP_CXXMFLAGS := $(ZPP_CXXMFLAGS) $(ZPP_CXXMFLAGS_DEBUG)
ZPP_ASFLAGS := $(ZPP_ASFLAGS) $(ZPP_ASFLAGS_DEBUG)
ZPP_LFLAGS := $(ZPP_LFLAGS) $(ZPP_LFLAGS_DEBUG)
else ifeq ($(ZPP_CONFIGURATION), release)
ZPP_FLAGS := $(ZPP_FLAGS) $(ZPP_FLAGS_RELEASE)
ZPP_CFLAGS := $(ZPP_CFLAGS) $(ZPP_CFLAGS_RELEASE)
ZPP_CXXFLAGS := $(ZPP_CXXFLAGS) $(ZPP_CXXFLAGS_RELEASE)
ZPP_CXXMFLAGS := $(ZPP_CXXMFLAGS) $(ZPP_CXXMFLAGS_RELEASE)
ZPP_ASFLAGS := $(ZPP_ASFLAGS) $(ZPP_ASFLAGS_RELEASE)
ZPP_LFLAGS := $(ZPP_LFLAGS) $(ZPP_LFLAGS_RELEASE)
endif

ifeq ($(ZPP_CPP_MODULES_TYPE), )
ZPP_COMPILED_MODULE_FILES :=
else ifeq ($(ZPP_CPP_MODULES_TYPE), clang)
ZPP_COMPILED_MODULE_EXTENSION := pcm
ZPP_COMPILED_MODULE_FILES := $(filter %.cppm, $(ZPP_SOURCE_FILES))
ZPP_COMPILED_MODULE_FILES := $(patsubst %.cppm, %.$(ZPP_COMPILED_MODULE_EXTENSION), $(ZPP_COMPILED_MODULE_FILES))
ZPP_COMPILED_MODULE_FILES := $(patsubst %, $(ZPP_INTERMEDIATE_DIRECTORY)/%, $(ZPP_COMPILED_MODULE_FILES))
ZPP_CLANG_PREBUILT_MODULE_PATHS_FLAGS := $(sort $(patsubst %, -fprebuilt-module-path=%, $(dir $(ZPP_COMPILED_MODULE_FILES))))
ZPP_CXXFLAGS += $(ZPP_CLANG_PREBUILT_MODULE_PATHS_FLAGS)

define ZPP_CREATE_MODULE_DEPENDENCIES_SCRIPT
import os
import sys
dependencies_file = sys.argv[1]
source_file = sys.argv[2]
source_file_type = os.path.splitext(source_file)[1]
compiled_module_files = '$(ZPP_COMPILED_MODULE_FILES)'.split()
intermediate_ext = '.S' if '$(ZPP_GENERATE_ASSEMBLY)' == 'true' else '.o'
target_file = os.path.join(os.path.dirname(dependencies_file), os.path.basename(dependencies_file).split('.')[0]) \
	+ ('.$(ZPP_COMPILED_MODULE_EXTENSION)' if source_file_type == '.cppm' else intermediate_ext)
dependency_directives = '\n'.join([line.strip() for line in sys.stdin.read().strip().replace('\r', '').split('\n') if not line.strip().startswith('#')])
dependency_directives = [s.strip().split() for s in dependency_directives.split(';') if '<' not in s and '"' not in s]
dependency_directives = [s for s in dependency_directives if len(s) > 1 and s[0] in ['import', 'export', 'module']]
needed_modules = [m[1] if m[0] in ['import', 'module'] else m[2] \
				 for m in dependency_directives if m[0] in ['import', 'module'] or (m[0] == 'export' and m[1] == 'import')]
module = [m[1] for m in dependency_directives if m[0] == 'module']
module_file = [f for f in compiled_module_files if module and os.path.splitext(os.path.basename(f))[0] == module[0]]
module_flag = ('-fmodule-file=' + module_file[0]) if module_file else ''
rule = target_file + ': ' + ' \\\n\t'.join([f for f in compiled_module_files if os.path.splitext(os.path.basename(f))[0] in needed_modules]) + '\n'
with open(dependencies_file, 'w') as f:
	f.write(''.join([rule,'\nZPP_MODULE_FLAG_', source_file.replace('/', '__sep__').replace('.', '__dot__'), ' := ', module_flag, '\n']))
endef
export ZPP_CREATE_MODULE_DEPENDENCIES_SCRIPT
ZPP_CREATE_MODULE_DEPENDENCIES := $(ZPP_PYTHON) -c "$$ZPP_CREATE_MODULE_DEPENDENCIES_SCRIPT"

else
$(error ZPP_CPP_MODULES_TYPE=$(ZPP_CPP_MODULES_TYPE) is unrecognized and not supported)
endif

ZPP_OBJECT_FILES := $(patsubst %.c, %.o, $(ZPP_SOURCE_FILES))
ZPP_OBJECT_FILES := $(ZPP_OBJECT_FILES) $(patsubst %.cpp, %.o, $(ZPP_SOURCE_FILES))
ZPP_OBJECT_FILES := $(ZPP_OBJECT_FILES) $(patsubst %.cc, %.o, $(ZPP_SOURCE_FILES))
ZPP_OBJECT_FILES := $(ZPP_OBJECT_FILES) $(patsubst %.cppm, %.o, $(ZPP_SOURCE_FILES))
ZPP_OBJECT_FILES := $(ZPP_OBJECT_FILES) $(patsubst %.S, %.o, $(ZPP_SOURCE_FILES))
ZPP_OBJECT_FILES := $(patsubst %, $(ZPP_INTERMEDIATE_DIRECTORY)/%, $(ZPP_OBJECT_FILES))
ZPP_OBJECT_FILES := $(filter %.o, $(ZPP_OBJECT_FILES))
ZPP_OBJECT_FILES_DIRECTORIES := $(dir $(ZPP_OBJECT_FILES))

ZPP_DEPENDENCY_FILES := $(patsubst %.o, %.d, $(ZPP_OBJECT_FILES))

ZPP_MODULE_DEPENDENCY_FILES := \
	$(patsubst %.cpp, $(ZPP_INTERMEDIATE_DIRECTORY)/%.cpp.md, $(filter %.cpp, $(ZPP_SOURCE_FILES))) \
	$(patsubst %.cc, $(ZPP_INTERMEDIATE_DIRECTORY)/%.cc.md, $(filter %.cc, $(ZPP_SOURCE_FILES)))
ifneq ($(ZPP_CPP_MODULES_TYPE), )
ZPP_MODULE_DEPENDENCY_FILES += $(patsubst %.cppm, $(ZPP_INTERMEDIATE_DIRECTORY)/%.cppm.md, $(filter %.cppm, $(ZPP_SOURCE_FILES)))
endif

ifeq ($(ZPP_LINK_TYPE), default)
	ZPP_LINK_COMMAND := $(ZPP_LINK) -o $(ZPP_OUTPUT_DIRECTORY)/$(ZPP_TARGET_NAME) $(ZPP_OBJECT_FILES) $(ZPP_LFLAGS)
else ifeq ($(ZPP_LINK_TYPE), ld)
	ZPP_LINK_COMMAND := $(ZPP_LINK) -o $(ZPP_OUTPUT_DIRECTORY)/$(ZPP_TARGET_NAME) $(ZPP_OBJECT_FILES) $(ZPP_LFLAGS)
else ifeq ($(ZPP_LINK_TYPE), link)
	ZPP_LINK_COMMAND := $(ZPP_LINK) $(ZPP_LFLAGS) /out:$(ZPP_OUTPUT_DIRECTORY)/$(ZPP_TARGET_NAME) $(ZPP_OBJECT_FILES)
else ifeq ($(ZPP_LINK_TYPE), ar)
	ZPP_LINK_COMMAND := $(ZPP_AR) rcs $(ZPP_OUTPUT_DIRECTORY)/$(ZPP_TARGET_NAME) $(ZPP_OBJECT_FILES)
else
$(error ZPP_LINK_TYPE must either be default, ld, link, or ar)
endif

define ZPP_GENERATE_COMPILE_COMMANDS_SCRIPT
import os
import json
compile_commands = []
for root, _, files in os.walk('$(ZPP_COMPILE_COMMANDS_PATHS)'):
	for file in files:
		if not file.endswith('.zppcmd'):
			continue
		full_file = os.path.join(root, file)
		with open(full_file, 'r') as f:
			command, source_file = f.read().split('\n')[:2]
		compile_commands.append(
			{
				'directory': os.path.abspath('.'),
				'file': os.path.abspath(source_file),
				'command': command,
			}
		)
	with open('$(ZPP_COMPILE_COMMANDS_JSON)', 'w') as f:
		json.dump(compile_commands, f, indent=2, sort_keys=True)
endef
export ZPP_GENERATE_COMPILE_COMMANDS_SCRIPT
ZPP_CALL_GENERATE_COMPILE_COMMANDS_SCRIPT := $(ZPP_PYTHON) -c "$$ZPP_GENERATE_COMPILE_COMMANDS_SCRIPT"

build_single: $(ZPP_COMPILE_COMMANDS_JSON) $(ZPP_OUTPUT_DIRECTORY)/$(ZPP_TARGET_NAME)
	@echo "Built '$(ZPP_TARGET_TYPE)/$(ZPP_TARGET_NAME)'."

ifneq ($(ZPP_COMPILE_COMMANDS_JSON), )
$(ZPP_COMPILE_COMMANDS_JSON): $(patsubst %, %.zppcmd, $(ZPP_OBJECT_FILES)) $(patsubst %, %.zppcmd, $(ZPP_COMPILED_MODULE_FILES))
	@echo "Building '$@'..."; \
	$(ZPP_CALL_GENERATE_COMPILE_COMMANDS_SCRIPT)
endif

build_init:
	@echo "Building '$(ZPP_TARGET_TYPE)/$(ZPP_TARGET_NAME)' in '$(ZPP_CONFIGURATION)' mode..."; \
	mkdir -p $(ZPP_INTERMEDIATE_DIRECTORY); \
	mkdir -p $(ZPP_OUTPUT_DIRECTORY); \
	mkdir -p $(ZPP_OBJECT_FILES_DIRECTORIES)

build_dep_init:
	@echo "Building dependencies for '$(ZPP_TARGET_TYPE)/$(ZPP_TARGET_NAME)'..."; \
	mkdir -p $(ZPP_INTERMEDIATE_DIRECTORY); \
	mkdir -p $(ZPP_OUTPUT_DIRECTORY); \
	mkdir -p $(ZPP_OBJECT_FILES_DIRECTORIES)

$(ZPP_OUTPUT_DIRECTORY)/$(ZPP_TARGET_NAME): $(ZPP_OBJECT_FILES)
	@echo "Linking '$(ZPP_OUTPUT_DIRECTORY)/$(ZPP_TARGET_NAME)'..."; \
	set -e; \
	$(ZPP_LINK_COMMAND); \
	$(ZPP_POSTLINK_COMMANDS)

ifeq ($(ZPP_GENERATE_ASSEMBLY), true)
$(ZPP_INTERMEDIATE_DIRECTORY)/%.S: %.c | build_init $(ZPP_COMPILE_COMMANDS_JSON)
	@echo "Compiling '$<'..."; \
	$(ZPP_CC) -S $(ZPP_CFLAGS) -o $@ $< -MD -MP -MF `dirname $@`/`basename $@ .S`.d

$(ZPP_INTERMEDIATE_DIRECTORY)/%.o.zppcmd: %.c | build_init $(ZPP_COMPILE_COMMANDS_JSON)
	@echo '$(ZPP_CC) -c $(ZPP_CFLAGS) -o '`dirname $@`/`basename $@ .zppcmd`' $< -MD -MP -MF '`dirname $@`/`basename $@ .o.zppcmd`.d > $@; \
	echo $< >> $@

$(ZPP_INTERMEDIATE_DIRECTORY)/%.S: %.cpp | build_init $(ZPP_COMPILE_COMMANDS_JSON)
	@echo "Compiling '$<'..."; \
	$(ZPP_CXX) -S $(ZPP_CXXFLAGS) -o $@ $< $(ZPP_MODULE_FLAG_$(subst .,__dot__,$(subst /,__sep__,$<))) -MD -MP -MF `dirname $@`/`basename $@ .S`.d

$(ZPP_INTERMEDIATE_DIRECTORY)/%.o.zppcmd: %.cpp | build_init
	@echo '$(ZPP_CXX) -c $(ZPP_CXXFLAGS) -o '`dirname $@`/`basename $@a .zppcmd`' $< $(ZPP_MODULE_FLAG_$(subst .,__dot__,$(subst /,__sep__,$<))) ' \
		'-MD -MP -MF '`dirname $@`/`basename $@ .o.zppcmd`.d > $@; \
	echo $< >> $@

$(ZPP_INTERMEDIATE_DIRECTORY)/%.S: %.cc | build_init $(ZPP_COMPILE_COMMANDS_JSON)
	@echo "Compiling '$<'..."; \
	$(ZPP_CXX) -S $(ZPP_CXXFLAGS) -o $@ $< $(ZPP_MODULE_FLAG_$(subst .,__dot__,$(subst /,__sep__,$<))) -MD -MP -MF `dirname $@`/`basename $@ .S`.d

$(ZPP_INTERMEDIATE_DIRECTORY)/%.o.zppcmd: %.cc | build_init
	@echo '$(ZPP_CXX) -c $(ZPP_CXXFLAGS) -o '`dirname $@`/`basename $@ .zppcmd`' $< $(ZPP_MODULE_FLAG_$(subst .,__dot__,$(subst /,__sep__,$<))) ' \
		'-MD -MP -MF '`dirname $@`/`basename $@ .o.zppcmd`.d > $@; \
	echo $< >> $@

ifneq ($(ZPP_CPP_MODULES_TYPE), )
$(ZPP_INTERMEDIATE_DIRECTORY)/%.S: $(ZPP_INTERMEDIATE_DIRECTORY)/%.$(ZPP_COMPILED_MODULE_EXTENSION) | build_init $(ZPP_COMPILE_COMMANDS_JSON)
	@echo "Compiling '$<'..."; \
	$(ZPP_CXX) -S $(ZPP_CXXMFLAGS) -o $@ $<

$(ZPP_INTERMEDIATE_DIRECTORY)/%.o.zppcmd: %.cppm | build_init
	@echo '$(ZPP_CXX) -c $(ZPP_CXXFLAGS) -o '`dirname $@`/`basename $@ .zppcmd` `dirname $@`/`basename $@ .o.zppcmd`.$(ZPP_COMPILED_MODULE_EXTENSION) > $@; \
	echo `dirname $@`/`basename $@ .o.zppcmd`.$(ZPP_COMPILED_MODULE_EXTENSION) >> $@
endif

ifeq ($(ZPP_CPP_MODULES_TYPE), clang)
$(ZPP_INTERMEDIATE_DIRECTORY)/%.$(ZPP_COMPILED_MODULE_EXTENSION): %.cppm | build_init $(ZPP_COMPILE_COMMANDS_JSON)
	@echo "Compiling '$<'..."; \
	$(ZPP_CXX) --precompile $(ZPP_CXXFLAGS) -o $@ $< -MD -MP -MF `dirname $@`/`basename $@ .o`.d

$(ZPP_INTERMEDIATE_DIRECTORY)/%.$(ZPP_COMPILED_MODULE_EXTENSION).zppcmd: %.cppm | build_init
	@echo '$(ZPP_CXX) --precompile $(ZPP_CXXFLAGS) -o '`dirname $@`/`basename $@ .zppcmd` \
		' $< -MD -MP -MF '`dirname $@`/`basename $@ .$(ZPP_COMPILED_MODULE_EXTENSION).zppcmd`.d > $@; \
	echo $< >> $@
endif

$(ZPP_INTERMEDIATE_DIRECTORY)/%.o: $(ZPP_INTERMEDIATE_DIRECTORY)/%.S
	@$(ZPP_CC) -Wno-unicode -c -o $@ $<
else ifeq ($(ZPP_GENERATE_ASSEMBLY), false)
$(ZPP_INTERMEDIATE_DIRECTORY)/%.o: %.c | build_init $(ZPP_COMPILE_COMMANDS_JSON)
	@echo "Compiling '$<'..."; \
	$(ZPP_CC) -c $(ZPP_CFLAGS) -o $@ $< -MD -MP -MF `dirname $@`/`basename $@ .o`.d

$(ZPP_INTERMEDIATE_DIRECTORY)/%.o.zppcmd: %.c | build_init
	@echo '$(ZPP_CC) -c $(ZPP_CFLAGS) -o '`dirname $@`/`basename $@ .zppcmd`' $< -MD -MP -MF '`dirname $@`/`basename $@ .o.zppcmd`.d > $@; \
	echo $< >> $@

$(ZPP_INTERMEDIATE_DIRECTORY)/%.o: %.cpp | build_init $(ZPP_COMPILE_COMMANDS_JSON)
	@echo "Compiling '$<'..."; \
	$(ZPP_CXX) -c $(ZPP_CXXFLAGS) -o $@ $< $(ZPP_MODULE_FLAG_$(subst .,__dot__,$(subst /,__sep__,$<))) -MD -MP -MF `dirname $@`/`basename $@ .o`.d

$(ZPP_INTERMEDIATE_DIRECTORY)/%.o.zppcmd: %.cpp | build_init
	@echo '$(ZPP_CXX) -c $(ZPP_CXXFLAGS) -o '`dirname $@`/`basename $@ .zppcmd`' $< $(ZPP_MODULE_FLAG_$(subst .,__dot__,$(subst /,__sep__,$<))) ' \
		'-MD -MP -MF '`dirname $@`/`basename $@ .o.zppcmd`.d > $@; \
	echo $< >> $@

$(ZPP_INTERMEDIATE_DIRECTORY)/%.o: %.cc | build_init $(ZPP_COMPILE_COMMANDS_JSON)
	@echo "Compiling '$<'..."; \
	$(ZPP_CXX) -c $(ZPP_CXXFLAGS) -o $@ $< $(ZPP_MODULE_FLAG_$(subst .,__dot__,$(subst /,__sep__,$<))) -MD -MP -MF `dirname $@`/`basename $@ .o`.d

$(ZPP_INTERMEDIATE_DIRECTORY)/%.o.zppcmd: %.cc | build_init
	@echo '$(ZPP_CXX) -c $(ZPP_CXXFLAGS) -o '`dirname $@`/`basename $@ .zppcmd`' $< $(ZPP_MODULE_FLAG_$(subst .,__dot__,$(subst /,__sep__,$<))) ' \
		'-MD -MP -MF '`dirname $@`/`basename $@ .o.zppcmd`.d > $@; \
	echo $< >> $@

ifneq ($(ZPP_CPP_MODULES_TYPE), )
$(ZPP_INTERMEDIATE_DIRECTORY)/%.o: $(ZPP_INTERMEDIATE_DIRECTORY)/%.$(ZPP_COMPILED_MODULE_EXTENSION) | build_init $(ZPP_COMPILE_COMMANDS_JSON)
	@echo "Compiling '$<'..."; \
	$(ZPP_CXX) -c $(ZPP_CXXMFLAGS) -o $@ $<

$(ZPP_INTERMEDIATE_DIRECTORY)/%.o.zppcmd: %.cppm | build_init
	@echo '$(ZPP_CXX) -c $(ZPP_CXXFLAGS) -o '`dirname $@`/`basename $@ .zppcmd` `dirname $@`/`basename $@ .o.zppcmd`.$(ZPP_COMPILED_MODULE_EXTENSION) > $@; \
	echo `dirname $@`/`basename $@ .o.zppcmd`.$(ZPP_COMPILED_MODULE_EXTENSION) >> $@
endif

ifeq ($(ZPP_CPP_MODULES_TYPE), clang)
$(ZPP_INTERMEDIATE_DIRECTORY)/%.$(ZPP_COMPILED_MODULE_EXTENSION): %.cppm $(ZPP_INTERMEDIATE_DIRECTORY)/%.cppm.md | build_init $(ZPP_COMPILE_COMMANDS_JSON)
	@echo "Compiling '$<'..."; \
	$(ZPP_CXX) --precompile $(ZPP_CXXFLAGS) -o $@ $< -MD -MP -MF `dirname $@`/`basename $@ .o`.d

$(ZPP_INTERMEDIATE_DIRECTORY)/%.$(ZPP_COMPILED_MODULE_EXTENSION).zppcmd: %.cppm | build_init
	@echo '$(ZPP_CXX) --precompile $(ZPP_CXXFLAGS) -o '`dirname $@`/`basename $@ .zppcmd` \
		' $< -MD -MP -MF '`dirname $@`/`basename $@ .$(ZPP_COMPILED_MODULE_EXTENSION).zppcmd`.d > $@; \
	echo $< >> $@
endif
else
$(error ZPP_GENERATE_ASSEMBLY must either be true or false)
endif

$(ZPP_INTERMEDIATE_DIRECTORY)/%.o: %.S | build_init $(ZPP_COMPILE_COMMANDS_JSON)
	@echo "Assemblying '$<'..."; \
	$(ZPP_AS) -c $(ZPP_ASFLAGS) -o $@ $< -MD -MP -MF `dirname $@`/`basename $@ .o`.d

$(ZPP_INTERMEDIATE_DIRECTORY)/%.o.zppcmd: %.S | build_init
	@echo '$(ZPP_AS) -c $(ZPP_ASFLAGS) -o '`dirname $@`/`basename $@ .zppcmd`' $< -MD -MP -MF '`dirname $@`/`basename $@ .o.zppcmd`.d > $@; \
	echo $< >> $@

ifeq ($(ZPP_CPP_MODULES_TYPE), clang)
$(ZPP_INTERMEDIATE_DIRECTORY)/%.cpp.md: %.cpp | build_dep_init
	@$(ZPP_CXX) $(ZPP_CXXFLAGS) -Wno-unused-command-line-argument -E -Xclang -print-dependency-directives-minimized-source $< 2> /dev/null \
		| $(ZPP_CREATE_MODULE_DEPENDENCIES) $@ $<

$(ZPP_INTERMEDIATE_DIRECTORY)/%.cc.md: %.cc | build_dep_init
	@$(ZPP_CXX) $(ZPP_CXXFLAGS) -Wno-unused-command-line-argument -E -Xclang -print-dependency-directives-minimized-source $< 2> /dev/null \
		| $(ZPP_CREATE_MODULE_DEPENDENCIES) $@ $<

$(ZPP_INTERMEDIATE_DIRECTORY)/%.cppm.md: %.cppm | build_dep_init
	@$(ZPP_CXX) $(ZPP_CXXFLAGS) -Wno-unused-command-line-argument -E -Xclang -print-dependency-directives-minimized-source $< 2> /dev/null \
		| $(ZPP_CREATE_MODULE_DEPENDENCIES) $@ $<
endif

clean_single:
	@echo "Cleaning '$(ZPP_TARGET_TYPE)/$(ZPP_TARGET_NAME)'..."; \
	rm -rf $(ZPP_INTERMEDIATE_DIRECTORY_ROOT)/debug/$(ZPP_TARGET_TYPE); \
	rm -rf $(ZPP_INTERMEDIATE_DIRECTORY_ROOT)/release/$(ZPP_TARGET_TYPE); \
	rm -f $(ZPP_OUTPUT_DIRECTORY_ROOT)/debug/$(ZPP_TARGET_TYPE)/$(ZPP_TARGET_NAME); \
	rm -f $(ZPP_OUTPUT_DIRECTORY_ROOT)/release/$(ZPP_TARGET_TYPE)/$(ZPP_TARGET_NAME); \
	rm -f $(ZPP_COMPILE_COMMANDS_JSON); \
	find $(ZPP_INTERMEDIATE_DIRECTORY_ROOT) -type d -empty -delete 2> /dev/null; \
	find $(ZPP_OUTPUT_DIRECTORY_ROOT) -type d -empty -delete 2> /dev/null; \
	echo "Cleaned '$(ZPP_TARGET_TYPE)/$(ZPP_TARGET_NAME)'."

clean_mode:
	@rm -rf $(ZPP_INTERMEDIATE_DIRECTORY); \
	rm -rf $(ZPP_OUTPUT_DIRECTORY)/$(ZPP_TARGET_NAME)

rebuild_single: clean_mode
	@$(MAKE) -s -f $(ZPP_THIS_MAKEFILE) build ZPP_SKIP_DEPENDENCIES=

ifeq ($(ZPP_SKIP_DEPENDENCIES), )
-include $(ZPP_DEPENDENCY_FILES)
-include $(ZPP_MODULE_DEPENDENCY_FILES)
endif

ZPP_PROJECT_RULES := true
include zpp_project.mk
ZPP_PROJECT_RULES := false

endif # ifeq ($(ZPP_TARGET_TYPE), )
endif # ifneq ($(ZPP_INCLUDE_PROJECTS), )
