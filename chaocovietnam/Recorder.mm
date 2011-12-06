//
//  Recorder.cpp
//  chaocovietnam
//
//  Created by Son Dao Hoang on 12/3/11.
//  Copyright (c) 2011 UET. All rights reserved.
//

#import <iostream>
#import "Recorder.h"

#define min(x,y) (x < y) ? x : y

#import "Frequencies004.h"

#define kSecondsToProcess 3.0f
#define kSecondsToSample frequenciesWindow

void Recorder::inCallbackProc(
                              void                                  *inUserData,
                              AudioQueueRef                         inAQ,
                              AudioQueueBufferRef                   inBuffer,
                              const AudioTimeStamp                  *inStartTime,
                              UInt32                                inNumPackets,
                              const AudioStreamPacketDescription    *inPacketDesc
                              )
{
    Recorder *recorder = (Recorder *)inUserData;

    try
    {
        if (recorder->m_sampleCount < recorder->m_requiredSampleCount)
        {
            bzero(recorder->m_buffer, recorder->m_bufferSize);
            int bytesToCopy = min(inBuffer->mAudioDataByteSize, recorder->m_bufferSize);
            memcpy(recorder->m_buffer, inBuffer->mAudioData, bytesToCopy);
            recorder->m_fft->forward(0, recorder->m_buffer, recorder->m_magnitude, recorder->m_phase);
            
            float maxMagnitude = 0;
            int savedI = 0;

            for (int i = 0, l = recorder->m_bufferSize / sizeof(float) / 2; i < l; i++) 
            {
                if (recorder->m_magnitude[i] > maxMagnitude) 
                {
                    maxMagnitude = recorder->m_magnitude[i];
                    savedI = i;
                }
            }
            int peakFrequency = savedI * (recorder->m_recordFormat.mSampleRate / (recorder->m_bufferSize / sizeof(float)));
            
            fprintf(stderr, "%5d ", peakFrequency);
            
            recorder->m_sampledFrequencies[recorder->m_sampleCount] = peakFrequency;
            recorder->m_sampleCount++;
            
            // re-enqueue the buffer
            XThrowIfError(AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL), "AudioQueueEnqueueBuffer");
        }
    }
    catch (CAXException e)
    {
        char buf[256];
        fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
    }
    
    if (recorder->m_sampleCount >= recorder->m_requiredSampleCount)
    {
        recorder->stopRecording();
    }
}

Recorder::Recorder(void)
{
    m_isRunning = false;
    m_fft = NULL;
}

Recorder::~Recorder()
{
    stopRecording();
}

void Recorder::startRecording(void)
{
    int i;
    
    try
    {
        setupAudioFormat();
        
        XThrowIfError(AudioQueueNewInput(&m_recordFormat, inCallbackProc, this /* userData */, NULL /* run loop */, NULL /* run loop mode */, 0 /* flags */, &m_queue), "AudioQueueNewInput");
        
        m_bufferSize = computeBufferSize(&m_recordFormat, kSecondsToSample);
        for (i = 0; i < kNumberBuffers; i++)
        {
            XThrowIfError(AudioQueueAllocateBuffer(m_queue, m_bufferSize, &m_buffers[i]), "AudioQueueAllocateBuffer");
            XThrowIfError(AudioQueueEnqueueBuffer(m_queue, m_buffers[i], 0, NULL), "AudioQueueEnqueueBuffer");
        }
        
        // m_bufferSize is calculated in bytes
        m_fft = new pkmFFT(m_bufferSize / sizeof(float));
        m_buffer = (float *)malloc(m_bufferSize);
        m_magnitude = (float *)malloc(m_bufferSize / 2);
        m_phase = (float *)malloc(m_bufferSize / 2);
        
        m_startTime = CACurrentMediaTime();
        m_requiredSampleCount = (int) (kSecondsToProcess / kSecondsToSample + .5f);
        m_sampledFrequencies = (int *)malloc(m_requiredSampleCount * sizeof(int));
        bzero(m_sampledFrequencies, m_requiredSampleCount * sizeof(int));
        m_sampleCount = 0;
        m_matchedI = -1;
        m_matchedMax = 0;
        
        XThrowIfError(AudioQueueStart(m_queue, NULL), "AudioQueueStart");

        m_isRunning = true;
    }
    catch (CAXException &e)
    {
        char buf[256];
        fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
	}
    catch (...)
    {
        fprintf(stderr, "An unknown error occurred\n");
	}	
}

void Recorder::stopRecording(void)
{
    if (m_isRunning)
    {
        XThrowIfError(AudioQueueStop(m_queue, true), "AudioQueueStop");
        AudioQueueDispose(m_queue, true);
        m_queue = nil;
        
        if (m_sampleCount == m_requiredSampleCount)
        {
            // we got enough samples 
            // processes them now...
            int i, j, l, matchedCount;
            int savedI = -1;
            int maxMatchedCount = 0;
            
            for (i = 0, l = frequenciesCount - m_sampleCount; i < l; i++)
            {
                matchedCount = 0;
                
                for (j = 0; j < m_sampleCount; j++)
                {
                    if (frequencies[i + j] == m_sampledFrequencies[j])
                    {
                        matchedCount++;
                    }
                }
                
                if (matchedCount > maxMatchedCount)
                {
                    savedI = i;
                    maxMatchedCount = matchedCount;
                }
            }
            
            fprintf(stderr, "i = %d, matched = %d\n", savedI, maxMatchedCount);
            
            m_matchedI = savedI;
            m_matchedMax = maxMatchedCount;
        }
        
        m_isRunning = false;
        
        delete m_fft;
        free(m_buffer);
        free(m_magnitude);
        free(m_phase);
        free(m_sampledFrequencies);
    }
}

bool Recorder::isRunning(void)
{
    return m_isRunning;
}

float Recorder::getRecognizedBaseTime(void)
{
    if (m_matchedI != -1 && m_matchedMax > 5)
    {
        // a matched is found
        float offset = ((float) m_matchedI) * frequenciesWindow - 2.8f;
        float workingDuration = CACurrentMediaTime() - m_startTime;
        return m_startTime - offset - workingDuration;
    }
    else
    {
        return 0.f;
    }
}

void Recorder::setupAudioFormat(void)
{
    memset(&m_recordFormat, 0, sizeof(m_recordFormat));
    
    /*
    UInt32 size = sizeof(m_recordFormat.mSampleRate);
    XThrowIfError(AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate, &size, &m_recordFormat.mSampleRate), "couldn't get hardware sample rate");
    */
    m_recordFormat.mSampleRate = 44100;
    m_recordFormat.mFormatID = kAudioFormatLinearPCM;
    m_recordFormat.mFormatFlags = kLinearPCMFormatFlagIsFloat;
    m_recordFormat.mBitsPerChannel = sizeof(Float32) * 8;
    m_recordFormat.mChannelsPerFrame = 1;
    m_recordFormat.mFramesPerPacket = 1;
    m_recordFormat.mBytesPerPacket = m_recordFormat.mBytesPerFrame = m_recordFormat.mBitsPerChannel / 8;
}

int Recorder::computeBufferSize(const AudioStreamBasicDescription *format, float seconds)
{
    int frames = (int) ceil(seconds * format->mSampleRate);
    return frames * format->mBytesPerFrame;
}