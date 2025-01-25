#include <iostream>
#include <vector>
#include <sndfile.h>

// Include all the header files containing sound data
#include "sampleA.h"
#include "sampleB.h"
#include "sampleC.h"
#include "sampleD.h"
#include "sampleE.h"
#include "sampleF.h"
#include "sampleG.h"
#include "sampleH.h"
#include "sampleI.h"
#include "sampleJ.h"

#define SAMPLE_RATE 44100  // Assuming 44.1 kHz
#define CHANNELS 1         // Mono audio
#define FORMAT (SF_FORMAT_WAV | SF_FORMAT_PCM_24) // 24-bit integer WAV

// Function pointer types for reading different files
typedef int (*SizeFunction)();
typedef float (*ReadFunction)(int);

// Generic function to write WAV files from a given sound array
void writeWavFile(const std::string &filename, SizeFunction getSize, ReadFunction getSample) {
    int dataSize = getSize(); // Get the number of samples

    // Read the float data from the header file
    std::vector<float> floatBuffer(dataSize);
    for (int i = 0; i < dataSize; i++) {
        floatBuffer[i] = getSample(i);
    }

    // Set up libsndfile format
    SF_INFO sfinfo;
    sfinfo.samplerate = SAMPLE_RATE;
    sfinfo.channels = CHANNELS;
    sfinfo.format = FORMAT;
    sfinfo.frames = dataSize;

    // Open the output WAV file
    SNDFILE *outfile = sf_open(filename.c_str(), SFM_WRITE, &sfinfo);
    if (!outfile) {
        std::cerr << "Error: Could not open " << filename << " for writing.\n";
        return;
    }

    // Write the float PCM data to the file
    sf_write_float(outfile, floatBuffer.data(), dataSize);

    // Close the file
    sf_close(outfile);

    std::cout << "Conversion completed successfully! Saved as " << filename << "\n";
}

int main() {
    // Convert multiple sound files to WAV
    writeWavFile("sampleA.wav", soundFileSize_sampleA, readSoundFile_sampleA);
    writeWavFile("sampleB.wav", soundFileSize_sampleB, readSoundFile_sampleB);
    writeWavFile("sampleC.wav", soundFileSize_sampleC, readSoundFile_sampleC);
    writeWavFile("sampleD.wav", soundFileSize_sampleD, readSoundFile_sampleD);
    writeWavFile("sampleE.wav", soundFileSize_sampleE, readSoundFile_sampleE);
    writeWavFile("sampleF.wav", soundFileSize_sampleF, readSoundFile_sampleF);
    writeWavFile("sampleG.wav", soundFileSize_sampleG, readSoundFile_sampleG);
    writeWavFile("sampleH.wav", soundFileSize_sampleH, readSoundFile_sampleH);
    writeWavFile("sampleI.wav", soundFileSize_sampleI, readSoundFile_sampleI);
    writeWavFile("sampleJ.wav", soundFileSize_sampleJ, readSoundFile_sampleJ);

    return 0;
}

