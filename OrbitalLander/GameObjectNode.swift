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
    func collisionWithShip(player: SKNode) -> Bool {
        return false
    }
    
}

class StarNode: GameObjectNode {
    var flag = false
    
    override func collisionWithShip(player: SKNode) -> Bool {
        
        if flag == false {
            flag = true
            stars += 1
            print("stars: \(stars)")
            self.removeFromParent()
        }
        
        // The HUD needs updating to show the new stars and score
        return true
    }
}