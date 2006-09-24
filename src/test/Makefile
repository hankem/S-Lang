# -*-sh-*-
TEST_SCRIPTS_SLC = argv syntax eqs sscanf loops arith array strops bstring \
  pack stdio assoc selfload struct nspace path ifeval anytype arrmult \
  time utf8 except bugs list regexp method deref naninf \
  longlong signal dollar req docfun debug

TEST_SCRIPTS_NO_SLC = autoload nspace2 prep

TEST_SCRIPTS = $(TEST_SCRIPTS_SLC) $(TEST_SCRIPTS_NO_SLC)

TEST_PGM = sltest
#RUN_TEST_PGM = valgrind --tool=memcheck --leak-check=yes --logfile=log --num-callers=20 ./$(TEST_PGM)
RUN_TEST_PGM = ./$(TEST_PGM)
SLANGINC = ..
SLANGLIB = ../$(ARCH)objs
OTHERLIBS = -lm

run_tests: $(TEST_PGM)
	@echo ""
	@echo "Running tests:"
	@echo ""
	-@for X in $(TEST_SCRIPTS); \
	do \
	   $(RUN_TEST_PGM) $$X.sl; \
	   $(RUN_TEST_PGM) -utf8 $$X.sl; \
	done
	touch sltest.c

run_tests_slc: $(TEST_PGM)
	@echo ""
	@echo "Running tests:"
	@echo ""
	-@for X in $(TEST_SCRIPTS_SLC); \
	do \
	   $(RUN_TEST_PGM) $$X.slc; \
	   $(RUN_TEST_PGM) -utf8 $$X.slc; \
	done
	touch sltest.c

sltest: sltest.c $(SLANGLIB)/libslang.a
	$(CC) $(CFLAGS) $(LDFLAGS) sltest.c -o sltest -I$(SLANGINC) -L$(SLANGLIB) -lslang $(OTHERLIBS)
clean: 
	-/bin/rm -f *~ sltest *.o *.log tmp-* log.pid* *.slc
