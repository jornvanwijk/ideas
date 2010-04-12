default: ideas ideasWX
all: binaries documentation

SRCDIR = src

VERSION = 0.5.14

include Makefile.incl

binaries: ideas ideasWX omconverter

ideas: $(BINDIR)/ideas.cgi
omconverter: $(BINDIR)/omconverter$(EXE)
ideasWX: $(BINDIR)/ideasWX$(EXE)
prof: $(BINDIR)/prof$(EXE)
assess: $(BINDIR)/assess$(EXE)

$(BINDIR)/ideas.cgi: $(HS-SOURCES) revision
	$(MKDIR) -p $(BINDIR) $(OUTDIR)
	$(GHC) $(GHCFLAGS) -o $@ src/Service/Main.hs
	$(STRIP) $@

$(BINDIR)/ideasWX$(EXE): $(BINDIR)/ounl.jpg $(BINDIR)/ideas.ico $(BINDIR)/ideas.jpg $(HS-SOURCES) tools/IdeasWX/IdeasWX.hs revision
ifeq ($(WX), yes)
	$(MKDIR) -p $(BINDIR) $(OUTDIR)
	$(GHC) $(GHCFLAGS) $(GHCGUIFLAGS) -itools/IdeasWX -o $@ tools/IdeasWX/IdeasWX.hs
	$(STRIP) $@
ifeq ($(WINDOWS), no)
	$(CD) $(BINDIR); $(MAC) ideasWX
endif
endif

$(BINDIR)/omconverter$(EXE): $(HS-SOURCES) tools/OMConverter.hs revision
ifeq ($(WX), yes)
	$(MKDIR) -p $(BINDIR) $(OUTDIR)
	$(GHC) $(GHCFLAGS) $(GHCGUIFLAGS) -itools/ExerciseAssistant -o $@ tools/OMConverter.hs
	$(STRIP) $@
ifeq ($(WINDOWS), no)
	$(CD) $(BINDIR); $(MAC) omconverter
endif
endif

# For profiling purposes
$(BINDIR)/prof$(EXE): $(HS-SOURCES) revision
	$(MKDIR) -p $(BINDIR) $(OUTDIR)
	$(GHC) -prof -auto-all -iscripts $(GHCFLAGS) -o $@ src/Documentation/Make.hs
	$(STRIP) $@

$(BINDIR)/ounl.jpg: tools/IdeasWX/ounl.jpg
	$(MKDIR) -p $(BINDIR)
	$(CP) $< $@

$(BINDIR)/ideas.ico: tools/IdeasWX/ideas.ico
	$(MKDIR) -p $(BINDIR)
	$(CP) $< $@

$(BINDIR)/ideas.jpg: tools/IdeasWX/ideas.jpg
	$(MKDIR) -p $(BINDIR)
	$(CP) $< $@

# Create the assessment binary
$(BINDIR)/assess$(EXE): ag
	$(MKDIR) -p $(BINDIR) $(OUTDIR)
	$(GHC) $(GHCFLAGS) $(HELIUMFLAGS) -o $@ $(SRCDIR)/Domain/Programming/Main.hs
	$(STRIP) $@

#---------------------------------------------------------------------------------------
# Other directories

documentation: docs $(BINDIR)/ideas.cgi
	make -C $(DOCDIR) || exit 1

unit-tests: $(TESTDIR)/test.log
test: $(TESTDIR)/test.log

$(TESTDIR)/test.log: $(HS-SOURCES) $(BINDIR)/ideas.cgi
	make -C $(TESTDIR) || exit 1

#---------------------------------------------------------------------------------------
# Helper targets

ghci: revision
	$(MKDIR) -p $(OUTDIR)
	$(GHCI) -i$(SRCDIR) -itools -itools/IdeasWX -odir $(OUTDIR) -hidir $(OUTDIR) $(GHCWARN)

HELIUMDIR = ../../../heliumsystem/helium/src
TOPDIR = ../../../heliumsystem/Top/src
LVMDIR = ../../../heliumsystem/lvm/src/

