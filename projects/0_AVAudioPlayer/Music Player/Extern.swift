//
//  Extern.swift
//  Music Player
//
//  Created by Jz D on 2019/7/23.
//  Copyright © 2019 polat. All rights reserved.
//

import Foundation




extension UserDefaults{
    
    
    func intVal(forKey defaultName: String)->Int{
        if let val = UserDefaults.standard.object(forKey: AudioTags.currentIndex.rawValue) as? Int{
            return val
        }else{
            return 0
        }
    }
    
    
}
