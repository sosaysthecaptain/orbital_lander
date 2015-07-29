//
//  GameScene.swift
//  OrbitalLander
//
//  Created by Marc Auger on 7/28/15.
//  Copyright (c) 2015 Marc Auger. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var backgroundNode: SKNode!
    var midgroundNode: SKNode!
    var foregroundNode: SKNode!
    var HUDNode: SKNode!
    var shipNode: SKSpriteNode!
    var throttleNode: SKSpriteNode!
    var leftThrottleNode: SKSpriteNode!
    var rightThrottleNode: SKSpriteNode!
    var dt: NSTimeInterval = 0
    var lastUpdateTime: NSTimeInterval = 0
    var downThrustOn: Bool = false
    var leftThrustOn: Bool = false
    var rightThrustOn: Bool = false
    var fuel: Double = 100.0
    //var health: Double = 100.0        // FOR TESTING ONLY
    var health: Double = 1.0
    var fuelBarNode: SKSpriteNode!
    var healthBarNode: SKSpriteNode!
    var padNode: SKSpriteNode!
    var shipSpeed: CGFloat = 0
    var oldSpeed: CGFloat = 0
    var deltaV: CGFloat = 0
    var speeds: [CGFloat] = []
    var starFlag: Bool = false
    var died: Bool = false
    var exploded: Bool = false
    
    var verticalThrustNode = SKNode()
    var verticalThrustContainer = SKNode()
    var leftThrustNode = SKNode()
    var leftThrustContainer = SKNode()
    var rightThrustNode = SKNode()
    var rightThrustContainer = SKNode()
    
    
    override func didMoveToView(view: SKView) {
        // calculate playable margin
        let maxAspectRatio: CGFloat = 16.0/9.0      // iphone 5
        let maxAspectRatioHeight = size.width / maxAspectRatio
        let playableMargin: CGFloat = (size.height - maxAspectRatioHeight)/2
        let playableRect = CGRect(x: 0, y: playableMargin, width: size.width, height: size.height - playableMargin*2)
        
        // border and gravity
        physicsBody = SKPhysicsBody(edgeLoopFromRect: playableRect)
        scene?.physicsWorld.gravity = CGVector(dx: 0, dy: -1.75)
        physicsWorld.contactDelegate = self
        physicsBody!.categoryBitMask = PhysicsCategory.Wall
        
        // set up nodes
        shipNode = childNodeWithName("ship") as! SKSpriteNode
        throttleNode = childNodeWithName("throttle") as! SKSpriteNode
        
        leftThrottleNode = childNodeWithName("leftThrust") as! SKSpriteNode
        rightThrottleNode = childNodeWithName("rightThrust") as! SKSpriteNode
        fuelBarNode = childNodeWithName("fuelBar") as! SKSpriteNode
        padNode = childNodeWithName("pad") as! SKSpriteNode
        
        // configure shipNode physics body. Needs to be set to none in GUI
        let shipTexture = SKTexture(imageNamed: "lander1")
        shipNode.physicsBody = SKPhysicsBody(texture: shipTexture, size: shipNode.size)
        
        shipNode.physicsBody?.angularDamping = 0.75
        shipNode.physicsBody?.usesPreciseCollisionDetection = true
        
        shipNode.addChild(verticalThrustContainer)
        shipNode.addChild(leftThrustContainer)
        shipNode.addChild(rightThrustContainer)
        
        
        // category bitmasks
        shipNode.physicsBody?.categoryBitMask = PhysicsCategory.Ship
        shipNode.physicsBody?.collisionBitMask = PhysicsCategory.Wall | PhysicsCategory.Box | PhysicsCategory.Pad
        shipNode.physicsBody!.contactTestBitMask = PhysicsCategory.Pad | PhysicsCategory.Box | PhysicsCategory.Wall | PhysicsCategory.Star
        
        
        
        setupUI()
        
        // testing only
        let star = createStarAtPosition(CGPoint(x: 500, y: 500))
        addChild(star)
        
        let star2 = createStarAtPosition(CGPoint(x: 500, y: 600))
        addChild(star2)
        
        // enumerate all SKSpriteNodes called "star" and make them of class StarNode
        enumerateChildNodesWithName("star") { node, _ in
            let position = node.position
            node.removeFromParent()
            let newStar = self.createStarAtPosition(position)
            self.addChild(newStar)
            
            //newStarNode.addChild(node)
        }
    }
    
    // touch information starts here
    // scoping these outside touchesBegan lets them be tracked from beginning to end
    var rawTouch: UITouch!
    var throttleTouch: UITouch!
    var leftTouch: UITouch!
    var rightTouch: UITouch!
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        rawTouch = touches.first as! UITouch
        sceneTouched(rawTouch.locationInNode(self))
        //let touch: UITouch = touches.first as! UITouch
        //sceneTouched(touch.locationInNode(self))
    }
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        let touch: UITouch = touches.first as! UITouch
        if touch == throttleTouch {
            downThrustOn = false
            stopFiringMainThruster()
        } else if touch == leftTouch {
            leftThrustOn = false
            stopFiringLeftThruster()
        } else if touch == rightTouch {
            rightThrustOn = false
            stopFiringRightThruster()
        }
    }
    
    // respond to touches fed in by touchesBegan
    func sceneTouched(location: CGPoint) {
        let targetNode = self.nodeAtPoint(location)
        
        if targetNode == throttleNode {
            downThrustOn = true
            fireMainThruster()
            throttleTouch = rawTouch
        }
        if targetNode == leftThrottleNode {
            leftThrustOn = true
            fireLeftThruster()
            leftTouch = rawTouch
        }
        if targetNode == rightThrottleNode {
            rightThrustOn = true
            fireRightThruster()
            rightTouch = rawTouch
        }
        
        
    }
    
    
    override func update(currentTime: NSTimeInterval) {
        if lastUpdateTime > 0 {
            dt = currentTime - lastUpdateTime
        } else {
            dt = 0
        }
        lastUpdateTime = currentTime
        
        if downThrustOn && (fuel > 0) {
            // get zRotation of shipNode
            // create yVector and xVector based on that
            let forceY = 600 * cos(shipNode.zRotation)
            let forceX = -600 * sin(shipNode.zRotation)
            shipNode.physicsBody!.applyForce(CGVector(dx: forceX, dy: forceY))
            fuel -= 0.04
        }
        if leftThrustOn && (fuel > 0) {
            let forceY = 300 * cos(shipNode.zRotation)
            let forceX = 300 * cos(shipNode.zRotation)
            
            shipNode.physicsBody!.applyForce(CGVector(dx: forceX, dy: forceY))
            fuel -= 0.02
        }
        if rightThrustOn && (fuel > 0) {
            let forceY = -300 * cos(shipNode.zRotation)
            let forceX = -300 * cos(shipNode.zRotation)
            
            shipNode.physicsBody!.applyForce(CGVector(dx: forceX, dy: forceY))
            //shipNode.physicsBody!.applyForce(CGVector(dx: -200, dy: 0))
            fuel -= 0.02
        }
        
        if fuel <= 0 {
            stopFiringMainThruster()
            stopFiringLeftThruster()
            stopFiringRightThruster()
        }
        
        // see if still alive
        if health <= 0 {
            died = true
        }
        
        if died == true && exploded == false {
            exploded = true
            println("exploded: \(exploded) BOOM")
        }
        
        //println("angular velocity: \(shipNode.physicsBody?.angularVelocity)")
        //println("position: \(shipNode!.position)")
        //println("rotation: \(shipNode!.zRotation % 6.28318530718)")
        //println("angular velocity: \(shipNode.physicsBody?.angularVelocity)")
        
        // stabilize rotation
        if abs(shipNode.zRotation) > 0.05 {
            //println("not level")
            if shipNode.zRotation > 0 {
                shipNode.physicsBody?.applyTorque(-0.5)
                //println("greater than zero. correcting")
            } else if shipNode.zRotation < 0 {
                shipNode.physicsBody?.applyTorque(0.5)
                //println("less than zero. correcting")
            }
        }
        
        //println(NSString(format: "x velocity: %.2f", shipNode.physicsBody!.velocity.dx))
        //println(NSString(format: "fuel: %.2f", fuel))
        
        // update fuel bar
        fuelBarNode.anchorPoint = CGPoint(x: 0, y: 0)
        fuelBarNode.position = CGPoint(x: 170, y: 1180)
        fuelBarNode.size = CGSize(width: fuel * 3, height: 40)
        
        // update health bar
        healthBarNode.size = CGSize(width: max(health * 3, 0), height: 40)
        
        // time business
        let currentTime = currentTime
        
        // calculate speed
        let xVel = shipNode.physicsBody?.velocity.dx
        let yVel = shipNode.physicsBody?.velocity.dy
        //oldSpeed = shipSpeed
        shipSpeed = sqrt(xVel! * xVel! + yVel! * yVel!)
        deltaV = shipSpeed - oldSpeed
        if speeds.count > 25 {
            oldSpeed = speeds[0]
            speeds.removeAtIndex(0)
            speeds.append(shipSpeed)
        } else {
            speeds.append(shipSpeed)
        }
        
    }
    
    struct PhysicsCategory {
        static let None:        UInt32 = 0
        static let Ship:        UInt32 = 0b1        // 1
        static let Wall:        UInt32 = 0b10       // 2
        static let Box:         UInt32 = 0b100      // 4
        static let Pad:         UInt32 = 0b1000     // 8
        static let Star:        UInt32 = 0b10000    // 16
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        let collision: UInt32 = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        if collision == PhysicsCategory.Ship | PhysicsCategory.Pad {
            //println("CONTACT WITH PAD")
            // TODO: HANDLE HEALTH DECREMENT
            // CREATE FUNCTION TO GIVE SCALAR VELOCITY?
            if shipNode.physicsBody?.velocity.dx < 1 && shipNode.physicsBody?.velocity.dy < 1 {
                println("landed")
            }
        }
        
        if collision == PhysicsCategory.Ship | PhysicsCategory.Wall {
            health -= calculateDamage(shipSpeed, velocity: shipNode.physicsBody!.velocity, deltaV: deltaV)
        }
        
        // should probably use this
        var updateHUD = false
        
        // other is the object that is not the ship
        let whichNode = (contact.bodyA.node != shipNode) ? contact.bodyA.node : contact.bodyB.node
        
        // HANDLE STARS/BOXES: IF OTHER IS OF CLASS GAMEOBJECTNODE, DO THIS:
        if whichNode is GameObjectNode {
            let other = whichNode as! GameObjectNode
            updateHUD = other.collisionWithShip(shipNode)
        }
        
        
        //        } else if collision == PhysicsCategory.Ship | PhysicsCategory.Box {
        //            //println("contact with box")
        //            // TODO: HANDLE HEALTH DECREMENT
        //        } else if collision == PhysicsCategory.Ship | PhysicsCategory.Wall {
        //            //println("touching wall")
        //            //println("CRASH. shipSpeed: \(shipSpeed), oldSpeed: \(oldSpeed)")
        //            //println("deltaV: \(deltaV)")
        //            if deltaV > 50 && deltaV < 100 {
        //                println("minor collision: \(deltaV)")
        //                health -= Double(deltaV * 0.05)
        //            } else if deltaV >= 100 && deltaV < 200{
        //                health -= Double(deltaV * 0.03)
        //                println("significant collision: \(deltaV)")
        //            } else if deltaV >= 200 {
        //                println("huge collision")
        //                health -= Double(deltaV * 0.025)
        //            }
        //        }
    }
    
    func didEndContact(contact: SKPhysicsContact) {
        starFlag = false
    }
    
    func setupUI() {
        // health bar background
        let healthBarBackground = SKSpriteNode(color: SKColor.blackColor(), size: CGSize(width: 300, height: 40))
        healthBarBackground.position = CGPoint(x: 170, y: 1250)
        healthBarBackground.anchorPoint = CGPoint(x: 0, y: 0)
        healthBarBackground.zPosition = 100
        self.addChild(healthBarBackground)
        
        // fuel bar background
        let fuelBarBackground = SKSpriteNode(color: SKColor.blackColor(), size: CGSize(width: 300, height: 40))
        fuelBarBackground.position = CGPoint(x: 170, y: 1320)
        fuelBarBackground.anchorPoint = CGPointZero
        fuelBarBackground.zPosition = 0
        //self.addChild(fuelBarBackground)
        
        // health bar (already initialized)
        healthBarNode = SKSpriteNode(color: SKColor.greenColor(), size: CGSize(width: 300, height: 40))
        healthBarNode.position = CGPoint(x: 170, y: 1250)
        healthBarNode.anchorPoint = CGPointZero
        healthBarNode.zPosition = 105
        self.addChild(healthBarNode)
    }
    
    func calculateDamage(shipSpeed: CGFloat, velocity: CGVector, deltaV: CGFloat) -> Double {
        var damage: Double = 0.0
        // stupid kludge cuz deltaV method sucks
        var fixedDeltaV: CGFloat = 0.0
        if deltaV < 0 {
            fixedDeltaV = 0.0
        } else {
            fixedDeltaV = deltaV
        }
        //println("calculateDamage called. shipSpeed: \(shipSpeed) dx: \(velocity.dx), dy: \(velocity.dy), deltaV: \(deltaV)")
        if deltaV > 50 && velocity.dy < 50 && velocity.dy > -50 {
            //println("deltaV between 50 and 150")
            //println("full damage. dy: \(velocity.dy)")
            damage = Double(fixedDeltaV * 0.1)
        } else if velocity.dy >= 50 || velocity.dy <= -50 {
            //println("high vertical velocity case. dy: \(velocity.dy)")
            damage = Double(fixedDeltaV * 0.05)
        }
        return damage
    }
    
    func createShip() -> SKNode {
        let playerNode = SKNode()
        playerNode.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
        
        let sprite = SKSpriteNode(imageNamed: "lander1")
        let shipTexture = SKTexture(imageNamed: "lander1")
        //playerNode.physicsBody = SKPhysicsBody(texture: shipTexture, size: playerNode.size)
        // don't know how to set alpha mask
        
        return playerNode
    }
    
    // should properly be in a playerShip class
    func fireMainThruster() {
        let mainThrusterEmitter = SKEmitterNode(fileNamed: "MainThruster.sks")
        mainThrusterEmitter.position = CGPoint(x: 1, y: -100)
        mainThrusterEmitter.name = "mainThrusterEmitter"
        // maybe this will help
        let verticalThrustNode = SKNode()
        verticalThrustNode.addChild(mainThrusterEmitter)
        verticalThrustContainer.addChild(verticalThrustNode)
    }
    
    func stopFiringMainThruster() {
        verticalThrustContainer.removeAllChildren()
    }
    
    func fireLeftThruster() {
        let leftThrusterEmitter = SKEmitterNode(fileNamed: "LeftThruster.sks")
        leftThrusterEmitter.position = CGPoint(x: -75, y: 0)
        leftThrusterEmitter.name = "leftThrusterEmitter"
        leftThrustNode.addChild(leftThrusterEmitter)
        leftThrustContainer.addChild(leftThrustNode)
    }
    
    func stopFiringLeftThruster() {
        leftThrustContainer.removeAllChildren()
    }
    
    func fireRightThruster() {
        let rightThrusterEmitter = SKEmitterNode(fileNamed: "RightThruster.sks")
        rightThrusterEmitter.position = CGPoint(x: 75, y: 0)
        rightThrusterEmitter.name = "rightThrusterEmitter"
        rightThrustNode.addChild(rightThrusterEmitter)
        rightThrustContainer.addChild(rightThrustNode)
    }
    
    func stopFiringRightThruster() {
        rightThrustContainer.removeAllChildren()
    }
    
    func createStarAtPosition(position: CGPoint) -> StarNode {
        let node = StarNode()
        let thePosition = CGPoint(x: position.x, y: position.y)
        node.position = thePosition
        node.name = "NODE_STAR"
        
        var sprite: SKSpriteNode
        sprite = SKSpriteNode(imageNamed: "Star")
        node.addChild(sprite)
        
        node.physicsBody = SKPhysicsBody(circleOfRadius: sprite.size.width / 2)
        node.physicsBody?.dynamic = false
        node.physicsBody?.categoryBitMask = PhysicsCategory.Star
        node.physicsBody?.collisionBitMask = 0
        
        return node
    }
    
}