HELIUMFLAGS = -i$(HELIUMDIR)/utils \
		-i$(HELIUMDIR)/staticanalysis/staticchecks -i$(HELIUMDIR)/staticanalysis/inferencers \
		-i$(HELIUMDIR)/staticanalysis/messages -i$(HELIUMDIR)/main -i$(TOPDIR) \
		-i$(HELIUMDIR)/staticanalysis/miscellaneous -i$(HELIUMDIR)/syntax -i$(LVMDIR)/lib/common \
		-i$(LVMDIR)/lib/common/ghc -i$(HELIUMDIR)/modulesystem -i$(HELIUMDIR)/staticanalysis/directives \
		-i$(HELIUMDIR)/staticanalysis/heuristics -i$(HELIUMDIR)/parser -i$(HELIUMDIR)/codegeneration \
		-i$(LVMDIR)/lib/lvm -i$(LVMDIR)/lib/asm -i$(LVMDIR)/lib/core

helium: ag # revision
	$(MKDIR) -p $(OUTDIR)
	$(GHCI) -optc-m32 -opta-m32 -optl-m32 $(HELIUMFLAGS) -i$(SRCDIR) -itools/IdeasWX -odir $(OUTDIR) -hidir $(OUTDIR) $(GHCWARN)


run: ideasWX
ifeq ($(WINDOWS), yes)
	$(BINDIR)/ideasWX$(EXE)
else
	open $(BINDIR)/ideasWX.app/
endif

revision: $(SRCDIR)/Service/Revision.hs

$(SRCDIR)/Service/Revision.hs: $(filter-out $(SRCDIR)/Service/Revision.hs, $(HS-SOURCES))
	echo "module Service.Revision where" > $@
	echo 'version = "$(VERSION)"' >> $@
ifeq ($(SVN), yes)
	svn info | grep 'Revision' | sed 's/.*\: /revision = /' >> $@
	svn info | grep 'Last Changed Date' | sed 's/.*(\(.*\))/lastChanged = \"\1\"/' >> $@
else
	echo 'revision = 0' >> $@
	echo 'lastChanged = "unknown"' >> $@
endif

nolicense:
	find src -name \*.hs -print0 | xargs --null grep -L "LICENSE"

#-------------------------------------------------------------------------
# AG sources
AG-SOURCES = $(SRCDIR)/Domain/Programming/AlphaRenaming.hs \
             $(SRCDIR)/Domain/Programming/InlinePatternBindings.hs

ag : $(AG-SOURCES)

$(SRCDIR)/Domain/Programming/AlphaRenaming.hs : \
		$(SRCDIR)/Domain/Programming/AlphaRenaming.ag \
		$(HELIUMDIR)/staticanalysis/staticchecks/Scope.ag \
		$(HELIUMDIR)/syntax/UHA_Syntax.ag 

	# AG AlphaRenaming
	cd $(SRCDIR)/Domain/Programming;\
	$(AG) $(AG_OPTS) --self --module=Domain.Programming.AlphaRenaming \
	-P ../../../$(HELIUMDIR) AlphaRenaming.ag;\
	cd ../../..

$(SRCDIR)/Domain/Programming/InlinePatternBindings.hs : \
		$(SRCDIR)/Domain/Programming/InlinePatternBindings.ag \
		$(HELIUMDIR)/syntax/UHA_Syntax.ag 

	# AG InlinePatternBindings
	cd $(SRCDIR)/Domain/Programming;\
	$(AG) $(AG_OPTS) --self --module=Domain.Programming.InlinePatternBindings \
	-P ../../../$(HELIUMDIR) InlinePatternBindings.ag;\
	cd ../../..


#-------------------------------------------------------------------------
# Installing on the IDEAS server

ifeq ($(IDEASSERVER), yes)

INSTALL-CGI  = /var/www/cgi-bin
INSTALL-DOC  = /var/www/html/docs/latest

install: ideas
	# "sudo make install"
	$(CP) $(BINDIR)/ideas.cgi $(INSTALL-CGI)
	$(CP) -r $(DOCDIR)/* $(INSTALL-DOC)

endif
	
#---------------------------------------------------------------------------------------
# Cleaning up

clean:
	$(RM) -rf $(BINDIR)
	$(RM) -rf $(OUTDIR)
	make -C $(DOCDIR)  clean
	make -C $(TESTDIR) clean
	$(RM) -f $(AG-SOURCES)
