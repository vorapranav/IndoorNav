//
//  ObjectDetectionController.swift
//  INDNAV
//
//  Created by Pranav on 07/04/2023.
//  Copyright © 2023 Pranav vora. All rights reserved.
//

import Foundation

import UIKit
import SceneKit
import ARKit

class ObjectDetectionController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet weak var objsceneView: ARSCNView!

    @IBAction func backAction(){
        dismiss(animated: true)
    }
    
        override func viewDidLoad() {
            super.viewDidLoad()
            
            // Set the view's delegate
            objsceneView.delegate = self
            
            // Show statistics such as fps and timing information
            objsceneView.showsStatistics = true
            
            // Create a new scene
            let scene = SCNScene(named: "art.scnassets/GameScene.scn")!
            
            // Set the scene to the view
            objsceneView.scene = scene
        }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            
            // Create a session configuration
            let configuration = ARWorldTrackingConfiguration()
            
            // Object Detection
            configuration.detectionObjects = ARReferenceObject.referenceObjects(inGroupNamed: "ARObjects", bundle: Bundle.main)!

            // Run the view's session
            objsceneView.session.run(configuration)
        }
        
        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            
            // Pause the view's session
            objsceneView.session.pause()
        }

        // MARK: - ARSCNViewDelegate
        
        func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
            
            print("rendered")
            
            let node = SCNNode()
            
            if let objectAnchor = anchor as? ARObjectAnchor {
                print ("entered")
                print(objectAnchor)
                print(ARReferenceObject.self)
                let plane = SCNPlane(width: CGFloat(objectAnchor.referenceObject.extent.x * 1.5), height: CGFloat(objectAnchor.referenceObject.extent.y * 0.7))
                
                plane.cornerRadius = plane.width / 8
                
                print(anchor.name ?? "default")
                var spriteKitScene = SKScene(fileNamed: "defaultscene")
                if anchor.name == "controller-w"{
                    spriteKitScene = SKScene(fileNamed: "controller")
                }
                else if anchor.name == "salt"{
                    spriteKitScene = SKScene(fileNamed: "defaultscene")
                }
                else if anchor.name == "buddha"{
                    spriteKitScene = SKScene(fileNamed: "LaughingBuddha")
                }
                else if anchor.name == "Teddy"{
                    spriteKitScene = SKScene(fileNamed: "Teddy")
                }
                else{
                    spriteKitScene = SKScene(fileNamed: "defaultscene")
                }
                plane.firstMaterial?.diffuse.contents = spriteKitScene
                plane.firstMaterial?.isDoubleSided = true
                plane.firstMaterial?.diffuse.contentsTransform = SCNMatrix4Translate(SCNMatrix4MakeScale(1, -1, 1), 0, 1, 0)
                
                let planeNode = SCNNode(geometry: plane)
                planeNode.position = SCNVector3Make(objectAnchor.referenceObject.center.x, objectAnchor.referenceObject.center.y + 0.1, objectAnchor.referenceObject.center.z)
                
                node.addChildNode(planeNode)
                
            }
            
            return node
        }
        
        
        func session(_ session: ARSession, didFailWithError error: Error) {
            // Present an error message to the user
            
        }
        
        func sessionWasInterrupted(_ session: ARSession) {
            // Inform the user that the session has been interrupted, for example, by presenting an overlay
            
        }
        
        func sessionInterruptionEnded(_ session: ARSession) {
            // Reset tracking and/or remove existing anchors if consistent tracking is required
            
        }
    }
