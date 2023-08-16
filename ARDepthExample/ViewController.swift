//
//  ViewController.swift
//  ARDepthExample
//
//  Created by jun.ogino on 2023/06/12.
//

import UIKit
import SceneKit
import ARKit
import Foundation

class ViewController: UIViewController {

    var session: ARSession!
    var sessionIsPaused = true
    @IBOutlet var sceneView: ARSCNView!

    var displayLink: CADisplayLink?
    var timerStarted = false {
        didSet {
            timerStartButton.isHidden = timerStarted
        }
    }
    /// sessionを停止させるタイミングのtoggle
    /// true: stop→distance検出
    /// false: distance検出→stop
    var detectDistanceMode = false
    var isShowTimer = true {
        didSet {
            timerLabel.isHidden = !isShowTimer
        }
    }

    var startTime: TimeInterval = 0
    var elapsedTime: TimeInterval = 0

    var timerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .boldSystemFont(ofSize: 80)
        label.textColor = .orange
        label.text = "00:00.00"
        return label
    }()

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
        label.font = .boldSystemFont(ofSize: 20)
        label.textColor = .red
        return label
    }()

    var timerStartButton: UIButton = {
        let button = UIButton()
        let image = UIImage(systemName: "timer", withConfiguration: UIImage.SymbolConfiguration(textStyle: .largeTitle))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(image, for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 50
        return button
    }()

    var resumeButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Session\nStart", for: .normal)
        button.titleLabel?.numberOfLines = 0
        button.setTitleColor(.systemBlue, for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 20
        return button
    }()

    var stopModeToggleButton: UISwitch = {
        let uiswitch = UISwitch()
        uiswitch.translatesAutoresizingMaskIntoConstraints = false
        return uiswitch
    }()

    var showTimerToggleButton: UISwitch = {
        let uiswitch = UISwitch()
        uiswitch.translatesAutoresizingMaskIntoConstraints = false
        uiswitch.isOn = true
        return uiswitch
    }()

    func resumeButtonTapped() {
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        flag = false
        if type(of: configuration).supportsFrameSemantics(.sceneDepth) {
            configuration.frameSemantics = .sceneDepth
        }
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        sessionIsPaused = false
    }

    func timerStartButtonTapped() {
        timerLabel.text = "00:00.00"
        guard !timerStarted, !sessionIsPaused else { return }
        timerStarted = true
        // 0秒になったらタイマーを開始する
        displayLink = CADisplayLink(target: self, selector: #selector(checkForNextZeroSecond))
        displayLink?.add(to: .main, forMode: .default)
    }

    @objc func checkForNextZeroSecond() {
        let currentSeconds = Calendar.current.component(.second, from: Date())
        guard currentSeconds == 0 else { return }
        displayLink?.invalidate()
        startTimer()
    }

    func startTimer() {
        startTime = CACurrentMediaTime()

        displayLink = CADisplayLink(target: self, selector: #selector(updateElapsedTime))
        displayLink?.add(to: .main, forMode: .default)
    }

    @objc func updateElapsedTime() {
        let currentTime = CACurrentMediaTime()
        elapsedTime = currentTime - startTime

        let minutes = Int(elapsedTime / 60)
        let seconds = Int(elapsedTime) % 60
        let fraction = Int((elapsedTime - Double(Int(elapsedTime))) * 100)

        timerLabel.text = String(format: "%02d:%02d.%02d", minutes, seconds, fraction)
    }

    /// session.runしてから距離を検出するまでのraycast.result=nilで停止しないためのフラグ
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
        sceneView.addSubview(resumeButton)
        sceneView.addSubview(timerStartButton)
        sceneView.addSubview(timerLabel)
        sceneView.addSubview(stopModeToggleButton)
        sceneView.addSubview(showTimerToggleButton)
        resumeButton.addAction(.init { [weak self] _ in
            guard let self else { return }
            self.resumeButtonTapped()
        }, for: .touchUpInside)
        timerStartButton.addAction(.init { [weak self] _ in
            guard let self else { return }
            self.timerStartButtonTapped()
        }, for: .touchUpInside)
        stopModeToggleButton.addAction(.init { [weak self] _ in
            guard let self else { return }
            self.detectDistanceMode.toggle()
        }, for: .touchUpInside)
        showTimerToggleButton.addAction(.init { [weak self] _ in
            guard let self else { return }
            self.isShowTimer.toggle()
        }, for: .touchUpInside)

        NSLayoutConstraint.activate([
            label.leftAnchor.constraint(equalTo: sceneView.leftAnchor, constant: 20),
            label.bottomAnchor.constraint(equalTo: sceneView.bottomAnchor, constant: -50),
            line.centerXAnchor.constraint(equalTo: sceneView.centerXAnchor),
            line.centerYAnchor.constraint(equalTo: sceneView.centerYAnchor),
            line.heightAnchor.constraint(equalTo: sceneView.heightAnchor),
            resumeButton.bottomAnchor.constraint(equalTo: sceneView.bottomAnchor, constant: -50),
            resumeButton.rightAnchor.constraint(equalTo: sceneView.rightAnchor, constant: -20),
            resumeButton.heightAnchor.constraint(equalToConstant: 100),
            resumeButton.widthAnchor.constraint(equalToConstant: 100),
            timerStartButton.bottomAnchor.constraint(equalTo: resumeButton.topAnchor, constant: -20),
            timerStartButton.rightAnchor.constraint(equalTo: resumeButton.rightAnchor),
            timerStartButton.heightAnchor.constraint(equalToConstant: 100),
            timerStartButton.widthAnchor.constraint(equalToConstant: 100),
            timerLabel.topAnchor.constraint(equalTo: sceneView.topAnchor, constant: 20),
            timerLabel.leftAnchor.constraint(equalTo: sceneView.leftAnchor, constant: 20),
            stopModeToggleButton.rightAnchor.constraint(equalTo: resumeButton.rightAnchor),
            stopModeToggleButton.bottomAnchor.constraint(equalTo: timerStartButton.topAnchor, constant: -20),
            showTimerToggleButton.rightAnchor.constraint(equalTo: resumeButton.rightAnchor),
            showTimerToggleButton.bottomAnchor.constraint(equalTo: stopModeToggleButton.topAnchor, constant: -20)
        ])
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session.pause()
    }
}

extension ViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let centerPoint = CGPoint(x: sceneView.frame.midX, y: sceneView.frame.midY)
        if detectDistanceMode {
            // stop→distance検出時にsession.pause()
            guard let raycast = sceneView.raycastQuery(from: centerPoint, allowing: .estimatedPlane, alignment: .any),
                  let result = sceneView.session.raycast(raycast).first else {
                return
            }

            session.pause()
            label.text = "Distance: \(String(format: "%.3f", calculateDistance(raycastResult: result, frame: frame))) m"
            displayLink?.invalidate()
            timerStarted = false
        } else {
            // distance検出中→stop時にsession.pause()
            guard let raycast = sceneView.raycastQuery(from: centerPoint, allowing: .estimatedPlane, alignment: .any),
                  let result = sceneView.session.raycast(raycast).first else {
                if (flag) {
                    session.pause()
                }
                label.text = "Stop"
                displayLink?.invalidate()
                timerStarted = false
                return
            }
            if !flag { flag = true }
            label.text = "Distance: \(String(format: "%.3f", calculateDistance(raycastResult: result, frame: frame))) m"
        }
    }

    func calculateDistance(raycastResult: ARRaycastResult, frame: ARFrame) -> Float {
        let position = SCNVector3(
            raycastResult.worldTransform.columns.3.x,
            raycastResult.worldTransform.columns.3.y,
            raycastResult.worldTransform.columns.3.z
        )

        let transform = frame.camera.transform.columns.3
        let cameraCoordinates = SCNVector3(x: transform.x, y: transform.y, z: transform.z)

        let distance = cameraCoordinates.distance(to: position)
        return distance
    }
}

extension ViewController: ARSCNViewDelegate {
    // MARK: - ARSCNViewDelegate
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        sessionIsPaused = true
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        sessionIsPaused = false
    }
}

extension SCNVector3 {
     func distance(to vector: SCNVector3) -> Float {
         return simd_distance(simd_float3(self), simd_float3(vector))
     }
 }
