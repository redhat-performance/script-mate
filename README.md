Script mate
===========

Collection of functions I use uften when scripting in Bash and wanted to deduplicate it :-)


Usage
-----

Just clone the repo and source bits you care about:

    git clone --depth=1 https://github.com/redhat-performance/script-mate.git
    source script-mate/src/logging.sh   # or any other file


Documentation
-------------

For user documentation see [docs/](docs/) directory.

To regenarate the documentaion, I have used this:

    git clone https://github.com/tests-always-included/tomdoc.sh.git
    for f in $( find src/ -type f -name \*.sh ); do echo "Generating doc for $f"; tomdoc.sh/tomdoc.sh --markdown $f >docs/$( basename $f .sh ).md; done
