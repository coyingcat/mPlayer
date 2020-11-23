//
//  main.swift
//  doPlay
//
//  Created by Jz D on 2020/11/23.
//

import Foundation

import AudioToolbox


// MARK: Struct definition

struct Player {
    var playbackFile: AudioFileID?                                          // reference to your output file
    var packetPosition: Int64 = 0                                           // current packet index in output file
    var numPacketsToRead: UInt32 = 0                                        // number of packets to read from file
    var packetDescs: UnsafeMutablePointer<AudioStreamPacketDescription>?    // array of packet descriptions for read buffer
    var isDone = false                                                      // playback has completed
}

//--------------------------------------------------------------------------------------------------
// MARK: Supporting methods

//
// we only use time here as a guideline
// we're really trying to get somewhere between kMinBufferSize and kMaxBufferSize buffers, but not allocate too much if we don't need it
//
func CalculateBytesForTime (inAudioFile: AudioFileID,
                            inDesc: AudioStreamBasicDescription,
                            inSeconds: Double,
                            outBufferSize: UnsafeMutablePointer<UInt32>,
                            outNumPackets: UnsafeMutablePointer<UInt32>) {
    
    let kMaxBufferSize: UInt32 = 0x10000                                        // limit size to 64K
    let kMinBufferSize: UInt32 = 0x4000                                         // limit size to 16K

    // we need to calculate how many packets we read at a time, and how big a buffer we need.
    // we base this on the size of the packets in the file and an approximate duration for each buffer.
    //
    // first check to see what the max size of a packet is, if it is bigger than our default
    // allocation size, that needs to become larger
    var maxPacketSize: UInt32 = 0
    var propSize: UInt32  = 4
    Utility.check(error: AudioFileGetProperty(inAudioFile,
                                              kAudioFilePropertyPacketSizeUpperBound,
                                              &propSize,
                                              &maxPacketSize),
                  operation: "couldn't get file's max packet size")
    
    
    if inDesc.mFramesPerPacket > 0 {
        
        let numPacketsForTime = UInt32(inDesc.mSampleRate / (Double(inDesc.mFramesPerPacket) * inSeconds))
        
        outBufferSize.pointee = numPacketsForTime * maxPacketSize
    
    } else {
        // if frames per packet is zero, then the codec has no predictable packet == time
        // so we can't tailor this (we don't know how many Packets represent a time period
        // we'll just return a default buffer size
        outBufferSize.pointee = (kMaxBufferSize > maxPacketSize ? kMaxBufferSize : maxPacketSize)
    }
    
    // we're going to limit our size to our default
    if outBufferSize.pointee > kMaxBufferSize && outBufferSize.pointee > maxPacketSize {
        
        outBufferSize.pointee = kMaxBufferSize
    
    }
    else {
        // also make sure we're not too small - we don't want to go the disk for too small chunks
        if outBufferSize.pointee < kMinBufferSize {
            outBufferSize.pointee = kMinBufferSize
        }
    }
    outNumPackets.pointee = outBufferSize.pointee / maxPacketSize
}
//
// Read bytes from a file into a buffer
//
// AudioQueueOutputCallback function
//
//      must have the following signature:
//          @convention(c) (UnsafeMutablePointer<Swift.Void>?,                      // Void pointer to Player struct
//                          AudioQueueRef,                                          // reference to the queue
//                          AudioQueueBufferRef) -> Swift.Void                      // reference to the buffer in the queue
//


func outputCallback(userData: UnsafeMutableRawPointer?, queue: OpaquePointer, bufferToFill: UnsafeMutablePointer<AudioQueueBuffer>) {

    guard let user = userData else {
        return
    }
    
    
    let player = user.assumingMemoryBound(to: Player.self)
        
        
    if player.pointee.isDone { return }
        
        // read audio data from file into supplied buffer
    var numBytes: UInt32 = bufferToFill.pointee.mAudioDataBytesCapacity
    var nPackets = player.pointee.numPacketsToRead
        
    Utility.check(error: AudioFileReadPacketData(player.pointee.playbackFile!,              // AudioFileID
                                                false,                                     // use cache?
                                                &numBytes,                                 // initially - buffer capacity, after - bytes actually read
                                                player.pointee.packetDescs,                // pointer to an array of PacketDescriptors
                                                player.pointee.packetPosition,             // index of first packet to be read
                                                &nPackets,                                 // number of packets
                                                bufferToFill.pointee.mAudioData),          // output buffer
                      operation: "AudioFileReadPacketData failed")

        // enqueue buffer into the Audio Queue
        // if nPackets == 0 it means we are EOF (all data has been read from file)
        if nPackets > 0 {
            bufferToFill.pointee.mAudioDataByteSize = numBytes
            
            Utility.check(error: AudioQueueEnqueueBuffer(queue,                                                 // queue
                                                         bufferToFill,                                          // buffer to enqueue
                                                         (player.pointee.packetDescs == nil ? 0 : nPackets),    // number of packet descriptions
                                                         player.pointee.packetDescs),                           // pointer to a PacketDescriptions array
                          operation: "AudioQueueEnqueueBuffer failed")
            
            player.pointee.packetPosition += Int64(nPackets)
            
        } else {
            
            Utility.check(error: AudioQueueStop(queue, false),
                          operation: "AudioQueueStop failed")
            
            player.pointee.isDone = true
        }
    
}

