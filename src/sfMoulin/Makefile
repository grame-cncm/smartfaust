
all: converter.cpp
	g++ -o converter converter.cpp `pkg-config --cflags --libs sndfile` 
	
convert:
	for file in *.wav; do flac -f -8 "$$file" -o "$${file%.wav}.flac"; done
