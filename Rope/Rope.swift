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
        let body = SCNPhysicsBody(type: SCNPhysicsBodyType.dynamic,
                                  shape: SCNPhysicsShape(geometry: linkNodeGeometry,
                                                         options: [SCNPhysicsShape.Option.scale : 0.5]))
        body.isAffectedByGravity = true
        
        body.mass = 0.1
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
        let anchorB = SCNVector3(x: 0, y: Float(linkNodeGeometry.height/2 - linkNodeGeometry.capRadius), z: 0)
        let joint = SCNPhysicsBallSocketJoint(bodyA: parent.physicsBody!,
                                              anchorA: anchor,
                                              bodyB: (startNode?.physicsBody)!,
                                              anchorB: anchorB)
        world.addBehavior(joint)
        ropeSegments.first?.position = SCNVector3(x: anchor.x, y: anchor.y - Float(linkNodeGeometry.height/2), z: anchor.z)
        arrangeSegments()
    }
    
    func attachToRope(node: SCNNode, anchor: SCNVector3) {
//        endNode?.addChildNode(node)
        guard let endNode = endNode else {
            return;
        }
        let anchorA = SCNVector3(x: 0, y: 0, z: 0)
        let joint = SCNPhysicsBallSocketJoint(bodyA: endNode.physicsBody!,
                                              anchorA: anchorA,
                                              bodyB: node.physicsBody!,
                                              anchorB: anchor)
        world.addBehavior(joint)
        node.position = SCNVector3(x: endNode.position.x,
                                   y: Float(endNode.position.y) - Float(linkNodeGeometry.height/2) - Float(node.boundingBox.max.y - node.boundingBox.min.y) / 2,
                                   z: endNode.position.z)
    }
    
    private func createRope() {
        if ropeSegments.count < segmentsCount {
            let cnt = ropeSegments.count
            for _ in cnt..<segmentsCount {
                
                let lastNode = ropeSegments.last
                let newNode = SCNNode(geometry: linkNodeGeometry)
                newNode.physicsBody = linkNodePhysics.copy() as? SCNPhysicsBody
                
                if let lastBody = lastNode?.physicsBody, let newBody = newNode.physicsBody {
                    let anchorA = SCNVector3(x: 0,
                                             y: -Float(linkNodeGeometry.height/2 - linkNodeGeometry.capRadius),
                                             z: 0)
                    let anchorB = SCNVector3(x: 0,
                                             y: Float(linkNodeGeometry.height/2 - linkNodeGeometry.capRadius),
                                             z: 0)
                    let joint = SCNPhysicsBallSocketJoint(bodyA: lastBody,
                                                        anchorA: anchorA,
                                                          bodyB: newBody,
                                                        anchorB: anchorB)
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
    
    private func arrangeSegments() {
        var previous = startNode
        for i in 1..<ropeSegments.count {
            let segment = ropeSegments[i]
            
            if let previous = previous {
                segment.position = SCNVector3(x: previous.position.x,
                                              y: previous.position.y - Float(linkNodeGeometry.height - linkNodeGeometry.capRadius * 2),
                                              z: previous.position.z)
            }
            previous = segment
        }
    }
}