//--------------------------------------------------------------------------------------------------
// MARK: Properties

var kPlaybackFileLocation = CFStringCreateWithCString(kCFAllocatorDefault, "/Users/jzd/Downloads/essays_francis_bacon_cv3_librivox_64kb_mp3/essays_07_bacon_64kb.mp3", CFStringBuiltInEncodings.UTF8.rawValue)

// kPlaybackFileLocation = CFStringCreateWithCString(kCFAllocatorDefault, "/Users/jzd/Music/dev_src/up.m4a", CFStringBuiltInEncodings.UTF8.rawValue)


let kNumberPlaybackBuffers = 3

//--------------------------------------------------------------------------------------------------
// MARK: Main

var player = Player()
    
let fileURL: CFURL  = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, kPlaybackFileLocation, .cfurlposixPathStyle, false)

// open the audio file, set the playbackFile property in the player struct
Utility.check(error: AudioFileOpenURL(fileURL,                              // file URL to open
                                      .readPermission,                      // open to read
                                      0,                                    // hint
                                      &player.playbackFile),                // set on output to the AudioFileID
              operation: "AudioFileOpenURL failed")


// get the audio data format from the file
var dataFormat = AudioStreamBasicDescription()

var propSize = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)


Utility.check(error: AudioFileGetProperty(player.playbackFile!,             // AudioFileID
                                          kAudioFilePropertyDataFormat,     // desired property
                                          &propSize,                        // size of the property
                                          &dataFormat),                     // set on output to the ASBD
              operation: "couldn't get file's data format");
    
// create an output (playback) queue
var queue: AudioQueueRef?
Utility.check(error: AudioQueueNewOutput(&dataFormat,                       // pointer to the ASBD
                                         outputCallback,                    // callback function
                                         &player,                           // pointer to the player struct
                                         nil,                               // run loop
                                         nil,                               // run loop mode
                                         0,                                 // flags (always 0)
                                         &queue),                           // pointer to the queue
              operation: "AudioQueueNewOutput failed");
    
    
// adjust buffer size to represent about a half second (0.5) of audio based on this format
var bufferByteSize: UInt32 = 0
CalculateBytesForTime(inAudioFile: player.playbackFile!, inDesc: dataFormat,  inSeconds: 0.5, outBufferSize: &bufferByteSize, outNumPackets: &player.numPacketsToRead)

// check if we are dealing with a variable-bit-rate file. ASBDs for VBR files always have
// mBytesPerPacket and mFramesPerPacket as 0 since they can fluctuate at any time.
// If we are dealing with a VBR file, we allocate memory to hold the packet descriptions
if dataFormat.mBytesPerPacket == 0 || dataFormat.mFramesPerPacket == 0{
    
    // variable bit rate formats
    
    
    
    let s = MemoryLayout<AudioStreamPacketDescription>.size
    
    player.packetDescs = UnsafeMutablePointer<AudioStreamPacketDescription>.allocate(capacity: s * Int(player.numPacketsToRead))
    

} else {
    
    // constant bit rate formats (we don't provide packet descriptions, e.g linear PCM)
    player.packetDescs = nil;
}

// get magic cookie from file and set on queue
Utility.applyEncoderCookie(fromFile: player.playbackFile!, toQueue: queue!)

// allocate the buffers
var buffers = [AudioQueueBufferRef?](repeating: nil, count: kNumberPlaybackBuffers)

player.isDone = false
player.packetPosition = 0

// prime the queue with some data before starting
for i in 0..<kNumberPlaybackBuffers where !player.isDone {
    
    // allocate a buffer of the specified size in the given queue
    //      places an AudioQueueBufferRef in the buffers array
    Utility.check(error: AudioQueueAllocateBuffer(queue!,                               // AudioQueueRef
                                                  bufferByteSize,                       // number of bytes to allocate
                                                  &buffers[i]),                         // on output contains an AudioQueueBufferRef
                  operation: "AudioQueueAllocateBuffer failed")
    
    // manually invoke callback to fill buffers with data
    outputCallback(userData: &player, queue: queue!, bufferToFill: buffers[i]!)
}

// start the queue. this function returns immedatly and begins
// invoking the callback, as needed, asynchronously.
Utility.check(error: AudioQueueStart(queue!, nil), operation: "AudioQueueStart failed")

Swift.print("Playing...\n");

// and wait
repeat{
    CFRunLoopRunInMode(CFRunLoopMode.defaultMode, 0.25, false)
} while !player.isDone

// isDone represents the state of the Audio File enqueuing. This does not mean the
// Audio Queue is actually done playing yet. Since we have 3 half-second buffers in-flight
// run for continue to run for a short additional time so they can be processed
CFRunLoopRunInMode(CFRunLoopMode.defaultMode, 2, false)

// end playback
player.isDone = true
Utility.check(error: AudioQueueStop(queue!, true), operation: "AudioQueueStop failed");

// cleanup
AudioQueueDispose(queue!, true)
AudioFileClose(player.playbackFile!)

exit(0)


