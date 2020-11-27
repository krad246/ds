#-------------------------------------------------------------------------------
# Toolchain definitions - to be automake'd out for cross compilation
#-------------------------------------------------------------------------------
CC				:= gcc
CXX				:= g++	
AR				:= ar
NM				:= nm
OBJCOPY			:= objcopy
OBJDUMP			:= objdump
RANLIB			:= ranlib
STRIP			:= strip
SIZE			:= size
READELF			:= readelf

#-------------------------------------------------------------------------------
# Build structure defines
#-------------------------------------------------------------------------------
SRCDIR		  	:= src
BINDIR			:= bin
OBJDIR		  	:= obj
PREPROCDIR		:= preproc

#-------------------------------------------------------------------------------
# Build file extensions
#-------------------------------------------------------------------------------
C_EXTS   		:= .c .cpp .cc

#-------------------------------------------------------------------------------
# Compiler flags
#-------------------------------------------------------------------------------
OPT_FLAGS		= -Og -g
WARN_FLAGS		= -Wall -Wunused -Werror -Wextra -pedantic
STYLE_FLAGS		= -ffunction-sections -fdata-sections

CFLAGS			:= $(OPT_FLAGS) $(STYLE_FLAGS) -MMD -MP 

#-------------------------------------------------------------------------------
# The magic
#-------------------------------------------------------------------------------
DIRS 			:= $(shell find $(SRCDIR) -type d -print)

C_SRC 			:= $(foreach DIR, $(DIRS), \
						$(foreach EXT, $(C_EXTS), \
							$(wildcard $(DIR)/*$(EXT))))

SRCS			:= $(C_SRC)
PREPROCS		:= $(addsuffix .preproc, $(addprefix $(PREPROCDIR)/, $(SRCS)))

C_OBJ 			:= $(addsuffix .o, $(addprefix $(OBJDIR)/, $(C_SRC)))
OBJS			:= $(C_OBJ)

DEPS 			:= $(patsubst %.o, %.d, $(OBJS))

#-------------------------------------------------------------------------------
# Binary outputs
#-------------------------------------------------------------------------------
BINARY			:= $(BINDIR)/libds.a

#-------------------------------------------------------------------------------
# Targets
#-------------------------------------------------------------------------------
.PHONY: clean all

all: preproc library

preproc: $(PREPROCS)
	@find $(PREPROCDIR) -mindepth 2 -type f -exec mv {} $(PREPROCDIR) \;
	@find $(PREPROCDIR) -type d -empty -delete

library: $(BINARY)

#-------------------------------------------------------------------------------
# The implementation
#-------------------------------------------------------------------------------
$(BINARY): $(OBJS)
	@echo [LD] $@
	@$(AR) -rcs $@ $^
	@echo [SIZE] $@
	@$(SIZE) $(BINARY)

$(OBJDIR)%/:
	@mkdir -p $@

$(PREPROCDIR)/%.preproc: $(SRCS)
	@mkdir -p $(dir $@)
	@$(CC) -E $< > $@

$(OBJDIR)/%.c.o: %.c
	@echo [CC] $<
	@$(CC) $(CFLAGS) -DMODULE_NAME=\
	$(shell echo \
	$(shell basename $(dir $<)) | \
	tr '[:lower:]' '[:upper:]') \
	-c $< -o $@ 

$(OBJDIR)/%.cc.o: %.cc
	@echo [CXX] $<
	@$(CXX) $(CFLAGS) -DMODULE_NAME=\
	$(shell echo \
	$(shell basename $(dir $<)) | \
	tr '[:lower:]' '[:upper:]') \
	-c $< -o $@ 

$(OBJDIR)/%.cpp.o: %.cpp
	@echo [CXX] $<
	@$(CXX) $(CFLAGS) -DMODULE_NAME=\
	$(shell echo \
	$(shell basename $(dir $<)) | \
	tr '[:lower:]' '[:upper:]') \
	-c $< -o $@ 

$(foreach OBJ, $(OBJS), $(eval $(OBJ): | $(dir $(OBJ))))

clean:
	@rm -rf $(OBJDIR)/* $(BINDIR)/* $(PREPROCDIR)/*

ifneq ($(MAKECMDGOALS), clean)
-include $(DEPS)
endif
