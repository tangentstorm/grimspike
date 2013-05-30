default: run/bfsyn

clean:
	rm -rf gen nimcache

# catchall to compile %.nim
gen/%: ./%.nim
	mkdir -p ./gen
	nimrod c $<
	mv $* gen


# catchall to compile and run %.nim
run/%: gen/%
	./gen/$*

# to keep make from automagically deleting gen/x after run/x
# cf: http://stackoverflow.com/questions/8024353/makefile-auto-removing-o-files
.PRECIOUS: gen/%


# special cases
run/bfsyn: gen/bfsyn
	@clear
	@./gen/bfsyn < hello.bf
