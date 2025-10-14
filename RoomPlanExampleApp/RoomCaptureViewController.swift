/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
The sample app's main view controller that manages the scanning process.
*/

import UIKit
import RoomPlan
import SceneKit
import ZIPFoundation
import SwiftUI

let SPESSORE: CGFloat = 20.0
let DIMENSIONE_CROCETTA: CGFloat = 60.0

class RoomCaptureViewController: UIViewController, RoomCaptureViewDelegate, RoomCaptureSessionDelegate {
    
    private var doneButton: UIBarButtonItem!
    private var cancelButton: UIBarButtonItem!
    private var activityIndicator: UIActivityIndicatorView!
    
    private var isScanning: Bool = false
    private var roomCaptureView: RoomCaptureView!
    private var roomCaptureSessionConfig: RoomCaptureSession.Configuration = RoomCaptureSession.Configuration()
    private var finalResults: CapturedRoom?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupRoomCaptureView()
        activityIndicator.stopAnimating()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelScanning))
        doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneScanning))
        
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = doneButton
        
        activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupRoomCaptureView() {
        roomCaptureView = RoomCaptureView(frame: view.bounds)
        roomCaptureView.captureSession.delegate = self
        roomCaptureView.delegate = self
        
        view.insertSubview(roomCaptureView, at: 0)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startSession()
    }
    
    override func viewWillDisappear(_ flag: Bool) {
        super.viewWillDisappear(flag)
        stopSession()
    }
    
    private func startSession() {
        isScanning = true
        roomCaptureView?.captureSession.run(configuration: roomCaptureSessionConfig)
        setActiveNavBar()
    }
    
    private func stopSession() {
        isScanning = false
        roomCaptureView?.captureSession.stop()
    }
    
    func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: Error?) -> Bool {
        return true
    }
    
    func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
        finalResults = processedResult
        self.activityIndicator?.stopAnimating()
        
        if !isScanning {
            updateUIAfterScanComplete()
        }
    }
    
    @objc func doneScanning() {
        if isScanning {
            stopSession()
            activityIndicator?.startAnimating()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.activityIndicator?.stopAnimating()
                self.updateUIAfterScanComplete()
            }
        } else {
            showObjectSelection()
        }
    }

    @objc func cancelScanning() {
        dismiss(animated: true)
    }
    
    private func updateUIAfterScanComplete() {
        doneButton?.title = "Continue"
        
        UIView.animate(withDuration: 0.5) {
            self.cancelButton?.tintColor = .systemBlue
            self.doneButton?.tintColor = .systemGreen
        }
    }
    
    private func showObjectSelection() {
        guard let results = finalResults else {
            let alert = UIAlertController(
                title: "Error",
                message: "No scan data available",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        let selectionView = ObjectSelectionView(capturedRoom: results)
        let hostingController = UIHostingController(rootView: selectionView)
        hostingController.modalPresentationStyle = .fullScreen
        present(hostingController, animated: true)
    }
    
    private func setActiveNavBar() {
        UIView.animate(withDuration: 1.0) {
            self.cancelButton?.tintColor = .white
            self.doneButton?.tintColor = .white
        }
    }
}
