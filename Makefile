# Make file for rtl2gds utility.

SHELL=/bin/bash
CP=/bin/cp
UNAME := $(shell uname)
ENC:=$(shell which encounter)
DC:=$(shell which dc_shell)
VSIM:=$(shell which vsim)

all: check

install: check
	@echo "Installing rtl2gds utility in $(RTL2GDSHOME)"
	@mkdir -p $(RTL2GDSHOME)/rtl2gds_install
	@$(CP) -rf ./*  $(RTL2GDSHOME)/rtl2gds_install/
	@ln -fs $(RTL2GDSHOME)/rtl2gds_install/rtl2gds.pl  $(RTL2GDSHOME)/rtl2gds
	@ln -fs $(RTL2GDSHOME)/rtl2gds_install/rtl2gds.1  $(RTL2GDSHOME)/rtl2gds.1
	@chmod 777 $(RTL2GDSHOME)/rtl2gds
	@echo "rtl2gds utility installed"
	@echo "Include $(RTL2GDSHOME) in the path settings"
	@echo "Include $(RTL2GDSHOME)/rtl2gds_install/man1 in the man-path (MANPATH) settings"
	@echo "INFO: If you are not root/sudo MAN installation may fail. Ignore errors if any"
	@echo "INFO: You may reinstall as root/sudo for proper MAN functioning"
	@echo ""
	@ln -fs $(RTL2GDSHOME)/rtl2gds_install/rtl2gds.1  /usr/share/man/man1/

clean: 
	echo "Nothing to cleanup"

uninstall: checkuninst
	@/bin/rm -rf $(RTL2GDSHOME)/rtl2gds_install
	@/bin/rm -rf /usr/local/lib/rtl2gds
	@/bin/rm -f $(RTL2GDSHOME)/rtl2gds
	@/bin/rm -f $(RTL2GDSHOME)/rtl2gds.1
	@/bin/rm -f /usr/share/man/man1/rtl2gds.1 

check:
	@echo ""
	@echo ""
ifneq ($(UNAME),Linux)
	@echo "Please install in Linux Platform"
endif

# RTL2GDSHOME path not found
ifeq ($(RTL2GDSHOME),)
	@echo ""
	@echo "ERROR:"
	@echo "RTL2GDSHOME not found"
	@echo "Please set enviroment variable RTL2GDSHOME first"
	@echo ""
	@echo ""
endif


# SoC Encounter installation error
ifeq ($(ENC),)
	@echo "Cadence SoC-Encounter not found"
	@echo "Please install SoC-Encounter after rtl2gds installation"
endif
# Design Compiler installation error
ifeq ($(DC),)
	@echo "Synopsys Design-Compiler not found"
	@echo "Please install Synopsys Design-Compiler after rtl2gds installation"
endif
# ModelSim installation error
ifeq ($(VSIM),)
	@echo "Mentor ModelSim not found"
	@echo "Please install Mentor ModelSim after rtl2gds installation"
endif


checkuninst:
# RTL2GDSHOME path not found
ifeq ($(RTL2GDSHOME),)
	@echo ""
	@echo "ERROR:"
	@echo "RTL2GDSHOME not found"
	@echo "Please set enviroment variable RTL2GDSHOME first"
	@echo ""
	@echo ""
endif


