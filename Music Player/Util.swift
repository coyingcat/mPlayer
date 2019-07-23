//
//  Util.swift
//  Music Player
//
//  Created by Jz D on 2019/7/23.
//  Copyright © 2019 polat. All rights reserved.
//

import UIKit




extension UIImageView {
    
    func setRounded() {
        let radius = self.frame.width / 2
        self.layer.cornerRadius = radius
        self.layer.masksToBounds = true
    }
}
