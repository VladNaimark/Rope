//
//  Rope.swift
//  Rope
//
//  Created by Vlad Naimark on 4/29/18.
//  Copyright © 2018 Vlad Naimark. All rights reserved.
//

import Foundation
import SceneKit

// https://whoischris.com/build-3d-chainstringrope-scenekit-swift/
class Rope {
    private var ropeSegments = [SCNNode]()
    private var linkNodeGeometry : SCNCapsule!
    private lazy var linkNodePhysics : SCNPhysicsBody = {
        let geometry = SCNCapsule(capRadius: linkNodeGeometry.capRadius,
                                  height: linkNodeGeometry.height + linkNodeGeometry.capRadius*2)
        let body = SCNPhysicsBody(type: SCNPhysicsBodyType.dynamic,
                                  shape: SCNPhysicsShape(geometry: geometry))
//            shape: nil)
        body.isAffectedByGravity = true
        body.mass = 1
        return body
    }()
    private var joints = [SCNPhysicsBallSocketJoint]()
    private let world: SCNPhysicsWorld!
    
    var startNode : SCNNode? {
        return ropeSegments.first
    }
    var endNode : SCNNode? {
        return ropeSegments.last
    }
    let segmentsCount : Int
//    let radius : CGFloat {
//        didSet {
//            linkNodeGeometry.radius = radius
//        }
//    }
//    let segmentLength : CGFloat {
//        didSet {
//            linkNodeGeometry.height = segmentLength
//        }
//    }
    
    required init(segmentsCount: Int, radius: CGFloat, segmentLength: CGFloat, world: SCNPhysicsWorld) {
        linkNodeGeometry = SCNCapsule(capRadius: radius, height: segmentLength)
        self.world = world
        self.segmentsCount = segmentsCount
        self.linkNodeGeometry.firstMaterial?.diffuse.contents = UIColor.blue
        createRope()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func attachTo(parent: SCNNode, anchor: SCNVector3) {
        for segment in ropeSegments {
            parent.addChildNode(segment)
        }
        let joint = SCNPhysicsBallSocketJoint(bodyA: parent.physicsBody!,
                                              anchorA: anchor,
                                              bodyB: (ropeSegments.first?.physicsBody)!,
//                                              anchorB: SCNVector3(x: 0, y: Float(-linkNodeGeometry.capRadius), z: 0))
//            anchorB: SCNVector3(x: 0, y: Float(linkNodeGeometry.height / 2), z: 0))
            anchorB: SCNVector3(x: 0, y: Float(linkNodeGeometry.height + linkNodeGeometry.capRadius*2)/2, z: 0))
        world.addBehavior(joint)
    }
    
    private func createRope() {
        if ropeSegments.count < segmentsCount {
            let cnt = ropeSegments.count
            for _ in cnt..<segmentsCount {
                
                let lastNode = ropeSegments.last
                let newNode = SCNNode(geometry: linkNodeGeometry)
                newNode.physicsBody = linkNodePhysics.copy() as? SCNPhysicsBody
                
                if let lastBody = lastNode?.physicsBody, let newBody = newNode.physicsBody {
                    let joint = SCNPhysicsBallSocketJoint(bodyA: lastBody,
                                                        anchorA: SCNVector3(x: 0, y: -Float(linkNodeGeometry.height/2), z: 0),
                                                          bodyB: newBody,
                                                          anchorB: SCNVector3(x: 0, y: Float(linkNodeGeometry.height/2), z: 0))
                    joints.append(joint)
                    world.addBehavior(joint)
                }
                
                ropeSegments.append(newNode)
            }
        } else if ropeSegments.count > segmentsCount {
            let cnt = ropeSegments.count - segmentsCount
            for _ in 0..<cnt {
                if let joint = joints.popLast() {
                    world.removeBehavior(joint)
                }
            }
            ropeSegments.removeLast(cnt)
        }
    }
}
