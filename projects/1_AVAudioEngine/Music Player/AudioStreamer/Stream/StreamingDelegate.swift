
import Foundation

/// The `StreamingDelegate` provides an interface for responding to changes to a `Streaming` instance. These include whenever the streamer state changes, when the download progress changes, as well as the current time and duration changes.

public protocol StreamingDelegate: class {

    
    
    /// Triggered when the playback `state` changes.
    ///
    /// - Parameters:
    ///   - streamer: The current `Streaming` instance
    ///   - state: A `StreamingState` representing the new state value.
    
    func streamer(_ streamer: Streaming, changedState state: StreamingState)
    
    /// Triggered when the current play time is updated.
    ///
    /// - Parameters:
    ///   - streamer: The current `Streaming` instance
    ///   - currentTime: A `TimeInterval` representing the new current time value.

    func streamer(_ streamer: Streaming, updatedCurrentTime currentTime: TimeInterval)
    
    /// Triggered when the duration is updated.
    ///
    /// - Parameters:
    ///   - streamer: The current `Streaming` instance
    ///   - duration: A `TimeInterval` representing the new duration value.
 
    func streamer(_ streamer: Streaming, updatedDuration duration: TimeInterval)
    
}




extension StreamingDelegate{
    
    func streamer(_ streamer: Streaming, changedState state: StreamingState){}
    
    func streamer(_ streamer: Streaming, updatedCurrentTime currentTime: TimeInterval){}
    
    
    func streamer(_ streamer: Streaming, updatedDuration duration: TimeInterval){}
    
    
}
