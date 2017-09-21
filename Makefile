run:
	perl main.pl

nytprof:
	perl -d:NYTProf main.pl && nytprofhtml

clean:
	rm -r *@* 2>/dev/null || echo > /dev/null
	rm -r nytprof* 2>/dev/null || echo > /dev/null
	