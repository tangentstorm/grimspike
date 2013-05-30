run: gen/hello
	./gen/hello

clean:
	rm -rf gen nimcache

gen:
	mkdir ./gen

gen/hello: gen hello.nim
	nimrod c hello.nim
	mv hello gen
