//
//  Recorder.h
//  chaocovietnam
//
//  Created by Son Dao Hoang on 12/3/11.
//  Copyright (c) 2011 UET. All rights reserved.
//

#ifndef chaocovietnam_Recorder_h
#define chaocovietnam_Recorder_h

#import <AudioToolbox/AudioToolbox.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "CAStreamBasicDescription.h"
#import "CAXException.h"
#import "pkmFFT.h"

#define kNumberBuffers 5

class Recorder
{
public:
    Recorder(void);
    ~Recorder();
    
    void startRecording(void);
    void stopRecording(void);
    bool isRunning(void);
    float getRecognizedBaseTime(void);
private:
    bool m_isRunning;
    AudioQueueRef m_queue;
    CAStreamBasicDescription m_recordFormat;
    AudioQueueBufferRef m_buffers[kNumberBuffers];
    
    int m_bufferSize;
    pkmFFT *m_fft;
    float *m_buffer;
    float *m_magnitude;
    float *m_phase;
    
    float m_startTime;
    int m_requiredSampleCount;
    int *m_sampledFrequencies;
    int m_sampleCount;
    int m_matchedI;
    int m_matchedMax;
    
    void setupAudioFormat(void);
    int computeBufferSize(const AudioStreamBasicDescription *format, float seconds);
    static void inCallbackProc(
                               void                                 *inUserData,
                               AudioQueueRef                        inAQ,
                               AudioQueueBufferRef                  inBuffer,
                               const AudioTimeStamp                 *inStartTime,
                               UInt32                               inNumPackets,
                               const AudioStreamPacketDescription   *inPacketDesc
                               );
};

#endif
