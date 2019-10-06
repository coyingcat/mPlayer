//
//  UserSettings.swift
//  Music Player
//
//  Created by Jz D on 2019/10/6.
//  Copyright © 2019 polat. All rights reserved.
//

import Foundation


enum Keys{
    static let isInShuffle = "shuffleState"
    static let isInRepeat = "repeatState"
}


struct UserSettings {
    
    static var shared = UserSettings()
    
    
    var isInShuffle: Bool{
        get {
            return UserDefaults.standard.bool(forKey: Keys.isInShuffle)
        }
        set(newVal){
            UserDefaults.standard.set(newVal, forKey: Keys.isInShuffle)
        }
    }
    
    var isInRepeat: Bool{
        get {
            return UserDefaults.standard.bool(forKey: Keys.isInRepeat)
        }
        set(newVal){
            UserDefaults.standard.set(newVal, forKey: Keys.isInRepeat)
        }
    }
    
    
    
}
