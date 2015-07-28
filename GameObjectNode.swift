//
//  GameObjectNode.swift
//  
//
//  Created by Marc Auger on 7/28/15.
//
//

import SpriteKit

var stars: Int = 0

class GameObjectNode: SKNode {
    func collisionWithPlayer(player: SKNode) -> Bool {
        return false
    }
    
}

class StarNode: GameObjectNode {
    override func collisionWithPlayer(player: SKNode) -> Bool {
        var flag = false
        
        if flag == false {
            stars += 1
            flag = true
        }
        
        
        // Remove this Star
        self.removeFromParent()
        
        // The HUD needs updating to show the new stars and score
        return true
    }
}