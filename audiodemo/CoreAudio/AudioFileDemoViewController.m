//
//  AudioFileDemoViewController.m
//  audiodemo
//
//  Created by YANG HONGBO on 2012-11-5.
//  Copyright (c) 2012年 YANG HONGBO. All rights reserved.
//

#import "AudioFileDemoViewController.h"
#import <AudioToolbox/AudioToolbox.h>

//static const int kNumberBuffers = 3;
#define NUMBER_BUFFERS 3

extern NSString * const kSPDidStartPlaying;
extern NSString * const kSPDidStopPlaying;

typedef enum SPTrackState {
    TRACK_IDLE = 0,
    TRACK_BUFFERING,
    TRACK_PLAYING,
    TRACK_PAUSED,
}SPTrackState;

typedef struct SPAudioQueueInfo {
    //Audio queue services basic structure infomation
    AudioStreamBasicDescription   format;
    AudioQueueRef                 queue;
//    AudioQueueBufferRef           buffers[NUMBER_BUFFERS];
    AudioQueueTimelineRef         timeline;
    UInt32                        buffersCount;
    AudioFileID                   fileID;
    AudioFileStreamID             fileStreamID;
    UInt32                        bufferByteSize;
    SInt64                        currentPacket;
    UInt32                        numPacketsToRead;
    AudioStreamPacketDescription  * packetDescs;
    bool                          isRunning;
}SPAudioQueueInfo;



#define LOGOSSSTATUS(e) { \
NSString * string = [NSString stringWithFormat:@"%s(%d)", __FILE__, __LINE__]; \
LogOSStatus(e, string); \
}

#define RIF(err) { \
OSStatus e = (err); \
if((e)) { \
LOGOSSSTATUS(e); \
return e; \
}\
}
#define JIF(err) { \
OSStatus e = (err); \
if((e)) { \
LOGOSSSTATUS(e); \
} \
}
NSString * const kSPDidStartPlaying = @"StreamingPlayer_DidStartPlaying_Notification";
NSString * const kSPDidStopPlaying = @"StreamingPlayer_DidStopPlaying_Notification";

void LogOSStatus(OSStatus err, NSString * additional) {
    if (err) {
        char * str = (char *)&err;
        NSError * error = [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil];
        NSLog(@"%@(%c%c%c%c, %ld)(%@)", [error localizedDescription], str[3], str[2], str[1], str[0], err, additional);
    }
}

void MyAudioQueueOutputCallbackForStreamingFile (
                                                 void                 *inUserData,
                                                 AudioQueueRef        inAQ,
                                                 AudioQueueBufferRef  inBuffer
                                                 );
void MyAudioQueuePropertyListenerProc (
                                       void                  *inUserData,
                                       AudioQueueRef         inAQ,
                                       AudioQueuePropertyID  inID
                                       );
void DeriveBufferSize (
                       AudioStreamBasicDescription *pASBDesc,
                       UInt32                      maxPacketSize,
                       Float64                     seconds,
                       UInt32                      *outBufferSize,
                       UInt32                      *outNumPacketsToRead
                       );
void MyAudioFileStream_PacketsProc (
                                    void                          *inClientData,
                                    UInt32                        inNumberBytes,
                                    UInt32                        inNumberPackets,
                                    const void                    *inInputData,
                                    AudioStreamPacketDescription  *inPacketDescriptions
                                    );
void MyAudioFileStream_PropertyListenerProc (
                                             void                        *inClientData,
                                             AudioFileStreamID           inAudioFileStream,
                                             AudioFileStreamPropertyID   inPropertyID,
                                             UInt32                      *ioFlags
                                             );
void interruptionListenerCallback (void *inUserData, UInt32 interruptionState);


@interface AudioFileDemoViewController ()
{
    SPAudioQueueInfo _aqInfo;
    SPTrackState state;
    NSMutableArray * streamingBuffers;
    
    NSURLConnection * _connection;
    NSDictionary *httpHeaders;
}
//
- (void)cleanupAQ;

- (void)streamFile:(NSURL *)url;
- (void)streamFileInternalThread:(NSURL *)url;

//Notification
- (void)postNotificationName:(NSString *)name;
- (void)postNotificationNameInternal:(NSString *)name;

