
import Foundation
import AVFoundation
import os.log

func ParserPacketCallback(_ context: UnsafeMutableRawPointer, _ byteCount: UInt32, _ packetCount: UInt32, _ data: UnsafeRawPointer, _ packetDescriptions: UnsafeMutablePointer<AudioStreamPacketDescription>) {
    let parser = Unmanaged<Parser>.fromOpaque(context).takeUnretainedValue()
    let packetDescriptionsOrNil: UnsafeMutablePointer<AudioStreamPacketDescription>? = packetDescriptions
    let isCompressed = packetDescriptionsOrNil != nil
    
    
    /// At this point we should definitely have a data format
    guard let dataFormat = parser.dataFormat else {
        return
    }
    
    /// Iterate through the packets and store the data appropriately
    if isCompressed {
        for i in 0 ..< Int(packetCount) {
            let packetDescription = packetDescriptions[i]
            let packetStart = Int(packetDescription.mStartOffset)
            let packetSize = Int(packetDescription.mDataByteSize)
            let packetData = Data(bytes: data.advanced(by: packetStart), count: packetSize)
            parser.packets.append((packetData, packetDescription))
        }
    } else {
        let format = dataFormat.streamDescription.pointee
        let bytesPerPacket = Int(format.mBytesPerPacket)
        for i in 0 ..< Int(packetCount) {
            let packetStart = i * bytesPerPacket
            let packetSize = bytesPerPacket
            let packetData = Data(bytes: data.advanced(by: packetStart), count: packetSize)
            parser.packets.append((packetData, nil))
        }
    }
}
