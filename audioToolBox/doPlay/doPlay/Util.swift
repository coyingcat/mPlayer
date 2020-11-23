//
//  Util.swift
//  doPlay
//
//  Created by Jz D on 2020/11/23.
//

import Foundation

import AudioToolbox

class Utility {
    //
    // convert a Core Audio error code to a printable string
    //
    static func codeToString(_ error: OSStatus) -> String {
        
        // byte swap the error
        let errorCode = CFSwapInt32HostToBig(UInt32(bitPattern: error))

        // separate the UInt32 into 4 bytes
        var bytes = [UInt8](repeating: 0, count: 4)
        bytes[0] = UInt8(errorCode & 0x000000ff)
        bytes[1] = UInt8( (errorCode & 0x0000ff00) >> 8)
        bytes[2] = UInt8( (errorCode & 0x00ff0000) >> 16)
        bytes[3] = UInt8( (errorCode & 0xff000000) >> 24)
        
        // do the four bytes all represent printable characters?
        if isprint(Int32(bytes[0])) != 0 && isprint(Int32(bytes[1])) != 0 &&
            isprint(Int32(bytes[2])) != 0 && isprint(Int32(bytes[3])) != 0 {
            
            // YES, return a String made from them
            return String(bytes: bytes, encoding: String.Encoding.ascii)!
        
        } else {
            
            // NO, treat the UInt32 as a number and create a String of the number
            return String(format: "%d", error)
        }
    }
    //
    // generic error handler - if error is nonzero, prints error message and exits program.
    //
    static func check(error: OSStatus , operation: String) {
    
        // return if no error
        if error == noErr { return }
        
        // print either four characters or the numeric value
        Swift.print("Error: \(operation), returned: \(codeToString(error))")
        
        // terminate the program
        exit(1)
    }
    //
    // Copy a file's magic cookie to a queue
    //
    static func applyEncoderCookie(fromFile file: AudioFileID, toQueue queue: AudioQueueRef) {
        var propertySize: UInt32 = 0
        
        // get the magic cookie, if any, from the file
        let result = AudioFileGetPropertyInfo (file, kAudioFilePropertyMagicCookieData, &propertySize, nil)

        // is there a cookie?
        if result == noErr && propertySize > 0 {
            
            // YES, allocate space for it
            let magicCookie: UnsafeMutableRawPointer  = malloc(4)

            // get the cookie
            Utility.check(error: AudioFileGetProperty (file,
                                                       kAudioFilePropertyMagicCookieData,
                                                       &propertySize,
                                                       magicCookie),
                          operation: "get cookie from file failed");
            
            // now set the magic cookie on the queue
            Utility.check(error: AudioQueueSetProperty(queue,
                                                       kAudioQueueProperty_MagicCookie,
                                                       magicCookie,
                                                       propertySize),
                          operation: "set cookie on queue failed");

            // release the malloc'd memory
            free(magicCookie);
        }
    }

}