//callback handlers
- (void)handleForStreamingFileAudioQueue:(AudioQueueRef)inAQ outputBuffer:(AudioQueueBufferRef)inBuffer;
- (void)handleAudioQueue:(AudioQueueRef)inAQ listenerPropertyID:(AudioQueuePropertyID)inID;
- (void)handleAudioSessionInterruption:(UInt32)interruptionState;
- (void)handleAudioFileStreamPacketsNubmerBytes:(UInt32)inNumberBytes
                                  numberPacktes:(UInt32)inNumberPackets
                                      inputData:(const void *)inInputData
                              packetDescription:(AudioStreamPacketDescription *)inPacketDescriptions;
-(void)handleAudioFileStream:(AudioFileStreamID)inAudioFileStream
                  propertyID:(AudioFileStreamPropertyID)inPropertyID
                       flags:(UInt32 *)ioFlags;

@end

@implementation AudioFileDemoViewController

- (id)init
{
    self = [self initWithNibName:@"AudioFileDemoViewController" bundle:nil];
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
#if !TARGET_IPHONE_SIMULATOR
        OSStatus err;
        err = AudioSessionInitialize(NULL, NULL, interruptionListenerCallback, (__bridge void*)self);
        UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;
        err = AudioSessionSetProperty (kAudioSessionProperty_AudioCategory,
                                       sizeof (sessionCategory),
                                       &sessionCategory);
        if (err) {
            LOGOSSSTATUS(err);
            self = nil;
            return self;
        }
#endif
        streamingBuffers = [[NSMutableArray alloc] initWithCapacity:10];
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.fileURLField.enabled = NO;
    self.fileURLField.text = @"sample.mp3";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)playOrStop:(id)sender {
    NSURL * url = [[NSBundle mainBundle] URLForResource:@"sample" withExtension:@"mp3"];
    self.fileURLField.text = @"sample.mp3";
//    NSURL * url = [NSURL URLWithString:@"http://music.baidu.com/data/music/file?link=http://zhangmenshiting.baidu.com/data2/music/11261395/157587332400.mp3?xcode=f373bc1efecf7907843424b4045d5199"];
    [self streamFile:url];
}


- (void)stop {
    [self cleanupAQ];
}

- (void)cleanupAQ {
    self.state = TRACK_IDLE;
    @synchronized(self) {
        if (_connection) {
            [_connection cancel];
            _connection = nil;
        }
        
        if (_aqInfo.queue) {
            JIF(AudioQueueDispose (_aqInfo.queue,true));
            _aqInfo.queue = NULL;
        }
        if (_aqInfo.fileID) {
            JIF(AudioFileClose (_aqInfo.fileID));
            _aqInfo.fileID = NULL;
        }
        if (_aqInfo.fileStreamID) {
            AudioFileStreamClose(_aqInfo.fileStreamID);
            _aqInfo.fileStreamID = NULL;
        }
        if (_aqInfo.packetDescs) {
            free (_aqInfo.packetDescs);
            _aqInfo.packetDescs = NULL;
        }
    }
    
}

- (void)setState:(SPTrackState)aState {
    @synchronized(self)
    {
        state = aState;
        switch (state) {
            case TRACK_IDLE:
                NSLog(@"state:TRACK_IDLE");
                break;
            case TRACK_BUFFERING:
                NSLog(@"state:TRACK_BUFFERING");
                break;
            case TRACK_PLAYING:
                NSLog(@"state:TRACK_PLAYING");
                break;
            case TRACK_PAUSED:
                NSLog(@"state:TRACK_PAUSED");
                break;
                
            default:
                break;
        }
    }
}
- (SPTrackState)state {
    @synchronized(self)
    {
        return state;
    }
}
- (BOOL)playForURL:(NSURL *)aUrl {
    [self streamFile:aUrl];
    
    return TRUE;
    
}

- (void)streamFile:(NSURL *)aUrl {
    
    self.state = TRACK_BUFFERING;
    
    [NSThread detachNewThreadSelector:@selector(streamFileInternalThread:) toTarget:self withObject:aUrl];
    //[self streamFileInternalThread:aUrl];
}

