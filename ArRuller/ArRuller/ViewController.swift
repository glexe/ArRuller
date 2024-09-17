//
//  ViewController.swift
//  AR Ruller
//
//  Created by Ilya Gladyshev on 9/14/24.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    
    var dotNodes = [SCNNode]()
    var textNode = SCNNode()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        sceneView.antialiasingMode = .multisampling4X
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if dotNodes.count >= 2 {
            for dotNode in dotNodes {
                dotNode.removeFromParentNode()
            }
            dotNodes = [SCNNode]()
        }
        
        if let touch = touches.first {
            let touchLocation = touch.location(in: sceneView)
            let results = sceneView.raycastQuery(from: touchLocation, allowing: .estimatedPlane, alignment: .any)
            
            if let result = sceneView.session.raycast(results!).first {
                addDot(at: result)
            }
        }
        print("touch detected")
    }
    
    func addDot(at result: ARRaycastResult) {
        let dotGeometry = SCNSphere(radius: 0.005)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.green
        dotGeometry.materials = [material]
        
        let dotNode = SCNNode(geometry: dotGeometry)
        
        dotNode.position = SCNVector3(result.worldTransform.columns.3.x, result.worldTransform.columns.3.y, result.worldTransform.columns.3.z)
        
        sceneView.scene.rootNode.addChildNode(dotNode)
        
        dotNodes.append(dotNode)
        
        if dotNodes.count >= 2 {
            calculate()
        }
    }
    
    func calculate() {
        let start = dotNodes[0]
        let finish = dotNodes[1]
        
        let a = finish.position.x - start.position.x
        let b = finish.position.y - start.position.y
        let c = finish.position.z - start.position.z
        
        let distance = sqrt(pow(a, 2) + pow(b, 2) + pow(c,2))
            
        // Convert distance to meters and centimeters
        let meters = Int(distance)
        let centimeters = Int((Double(distance) - Double(meters)) * 100.0)
            
        // Format the text
        let distanceText: String
        if meters > 0 {
            if centimeters > 0 {
                distanceText = "\(meters) m \(centimeters) cm"
            } else {
                distanceText = "\(meters) m"
            }
        } else {
            distanceText = "\(centimeters) cm"
        }
            
        updateText(text: distanceText, atPosition: finish.position)
    }
    
    func updateText(text: String, atPosition position: SCNVector3) {
        textNode.removeFromParentNode()
        
        // Create a text geometry with increased extrusion depth and font
        let textGeometry = SCNText(string: text, extrusionDepth: 2.0) // Increased depth for smoothness
        
        // Create a material with enhanced properties for shadows
        let textMaterial = SCNMaterial()
        textMaterial.diffuse.contents = UIColor.green
        textMaterial.specular.contents = UIColor.white
        textMaterial.shininess = 1.0
        textMaterial.lightingModel = .phong
        textMaterial.isDoubleSided = true
        
        // Apply the material to the text geometry
        textGeometry.firstMaterial = textMaterial
        
        // Create the node and apply position and scale
        textNode = SCNNode(geometry: textGeometry)
        textNode.position = SCNVector3(position.x, position.y + 0.1, position.z)
        textNode.scale = SCNVector3(0.01, 0.01, 0.01)
        textNode.castsShadow = true
        
        let billboardConstraint = SCNBillboardConstraint()
            billboardConstraint.freeAxes = SCNBillboardAxis.Y
            textNode.constraints = [billboardConstraint]
        
        sceneView.scene.rootNode.addChildNode(textNode)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.textNode.constraints = [] // Remove constraints
            }

    
    }

}
