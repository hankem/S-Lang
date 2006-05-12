# -*-sh-*-
TEST_SCRIPTS = argv syntax eqs sscanf loops arith array strops bstring \
  pack stdio assoc selfload struct nspace path ifeval anytype arrmult \
  nspace2 prep time utf8 except bugs list regexp method deref naninf \
  longlong signal dollar req autoload docfun debug

TEST_PGM = sltest
#RUN_TEST_PGM = valgrind --tool=memcheck --leak-check=yes --logfile=log --num-callers=20 ./$(TEST_PGM)
RUN_TEST_PGM = ./$(TEST_PGM)
SLANGINC = ..
SLANGLIB = ../$(ARCH)objs

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

sltest: sltest.c $(SLANGLIB)/libslang.a
	$(CC) $(CFLAGS) $(LDFLAGS) sltest.c -o sltest -I$(SLANGINC) -L$(SLANGLIB) -lslang $(TCAPLIB) -lm
clean: 
	-/bin/rm -f *~ sltest *.o *.log tmp-* log.pid*
