//
//  CDYelpFusionKit.swift
//  Find&Dine
//
//  Created by Yan Wen Huang on 6/17/18.
//  Copyright © 2018 WIT Senior Design. All rights reserved.
//

import CDYelpFusionKit
import UIKit

final class CDYelpFusionKitManager: NSObject {
    static let shared = CDYelpFusionKitManager()
    var apiClient: CDYelpAPIClient!
    
    func configure() {
        self.apiClient = CDYelpAPIClient(apiKey: "kGYByIBQ7we_w1NzMu7vlcxXw0FkM7FcFQpphMExWkzAvSCYTenJkTT4Ps5pOT_AoDwPB2LkHJ8HxExdL0spNO0I-qx5NIZwzPkGLtMBsojzzmPoO7ouYtIlomITW3Yx")
    }
}
