//
//  AudioUnitRemoteIOViewController.m
//  audiodemo
//
//  Created by YANG HONGBO on 2012-11-6.
//  Copyright (c) 2012年 YANG HONGBO. All rights reserved.
//

#import "AudioUnitRemoteIOViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>



@interface AudioUnitRemoteIOViewController ()
{
    AUGraph _processingGraph;
}
@property (nonatomic, assign, readwrite) double sampleRate;
@property (nonatomic, assign, readwrite) double theta;
@property (nonatomic, assign, readwrite) double frequency;

- (OSStatus)handleAURenderCallbackActionFlags:(AudioUnitRenderActionFlags *)	ioActionFlags
                                    timeStamp:(const AudioTimeStamp *)			inTimeStamp
                                    busNumber:(UInt32)							inBusNumber
                                 numberFrames:(UInt32)							inNumberFrames
                                       ioData:(AudioBufferList *)				ioData;
@end

OSStatus MyAURenderCallback(void *							inRefCon,
                            AudioUnitRenderActionFlags *	ioActionFlags,
                            const AudioTimeStamp *			inTimeStamp,
                            UInt32							inBusNumber,
                            UInt32							inNumberFrames,
                            AudioBufferList *				ioData);

OSStatus MyAURenderCallback(void *							inRefCon,
                            AudioUnitRenderActionFlags *	ioActionFlags,
                            const AudioTimeStamp *			inTimeStamp,
                            UInt32							inBusNumber,
                            UInt32							inNumberFrames,
                            AudioBufferList *				ioData)
{
//    AudioUnitRemoteIOViewController * vc = (__bridge AudioUnitRemoteIOViewController *)inRefCon;
//    return [vc handleAURenderCallbackActionFlags:ioActionFlags
//                                       timeStamp:inTimeStamp
//                                       busNumber:inBusNumber
//                                    numberFrames:inNumberFrames
//                                          ioData:ioData];
    
    // code from : http://www.cocoawithlove.com/2010/10/ios-tone-generator-introduction-to.html
    const double amplitude = 0.25;
    
	// Get the tone parameters out of the view controller
	AudioUnitRemoteIOViewController *viewController =
    (__bridge AudioUnitRemoteIOViewController *)inRefCon;
	double theta = viewController.theta;
	double theta_increment = 2.0 * M_PI * viewController.frequency / viewController.sampleRate;
    
	// This is a mono tone generator so we only need the first buffer
	const int channel = 0;
	Float32 *buffer = (Float32 *)ioData->mBuffers[channel].mData;
	
	// Generate the samples
	for (UInt32 frame = 0; frame < inNumberFrames; frame++)
	{
		buffer[frame] = sin(theta) * amplitude;
		
		theta += theta_increment;
		if (theta > 2.0 * M_PI)
		{
			theta -= 2.0 * M_PI;
		}
	}
	
	// Store the theta back in the view controller
	viewController.theta = theta;
    
	return noErr;
}

@implementation AudioUnitRemoteIOViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.frequency = 4400.0f;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self setupAudioSession];
    [self buildAudioGraph];
    [self startAudioGraph];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [self stopAudioGraph];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupAudioUnit
{
    AudioComponentDescription ioUnitDesc;
    ioUnitDesc.componentType = kAudioUnitType_Output;
    ioUnitDesc.componentSubType = kAudioUnitSubType_RemoteIO;
    ioUnitDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
    ioUnitDesc.componentFlags = 0;
    ioUnitDesc.componentFlagsMask = 0;
    
    AudioComponent foundIoUnitRef = AudioComponentFindNext(NULL, &ioUnitDesc);
    AudioUnit ioUnitInst;
    AudioComponentInstanceNew(foundIoUnitRef, &ioUnitInst);
}

- (void)buildAudioGraph
{
    AudioComponentDescription ioUnitDesc;
    ioUnitDesc.componentType = kAudioUnitType_Output;
    ioUnitDesc.componentSubType = kAudioUnitSubType_RemoteIO;
    ioUnitDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
    ioUnitDesc.componentFlags = 0;
    ioUnitDesc.componentFlagsMask = 0;
    
    
    NewAUGraph(&_processingGraph);
    
    AUNode ioNode;
    AUGraphAddNode(_processingGraph, &ioUnitDesc, &ioNode);
    AUGraphOpen(_processingGraph);
    
    AudioUnit ioUnit;
    AUGraphNodeInfo(_processingGraph, ioNode, NULL, &ioUnit);
    
    const int four_bytes_per_float = 4;
	const int eight_bits_per_byte = 8;
	AudioStreamBasicDescription streamFormat = {0};
	streamFormat.mSampleRate = self.sampleRate;
	streamFormat.mFormatID = kAudioFormatLinearPCM;
	streamFormat.mFormatFlags =
    kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
	streamFormat.mBytesPerPacket = four_bytes_per_float;
	streamFormat.mFramesPerPacket = 1;
	streamFormat.mBytesPerFrame = four_bytes_per_float;
	streamFormat.mChannelsPerFrame = 1;
	streamFormat.mBitsPerChannel = four_bytes_per_float * eight_bits_per_byte;
	OSStatus err = AudioUnitSetProperty (ioUnit,
                                kAudioUnitProperty_StreamFormat,
                                kAudioUnitScope_Input,
                                0,
                                &streamFormat,
                                sizeof(AudioStreamBasicDescription));
    
//    UInt32 enableInput = 1;
//    AudioUnitElement inputBus = 1;
//    AudioUnitSetProperty(ioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, inputBus, &enableInput, sizeof(enableInput));
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = &MyAURenderCallback;
    callbackStruct.inputProcRefCon = (__bridge void *)self;
    AUGraphSetNodeInputCallback(_processingGraph, ioNode, 0, &callbackStruct);
    Boolean updated;
    AUGraphUpdate(_processingGraph, &updated);
    
}

- (void)startAudioGraph
{
    OSStatus result = AUGraphInitialize(_processingGraph);
    if (!result) {
        AUGraphStart(_processingGraph);
    }
}

- (void)stopAudioGraph
{
    AUGraphStop(_processingGraph);
}

- (OSStatus)handleAURenderCallbackActionFlags:(AudioUnitRenderActionFlags *)ioActionFlags timeStamp:(const AudioTimeStamp *)inTimeStamp busNumber:(UInt32)inBusNumber numberFrames:(UInt32)inNumberFrames ioData:(AudioBufferList *)ioData
{
    for (int i = 0; i < inNumberFrames; i ++) {
        AudioBufferList * list = ioData + i;
        for (int j = 0; j < list->mNumberBuffers; j ++) {
            AudioBuffer * buffer = list->mBuffers + j;
            
        }
    }
    return 0;
}

- (void)setupAudioSession
{
    NSError * error = nil;
    AVAudioSession * session = [AVAudioSession sharedInstance];
    [session setPreferredSampleRate:44100.0 error:&error];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    [session setActive:YES error:&error];
    self.sampleRate = [session sampleRate];
}

@end
