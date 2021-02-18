# Nicolas D'Cotta (nd3018) and William Profit (wtp18)


# distributed algorithms, n.dulay, 29 jan 21
# coursework, paxos made moderately complex

# make options for Multipaxos

To see possible running ocnfiguraitons, see configuration.ex file.
Change running configurations as variable in Makefile.
The prevent_livelock ones are the most relevant ones.

CLEAN UP
--------
make clean   - remove compiled code
make compile - compile 

make run     - same as make run SERVERS=5 CLIENTS=5 CONFIG=default DEBUG=0 MAX_TIME=15000

