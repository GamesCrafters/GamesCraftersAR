//
//  MoveOverlay.swift
//  AR-TicTacToe
//
//  Created by Siddharth Ganapathy on 3/16/26.
//  Copyright © 2026 Bjarne Møller Lundgren. All rights reserved.
//

import SceneKit
import UIKit

class MoveOverlay {

    // All dot/arrow nodes for the current turn
    private var moveNodes: [SCNNode] = []
    // Remoteness text node
    private var textNode: SCNNode?

    // MARK: - Public

    /// Show colored dots on every legal move cell (placement games)
    func showAllDots(
        moves: [(position: SCNVector3, moveValue: String)],
        in scene: SCNScene
    ) {
        clear()
        for move in moves {
            let disc = SCNCylinder(radius: 0.025, height: 0.005)
            disc.materials = [colorMaterial(for: move.moveValue)]

            let node = SCNNode(geometry: disc)
            node.position = SCNVector3(
                move.position.x,
                move.position.y + 0.015,
                move.position.z
            )

            let pulseUp = SCNAction.scale(to: 1.15, duration: 0.5)
            let pulseDown = SCNAction.scale(to: 1.0, duration: 0.5)
            pulseUp.timingMode = .easeInEaseOut
            pulseDown.timingMode = .easeInEaseOut
            node.runAction(.repeatForever(.sequence([pulseUp, pulseDown])))

            scene.rootNode.addChildNode(node)
            moveNodes.append(node)
        }
    }

    /// Show a single colored dot above a cell + remoteness text (used for AI best move highlight)
    func showDot(
        at position: SCNVector3,
        moveValue: String,
        remoteness: Int,
        in scene: SCNScene
    ) {
        // Don't clear — layered on top of showAllDots
        let disc = SCNCylinder(radius: 0.032, height: 0.006)  // slightly larger than regular dots
        disc.materials = [colorMaterial(for: moveValue)]

        let node = SCNNode(geometry: disc)
        node.position = SCNVector3(position.x, position.y + 0.02, position.z)

        let pulseUp = SCNAction.scale(to: 1.2, duration: 0.4)
        let pulseDown = SCNAction.scale(to: 1.0, duration: 0.4)
        pulseUp.timingMode = .easeInEaseOut
        pulseDown.timingMode = .easeInEaseOut
        node.runAction(.repeatForever(.sequence([pulseUp, pulseDown])))

        scene.rootNode.addChildNode(node)
        moveNodes.append(node)

    }

    /// Show colored arrow from one cell to another + remoteness text (movement games)
    func showArrow(
        from fromPosition: SCNVector3,
        to toPosition: SCNVector3,
        moveValue: String,
        remoteness: Int,
        in scene: SCNScene
    ) {
        // Don't clear — may be layered on top of dots
        let dx = toPosition.x - fromPosition.x
        let dz = toPosition.z - fromPosition.z
        let length = sqrt(dx*dx + dz*dz)

        // Shaft
        let shaft = SCNCylinder(radius: 0.005, height: CGFloat(length * 0.8))
        shaft.materials = [colorMaterial(for: moveValue)]
        let shaftNode = SCNNode(geometry: shaft)
        shaftNode.position = SCNVector3(
            (fromPosition.x + toPosition.x) / 2,
            fromPosition.y + 0.02,
            (fromPosition.z + toPosition.z) / 2
        )
        shaftNode.eulerAngles = SCNVector3(Float.pi / 2, 0, -atan2(dx, dz))

        // Arrowhead
        let head = SCNCone(topRadius: 0, bottomRadius: 0.015, height: 0.03)
        head.materials = [colorMaterial(for: moveValue)]
        let headNode = SCNNode(geometry: head)
        headNode.position = SCNVector3(0, Float(length * 0.4), 0)
        shaftNode.addChildNode(headNode)

        scene.rootNode.addChildNode(shaftNode)
        moveNodes.append(shaftNode)

    }

    /// Clear all dots or arrows
    func clear() {
        moveNodes.forEach {
            $0.removeAllActions()
            $0.removeFromParentNode()
        }
        moveNodes = []
    }

    private func color(for moveValue: String) -> UIColor {
        switch moveValue {
        case "win":  return UIColor(red: 0.2,  green: 0.85, blue: 0.3,  alpha: 1)
        case "lose": return UIColor(red: 0.95, green: 0.3,  blue: 0.25, alpha: 1)
        default:     return UIColor(red: 1.0,  green: 0.85, blue: 0.1,  alpha: 1)
        }
    }

    private func colorMaterial(for moveValue: String) -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = color(for: moveValue)
        material.isDoubleSided = true
        return material
    }
}
