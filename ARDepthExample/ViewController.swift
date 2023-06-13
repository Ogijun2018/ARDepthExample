//
//  ViewController.swift
//  ARDepthExample
//
//  Created by jun.ogino on 2023/06/12.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    var session: ARSession!
    @IBOutlet var sceneView: ARSCNView!
    var line: UIView = {
        let line = UIView()
        line.translatesAutoresizingMaskIntoConstraints = false
        line.widthAnchor.constraint(equalToConstant: 2).isActive = true
        line.backgroundColor = .yellow
        return line
    }()

    var label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .boldSystemFont(ofSize: 40)
        label.textColor = .green
        return label
    }()
    // 初回起動が完了した場合true
    var flag = false

    override func viewDidLoad() {
        super.viewDidLoad()

        session = ARSession()
        session.delegate = self

        // Set the view's delegate
        sceneView.delegate = self

        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        sceneView.session = session

        sceneView.addSubview(label)
        sceneView.addSubview(line)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: sceneView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: sceneView.centerYAnchor),
            line.centerXAnchor.constraint(equalTo: sceneView.centerXAnchor),
            line.centerYAnchor.constraint(equalTo: sceneView.centerYAnchor),
            line.heightAnchor.constraint(equalTo: sceneView.heightAnchor)
        ])
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let hoge = CGPoint(x: sceneView.frame.midX, y: sceneView.frame.midY)
        guard let raycast = sceneView.raycastQuery(from: hoge, allowing: .estimatedPlane, alignment: .any),
              let result = sceneView.session.raycast(raycast).first else {
            if (flag) {
                session.pause()
            }
            label.text = "Stop!"
            label.textColor = .red
            return
        }
        if !flag { flag = true }
        label.textColor = .purple

        let position = SCNVector3(result.worldTransform.columns.3.x, result.worldTransform.columns.3.y, result.worldTransform.columns.3.z)

        let transform = frame.camera.transform.columns.3
        let cameraCoordinates = SCNVector3(x: transform.x, y: transform.y, z: transform.z)

        let distance = cameraCoordinates.distance(to: position)
        label.text = "Distance: \(String(format: "%.3f", distance)) m"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // sceneDepth(LiDAR)が利用可能かチェック
        if type(of: configuration).supportsFrameSemantics(.sceneDepth) {
            configuration.frameSemantics = .sceneDepth
        }

        print("fps:", configuration.videoFormat.framesPerSecond)
        // Run the view's session
        session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        session.pause()
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
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

extension SCNVector3 {
     func distance(to vector: SCNVector3) -> Float {
         return simd_distance(simd_float3(self), simd_float3(vector))
     }
 }
