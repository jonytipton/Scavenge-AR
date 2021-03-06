//
//  ScavengeViewController.swift
//  Scavenge[AR]
//
//  Created by Jonathan Tipton on 3/23/22.
//  Copyright © 2022 Microsoft. All rights reserved.

class ScavengeViewController: BaseViewController {

    @IBOutlet var sensorStatusView: SensorStatusView!

    @IBOutlet var descriptionTextView: UITextView!
    
    @IBOutlet var dismissButton: UIButton!
    
    @IBAction func onDismissTapped(_ sender: Any) {
        print("DISMISS TAPPED")
        if (descriptionTextList.isEmpty == true) {
            print("No more items in description list. Hidding view.")
            dismissButton.isHidden = true
            descriptionTextView.isHidden = true
        }
        else {
            print("Displaying next item in description list!")
            descriptionTextView.text = descriptionTextList.removeFirst()
        }
        
    }
    /// Whether the "Access WiFi Information" capability is enabled.
    /// If available, the MAC address of the connected Wi-Fi access point can be used
    /// to help find nearby anchors.
    /// Note: This entitlement requires a paid Apple Developer account.
    private static let haveAccessWifiInformationEntitlement = false

    /// Whitelist of Bluetooth-LE beacons used to find anchors and improve the locatability
    /// of existing anchors.
    /// Add the UUIDs for your own Bluetooth beacons here to use them with Azure Spatial Anchors.
    public static let knownBluetoothProximityUuids = [
        "61687109-905f-4436-91f8-e602f514c96d",
        "e1f54e02-1e23-44e0-9c3d-512eb56adec9",
        "01234567-8901-2345-6789-012345678903",
    ]

    var locationProvider: ASAPlatformLocationProvider?

    var nearDeviceWatcher: ASACloudSpatialAnchorWatcher?
    var numAnchorsFound = 0 //Use for found score
    
    var resumedCloudSession :ASACloudSpatialAnchorSession? = nil

    var descriptionTextList: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        //This call handles collision detection
        sceneView.scene.physicsWorld.contactDelegate = self
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        print("contact happened")
    }
    
/*
    override func onCloudAnchorCreated() {
        ignoreMainButtonTaps = false
        step = .lookForNearbyAnchors

        DispatchQueue.main.async {
            self.feedbackControl.isHidden = true
            self.mainButton.setTitle("Tap to start next Session & look for anchors near device", for: .normal)
        }
    }*/

    /*
     Going to assume anchors are spaced a few meters apart
     User likely stopping when reading description then dismissing before reaching next anchor
     */
    override func onNewAnchorLocated(_ cloudAnchor: ASACloudSpatialAnchor) {
        ignoreMainButtonTaps = true
        
        //resumedCloudSession = super.cloudSession
        //super.pauseSession()
        
        //step = .stopWatcher //Activates on main button tap
        
        if let anchorText: String = cloudAnchor.appProperties["anchor-name"] as? String
        {
            print("Appending: \(cloudAnchor.appProperties["anchor-name"] ?? "ERROR: NO VALUE FOR APP PROPERTY 'anchor-name'")")
            //Add anchor description to list
            descriptionTextList.append(anchorText)
            
            if (descriptionTextView.isHidden == true) {
                descriptionTextView.text = descriptionTextList.removeFirst()
            }
        }
        else {
            descriptionTextView.text = "ERROR: No value for anchor-name property!"
        }
        
        //Display view
        descriptionTextView.isHidden = false
        dismissButton.isHidden = false
        
        DispatchQueue.main.async {
            self.numAnchorsFound += 1
            self.feedbackControl.isHidden = true
            self.mainButton.setTitle("\(self.numAnchorsFound) Pausing session. Found Anchor", for: .normal)
        }
    }
    
    

    override func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        super.renderer(renderer, updateAtTime: time)
        
        DispatchQueue.main.async {
            self.sensorStatusView.update()
        }
    }

    @objc override func mainButtonTap(sender: UIButton) {
        if (ignoreMainButtonTaps) {
            return
        }

        switch (step) {
        case .prepare:
            mainButton.setTitle("Tap to start Session", for: .normal)
            step = .lookForNearbyAnchors
            createLocationProvider()
        case .lookForNearbyAnchors:
            ignoreMainButtonTaps = true
            stopSession()
            startSession()
            attachLocationProviderToSession()

            // We will get a call to onLocateAnchorsCompleted which will move to the next step when the locate operation completes.
            lookForAnchorsNearDevice()
        case .stopWatcher:
            step = .stopSession
            nearDeviceWatcher?.stop()
            nearDeviceWatcher = nil
            mainButton.setTitle("Tap to stop Session and return to the main menu", for: .normal)
        case .stopSession:
            stopSession()
            self.locationProvider = nil
            self.sensorStatusView.setModel(nil)
            moveToMainMenu()
        default:
            assertionFailure("Demo has somehow entered an invalid state")
        }
    }

    private func createLocationProvider() {
        locationProvider = ASAPlatformLocationProvider()

        // Register known Bluetooth beacons
        locationProvider!.sensors!.knownBeaconProximityUuids =
            ScavengeViewController.knownBluetoothProximityUuids

        // Display the sensor status
        let sensorStatus = LocationProviderSensorStatus(for: locationProvider)
        sensorStatusView.setModel(sensorStatus)

        enableAllowedSensors()
    }

    private func enableAllowedSensors() {
        if let sensors = locationProvider?.sensors {
            sensors.bluetoothEnabled = true
            sensors.wifiEnabled = ScavengeViewController.haveAccessWifiInformationEntitlement
            sensors.geoLocationEnabled = true
        }
    }

    private func attachLocationProviderToSession() {
        cloudSession!.locationProvider = locationProvider
    }
    
    private func resumeSession() {
        print("RESUME SESSION")
        lookForAnchorsNearDevice()
    }

    private func lookForAnchorsNearDevice() {
        let nearDevice = ASANearDeviceCriteria()!
        nearDevice.distanceInMeters = 1
        nearDevice.maxResultCount = 35

        let criteria = ASAAnchorLocateCriteria()!
        criteria.nearDevice = nearDevice
        nearDeviceWatcher = cloudSession!.createWatcher(criteria)

        mainButton.setTitle("Looking for anchors near device...", for: .normal)
    }
}


