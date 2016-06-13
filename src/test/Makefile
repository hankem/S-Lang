# -*- make -*-
TEST_SCRIPTS_SLC = argv syntax scircuit eqs sscanf loops arith array strops \
  bstring pack stdio assoc selfload struct nspace path ifeval anytype arrmult \
  time utf8 except bugs list regexp method deref naninf overflow sort \
  longlong signal dollar req docfun debug qualif compare break multline \
  stack misc posixio posdir proc math

TEST_SCRIPTS_NO_SLC = autoload nspace2 prep

TEST_SCRIPTS = $(TEST_SCRIPTS_SLC) $(TEST_SCRIPTS_NO_SLC)

TEST_PGM = sltest
MEMCHECK = valgrind --tool=memcheck --leak-check=yes --leak-resolution=med --num-callers=20
RUN_TEST_PGM = ./$(TEST_PGM)
SLANGINC = ..
SLANGLIB = ../$(ARCH)objs
OTHER_LIBS = -lm
OTHER_CFLAGS =

runtests: $(TEST_PGM) cleantmp
	@tests=""; \
	for test in $(TEST_SCRIPTS); \
	do \
	   tests="$$tests $$test.sl"; \
	done; \
	for test in $(TEST_SCRIPTS_SLC); \
	do \
	   tests="$$tests $$test.slc"; \
	done; \
	MAKERUNNING=1 ./runtests.sh $$tests
#	@touch $(TEST_PGM).c

update: $(TEST_PGM) cleantmp
	@tests=""; \
	for X in $(TEST_SCRIPTS); \
	do \
	  if [ ! -e lastrun/$$X.sl ] || [ $$X.sl -nt lastrun/$$X.sl ] ; \
	  then \
	   tests="$$tests $$X.sl"; \
	  fi \
	done; \
	for X in $(TEST_SCRIPTS_SLC); \
	do \
	  if [ ! -e lastrun/$$X.slc ] || [ $$X.sl -nt lastrun/$$X.slc ] ; \
	  then \
	   tests="$$tests $$X.slc"; \
	  fi \
	done; \
	if test -n "$$tests"; \
	then \
	  MAKERUNNING=1 ./runtests.sh $$tests; \
	fi
#	@touch $(TEST_PGM).c

memcheck_runtests: $(TEST_PGM) cleantmp
	@echo ""
	@echo "Running tests:"
	@echo ""
	-@for X in $(TEST_SCRIPTS); \
	do \
	   $(MEMCHECK) --log-file=log.$${X} $(RUN_TEST_PGM) $$X.sl; \
	   grep ERROR log.$${X}; grep 'lost: [^0]' log.$${X}; \
	   $(MEMCHECK) --log-file=log.$${X}_u $(RUN_TEST_PGM) -utf8 $$X.sl; \
	   grep ERROR log.$${X}_u; grep 'lost: [^0]' log.$${X}_u; \
	done
#	touch $(TEST_PGM).c

memcheck_runtests_slc: $(TEST_PGM) cleantmp
	@echo ""
	@echo "Running tests:"
	@echo ""
	-@for X in $(TEST_SCRIPTS_SLC); \
	do \
	   $(MEMCHECK) --log-file=log.$${X}_c $(RUN_TEST_PGM) $$X.slc; \
	   $(MEMCHECK) --log-file=log.$${X}_uc $(RUN_TEST_PGM) -utf8 $$X.slc; \
	done
#	touch $(TEST_PGM).c

memcheck: memcheck_runtests memcheck_runtests_slc

$(TEST_PGM): $(TEST_PGM).c assoc.c list.c $(SLANGLIB)/libslang.a
	$(CC) $(CFLAGS) $(OTHER_CFLAGS) $(LDFLAGS) $(TEST_PGM).c -o $(TEST_PGM) -I$(SLANGINC) -L$(SLANGLIB) -lslang $(OTHER_LIBS)
cleantmp:
	-/bin/rm -rf tmpfile*.* tmpdir*.*
clean: cleantmp
	-/bin/rm -f *~ *.o *.log log.pid* *.slc log.* *.log-*
distclean: clean
	/bin/rm -f $(TEST_PGM) $(TEST_PGM).gcda $(TEST_PGM).gcno
.PHONY: clean memcheck runtests memcheck_runtests_slc memcheck_runtests cleantmp

