//
//  VoidInstance.swift
//  Fibor
//
//  Created by Tristan Barnes on 10/8/17.
//  Copyright © 2017 Tristan Barnes. All rights reserved.
//

import Foundation


class VoidInstance: Instance {
    
    init(_ address: Int) {
        super.init(.void, VoidType(), address, [:])
    }
    
}

