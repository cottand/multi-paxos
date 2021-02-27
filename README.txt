To see possible running ocnfiguraitons, see configuration.ex file.
Change running configurations as variable in Makefile.
The prevent_livelock ones are the most relevant ones.

CLEAN UP
--------
make clean   - remove compiled code
make compile - compile 

make run     - same as make run SERVERS=5 CLIENTS=5 CONFIG=default DEBUG=0 MAX_TIME=15000