- (void)streamFileInternalThread:(NSURL *)aUrl {
    @autoreleasepool {
        if ([aUrl isFileURL]) {
#if 0
            OSStatus err = 0;
            //没有加锁，是因为这里对_aqInfo的操作都在一个线程里完成
            //可能与其他操作产生异常访问（比如在cleanupAQ中），这里并未做完整的处理
            JIF(AudioFileOpenURL((__bridge CFURLRef)aUrl, kAudioFileReadPermission, 0, &_aqInfo.fileID));
            UInt32 dataFormatSize = sizeof(_aqInfo.format);
            JIF(AudioFileGetProperty(_aqInfo.fileID, kAudioFilePropertyDataFormat, &dataFormatSize, &_aqInfo.format));
            UInt32 maxPacketSize;
            UInt32 propertySize = sizeof (maxPacketSize);
            JIF(AudioFileGetProperty (_aqInfo.fileID,kAudioFilePropertyPacketSizeUpperBound,&propertySize,&maxPacketSize));
            
            DeriveBufferSize (&_aqInfo.format, maxPacketSize, 0.5, &_aqInfo.bufferByteSize,&_aqInfo.numPacketsToRead);
            
            bool isFormatVBR = (_aqInfo.format.mBytesPerPacket == 0 ||
                                _aqInfo.format.mFramesPerPacket == 0);
            
            if (isFormatVBR) {
                _aqInfo.packetDescs = (AudioStreamPacketDescription*) malloc (
                                                                             _aqInfo.numPacketsToRead * sizeof (AudioStreamPacketDescription));
            } else {
                _aqInfo.packetDescs = NULL;
            }
            
            
            JIF(AudioQueueNewOutput(&_aqInfo.format, MyAudioQueueOutputCallbackForStreamingFile, (__bridge void *)self, NULL, NULL, 0, &_aqInfo.queue));
            JIF(AudioQueueAddPropertyListener(_aqInfo.queue, kAudioQueueProperty_IsRunning, MyAudioQueuePropertyListenerProc, (__bridge void *)self));

            UInt32 cookieSize = sizeof (UInt32);
            bool couldNotGetProperty = AudioFileGetPropertyInfo (
                                                                 _aqInfo.fileID,
                                                                 kAudioFilePropertyMagicCookieData,
                                                                 &cookieSize,
                                                                 NULL);
            
            if (!couldNotGetProperty && cookieSize) {
                char* magicCookie =
                (char *) malloc (cookieSize);
                
                AudioFileGetProperty (_aqInfo.fileID, kAudioFilePropertyMagicCookieData, &cookieSize, magicCookie);
                AudioQueueSetProperty (_aqInfo.queue, kAudioQueueProperty_MagicCookie, magicCookie, cookieSize);
                free (magicCookie);
            }

            
            void * buffer = NULL;
            if (NULL == buffer) {
                buffer = malloc(_aqInfo.bufferByteSize);
                memset(buffer, 0, _aqInfo.bufferByteSize);
            }
            _aqInfo.currentPacket = 0;
            do {
                NSInteger buffersCount = 0;
                @synchronized(self) {
                    buffersCount = _aqInfo.buffersCount;
                }
                if (buffersCount < 2) {
                    UInt32 inNumberBytes = _aqInfo.bufferByteSize;
                    UInt32 inNumberPackets = _aqInfo.numPacketsToRead;
                    err = AudioFileReadPackets(_aqInfo.fileID, FALSE, &inNumberBytes, _aqInfo.packetDescs, _aqInfo.currentPacket, &inNumberPackets, buffer);
                    if (!err) {
                        AudioQueueBufferRef aqBuffer = NULL;
                        if (inNumberPackets > 0) {
                            JIF(AudioQueueAllocateBufferWithPacketDescriptions(_aqInfo.queue, inNumberBytes, inNumberPackets, &aqBuffer));
                            aqBuffer->mPacketDescriptionCount = inNumberPackets;
                            memcpy(aqBuffer->mPacketDescriptions, _aqInfo.packetDescs, sizeof(AudioStreamPacketDescription) * inNumberPackets);
                        }
                        else {
                            JIF(AudioQueueAllocateBuffer(_aqInfo.queue, inNumberBytes, &aqBuffer));
                        }
                        
                        aqBuffer->mAudioDataByteSize = inNumberBytes;
                        memcpy(aqBuffer->mAudioData, buffer, inNumberBytes);
                        JIF(AudioQueueEnqueueBuffer(_aqInfo.queue, aqBuffer, inNumberPackets, _aqInfo.packetDescs));
                        _aqInfo.currentPacket += inNumberPackets;
                        @synchronized(self)
                        {
                            _aqInfo.buffersCount ++;
                            if (TRACK_BUFFERING == self.state) {
                                OSStatus err;
                                err = AudioQueueStart(_aqInfo.queue, NULL);
                                if (err) {
                                    LOGOSSSTATUS(err);
                                }
                                else{
                                    self.state = TRACK_PLAYING;
                                    [self postNotificationName:kSPDidStartPlaying];
                                }
                            }
                        }
                    }
                }
                else {
                    [NSThread sleepForTimeInterval:0.01];
                }
            } while (TRACK_IDLE != self.state);
            
            if (buffer) {
                free(buffer);
                buffer = NULL;
            }
#else //这部分来测试流播放的功能
            @synchronized(self) {
                AudioFileStreamOpen((__bridge void*) self, MyAudioFileStream_PropertyListenerProc, MyAudioFileStream_PacketsProc, 0, &_aqInfo.fileStreamID);
            }
            UInt32 totalbytes = 0;
            NSFileHandle * fileHandle = [NSFileHandle fileHandleForReadingFromURL:aUrl error:NULL];

            do {
                if (_aqInfo.buffersCount < 2) {
                    @autoreleasepool {
                        NSData * data = [fileHandle readDataOfLength:128*1024];
                        NSLog(@"streamFileInternalThread: readBytes(%d)", [data length]);
                        totalbytes += [data length];
                        if ([data length]) {
                            AudioFileStreamParseBytes(_aqInfo.fileStreamID, [data length], [data bytes], 0);
                            totalbytes += [data length];
                        }
                        else {
                            break;
                        }
                        NSLog(@"Totalbytes:%ld", totalbytes);
                    }
                }
                else {
                    [NSThread sleepForTimeInterval:0.01];
                }
            }
            while (TRACK_IDLE != self.state);
#endif
        }
        else {//network stream
            NSURLRequest * request = [[NSURLRequest alloc] initWithURL:aUrl];
            _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
            
            if ([NSThread currentThread] != [NSThread mainThread]) {
                BOOL isRunning = TRUE;
                do {
                    isRunning = [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
                    
                } while (isRunning);
            }
        }
    }

}

//NSURLConnection delegates
- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse {
#ifdef _DEBUG
	NSLog(@"Streaming: %@", [request URL]);
#endif
	return request;
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"didFailWithError:%@", [error localizedDescription]);
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
    httpHeaders = [response allHeaderFields];
    @synchronized(self) {
        AudioFileStreamOpen((__bridge void*) self, MyAudioFileStream_PropertyListenerProc, MyAudioFileStream_PacketsProc, 0, &_aqInfo.fileStreamID);
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    assert(_aqInfo.fileStreamID);
    NSLog(@"didReceiveData:%d", [data length]);
    AudioFileStreamParseBytes(_aqInfo.fileStreamID, [data length], [data bytes], 0);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [NSThread detachNewThreadSelector:@selector(waitForFinishingPlaying) toTarget:self withObject:nil];
}
- (void)waitForFinishingPlaying {
    @autoreleasepool {
        NSLog(@"waitForFinishingPlaying");
        
        OSStatus err;
        UInt32 isRunning = 0;
        do {
            UInt32 size = sizeof(isRunning);
            [NSThread sleepForTimeInterval:0.25];
            err = AudioQueueGetProperty(_aqInfo.queue, kAudioQueueProperty_IsRunning, &isRunning, &size);
        } while (0 == err || isRunning);
        
        [self stop];
        [self postNotificationName:kSPDidStopPlaying];
        if (err) {
            LOGOSSSTATUS(err);
        }
    }
}

- (NSTimeInterval)duration {
    OSStatus err = 0;
    if (_aqInfo.queue) {
        if (NULL == _aqInfo.timeline) {
            err = AudioQueueCreateTimeline(_aqInfo.queue, &_aqInfo.timeline);
            if (err) {LOGOSSSTATUS(err);return 0;}
        }
        AudioTimeStamp timestamp;
        Boolean timelineDiscontinuity;
        err = AudioQueueGetCurrentTime(_aqInfo.queue, _aqInfo.timeline, &timestamp, &timelineDiscontinuity);
        if (err) {LOGOSSSTATUS(err);return 0;}
        
        return (timestamp.mSampleTime / _aqInfo.format.mSampleRate);
    }
    return 0;
}
//Notifications
- (void)postNotificationName:(NSString *)name {
    [self performSelectorOnMainThread:@selector(postNotificationNameInternal:) withObject:name waitUntilDone:NO];
}
- (void)postNotificationNameInternal:(NSString *)name {
    [[NSNotificationCenter defaultCenter] postNotificationName:name object:self];
}

- (void)handleForStreamingFileAudioQueue:(AudioQueueRef)inAQ outputBuffer:(AudioQueueBufferRef)inBuffer {
    //AudioQueueFreeBuffer(_aqInfo.queue, inBuffer);
    @synchronized(self)
    {
        _aqInfo.buffersCount --;
        NSLog(@"buffer dequeued:%ld", _aqInfo.buffersCount);
        if (_aqInfo.buffersCount < 1 && TRACK_PLAYING == self.state) {
            AudioQueuePause(_aqInfo.queue);
            self.state = TRACK_BUFFERING;
        }
    }
}

- (void)handleAudioFileStreamPacketsNubmerBytes:(UInt32)inNumberBytes
                                  numberPacktes:(UInt32)inNumberPackets
                                      inputData:(const void *)inInputData
                              packetDescription:(AudioStreamPacketDescription *)inPacketDescriptions
{
    assert(_aqInfo.queue);
    AudioQueueBufferRef buffer = NULL;
    if (inNumberPackets > 0) {
        JIF(AudioQueueAllocateBufferWithPacketDescriptions(_aqInfo.queue, inNumberBytes, inNumberPackets, &buffer));
        buffer->mPacketDescriptionCount = inNumberPackets;
        memcpy(buffer->mPacketDescriptions, inPacketDescriptions, sizeof(AudioStreamPacketDescription) * inNumberPackets);
    }
    else {
        JIF(AudioQueueAllocateBuffer(_aqInfo.queue, inNumberBytes, &buffer));
    }
    
    buffer->mAudioDataByteSize = inNumberBytes;
    memcpy(buffer->mAudioData, inInputData, inNumberBytes);
    JIF(AudioQueueEnqueueBuffer(_aqInfo.queue, buffer, inNumberPackets, inPacketDescriptions));
    @synchronized(self)
    {
        _aqInfo.buffersCount ++;
        if (TRACK_BUFFERING == self.state) {
            OSStatus err;
            err = AudioQueueStart(_aqInfo.queue, NULL);
            if (err) {
                LOGOSSSTATUS(err);
            }
            else{
                self.state = TRACK_PLAYING;
                [self postNotificationName:kSPDidStartPlaying];
            }
        }
    }
}

-(void)handleAudioFileStream:(AudioFileStreamID)inAudioFileStream
                  propertyID:(AudioFileStreamPropertyID)inPropertyID
                       flags:(UInt32 *)ioFlags
{
    switch (inPropertyID) {
        case kAudioFileStreamProperty_ReadyToProducePackets:
        {
            NSLog(@"kAudioFileStreamProperty_ReadyToProducePackets");
            AudioStreamBasicDescription dataFormat;
            UInt32 len = sizeof(dataFormat);
			AudioFileStreamGetProperty(inAudioFileStream, kAudioFileStreamProperty_DataFormat, &len, &dataFormat);
			_aqInfo.format = dataFormat;
            
            OSStatus err;
            UInt32 maximumPacketSize = 0;
            len = sizeof(maximumPacketSize);
            err = AudioFileStreamGetProperty(inAudioFileStream, kAudioFileStreamProperty_MaximumPacketSize, &len, &maximumPacketSize);
            LOGOSSSTATUS(err);
            
            UInt32 packetSizeUpperBound = 0;
            len = sizeof(packetSizeUpperBound);
            err = AudioFileStreamGetProperty(inAudioFileStream, kAudioFileStreamProperty_PacketSizeUpperBound, &len, &packetSizeUpperBound);
            LOGOSSSTATUS(err);
            
            JIF(AudioQueueNewOutput(&_aqInfo.format, MyAudioQueueOutputCallbackForStreamingFile, (__bridge void *)self, NULL, NULL, 0, &_aqInfo.queue));
            JIF(AudioQueueAddPropertyListener(_aqInfo.queue, kAudioQueueProperty_IsRunning, MyAudioQueuePropertyListenerProc, (__bridge void *)self));
        }
            break;
        default:
            break;
    }
}

- (void)handleAudioQueue:(AudioQueueRef)inAQ listenerPropertyID:(AudioQueuePropertyID)inID {
    if (kAudioQueueProperty_IsRunning == inID) {
        OSStatus err;
        UInt32 isRunning = 0;
        UInt32 size = sizeof(isRunning);
        err = AudioQueueGetProperty(inAQ, kAudioQueueProperty_IsRunning, &isRunning, &size);
        if (err || 0 == isRunning) {
            _aqInfo.isRunning = FALSE;
            [self postNotificationName:kSPDidStopPlaying];
            if (err) {
                LOGOSSSTATUS(err);
            }
        }
    }
}


- (void)handleAudioSessionInterruption:(UInt32)interruptionState {
    if (interruptionState == kAudioSessionBeginInterruption) {
        
    }
    else if (interruptionState == kAudioSessionEndInterruption){
        
    }    
}
@end

void MyAudioQueuePropertyListenerProc (void *inUserData,AudioQueueRef inAQ, AudioQueuePropertyID  inID){
    AudioFileDemoViewController * player = (__bridge AudioFileDemoViewController *)inUserData;
    assert(player && [player isKindOfClass:[AudioFileDemoViewController class]]);
    [player handleAudioQueue:inAQ listenerPropertyID:inID];
}

void MyAudioQueueOutputCallbackForStreamingFile(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer) {
    
    AudioFileDemoViewController * player = (__bridge AudioFileDemoViewController *)inUserData;
    assert(player && [player isKindOfClass:[AudioFileDemoViewController class]]);
    [player handleForStreamingFileAudioQueue:inAQ outputBuffer:inBuffer];
}

void interruptionListenerCallback (void *inUserData, UInt32 interruptionState) {
    
    AudioFileDemoViewController * player = (__bridge AudioFileDemoViewController *)inUserData;
    assert(player && [player isKindOfClass:[AudioFileDemoViewController class]]);
    [player handleAudioSessionInterruption:interruptionState];
    
}
void MyAudioFileStream_PacketsProc (
                                    void                          *inClientData,
                                    UInt32                        inNumberBytes,
                                    UInt32                        inNumberPackets,
                                    const void                    *inInputData,
                                    AudioStreamPacketDescription  *inPacketDescriptions
                                    )
{
    AudioFileDemoViewController * player = (__bridge AudioFileDemoViewController *)inClientData;
    assert(player && [player isKindOfClass:[AudioFileDemoViewController class]]);
    [player handleAudioFileStreamPacketsNubmerBytes:inNumberBytes numberPacktes:inNumberPackets inputData:inInputData packetDescription:inPacketDescriptions];
}

void MyAudioFileStream_PropertyListenerProc (
                                             void                        *inClientData,
                                             AudioFileStreamID           inAudioFileStream,
                                             AudioFileStreamPropertyID   inPropertyID,
                                             UInt32                      *ioFlags
                                             )
{
    AudioFileDemoViewController * player = (__bridge AudioFileDemoViewController *)inClientData;
    assert(player && [player isKindOfClass:[AudioFileDemoViewController class]]);
    [player handleAudioFileStream:inAudioFileStream propertyID:inPropertyID flags:ioFlags];
}

void DeriveBufferSize (AudioStreamBasicDescription * pASBDesc, UInt32 maxPacketSize, Float64 seconds, UInt32 *outBufferSize, UInt32 *outNumPacketsToRead) {
    static const int maxBufferSize = 0x50000;
    static const int minBufferSize = 0x4000;
    assert(pASBDesc);
    assert(outBufferSize);
    assert(outNumPacketsToRead);
    
    if (pASBDesc->mFramesPerPacket != 0) {
        Float64 numPacketsForTime = pASBDesc->mSampleRate / pASBDesc->mFramesPerPacket * seconds;
        *outBufferSize = numPacketsForTime * maxPacketSize;
    } else {
        *outBufferSize = maxBufferSize > maxPacketSize ?
        maxBufferSize : maxPacketSize;
    }
    
    if (*outBufferSize > maxBufferSize &&
        *outBufferSize > maxPacketSize)
        *outBufferSize = maxBufferSize;
    else {                                                           // 11
        if (*outBufferSize < minBufferSize)
            *outBufferSize = minBufferSize;
    }
    
    *outNumPacketsToRead = *outBufferSize / maxPacketSize;           // 12
}
