//
//  Earth.swift
//  TaskARApp
//
//  Created by 福島悠樹 on 2020/07/21.
//  Copyright © 2020 福島悠樹. All rights reserved.
//

import Foundation
import SceneKit
import ARKit

protocol EarthDelegate:class {
    /* NoAction */
}

class EarthMgr{
    static let sharedInstance = EarthMgr()
    
    var scene:SCNScene? = nil
    var node:SCNNode? = nil
    
    weak var delegate:EarthDelegate?
    
    func setCurrentScene(currentScene:SCNScene){
        scene = currentScene
    }
    
    func getCurrentScene() -> SCNScene{
        guard let scene=scene else {
            print("ERR")
            let scene = SCNScene()
            return scene
        }
        return scene
    }
    
    func setCurrentNode(currentNode:SCNNode){
        node = currentNode
    }
    
    func getCurrentNode() -> SCNNode{
        guard let node=node else {
            print("ERR")
            let node = SCNNode()
            return node
        }
        return node
    }
}
