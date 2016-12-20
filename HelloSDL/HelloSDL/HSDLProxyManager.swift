//
//  HSDLProxyManager.swift
//  HelloSDL
//
//  Created by Ford Developer on 11/3/15.
//  Copyright © 2015 Ford. All rights reserved.
//

import Foundation
import SmartDeviceLink_iOS

class HSDLProxyManager : NSObject {
// TODO: Change these to match your app settings!!
    // TCP/IP (Emulator) configuration

    //19.32.136.90:2776
    let RemoteIpAddress = "127.0.0.1"
    let RemotePort: UInt16 = 12345
    
    // App configuration
    let AppName = "HelloSDL"
    let AppId = "8675309"
    let AppIsMediaApp = false
    let ShortAppName = "Hello"
    let AppVrSynonym = "Hello S D L"
    let IconFile = "sdl_icon.png"
    
    // Welcome message
    let WelcomeShow = "Welcome to HelloSDL"
    let WelcomeSpeak = "Welcome to Hello S D L"
    
    // Sample AddCommand
    let TestCommandName = "Test Command"
    let TestCommandID: UInt32 = 1

    // Manager and state variables
    var manager = SDLManager()
    var lifecycleConfiguration: SDLLifecycleConfiguration?

    var isGraphicsSupported = false
    var firstHmiNotNone = true
    var isVehicleDataSubscribed = false

    
// MARK: Lifecycle
    
    // Singleton
    static let manager = HSDLProxyManager()
    
    override init() {
        super.init()
        // SDLLifecycleConfiguration contains all information to connecting to core, including Register App Interface information.
        
        // If connecting via USB (to a vehicle).
        lifecycleConfiguration = SDLLifecycleConfiguration.defaultConfiguration(withAppName: AppName, appId: AppId)
        
        // If connecting via TCP/IP (to an emulator).
//        lifecycleConfiguration = SDLLifecycleConfiguration.debugConfiguration(withAppName: AppName, appId: AppId, ipAddress: RemoteIpAddress, port: RemotePort)
        
        lifecycleConfiguration!.appType = AppIsMediaApp ? .media() : .default()
        lifecycleConfiguration!.shortAppName = ShortAppName
        lifecycleConfiguration!.voiceRecognitionCommandNames = [AppVrSynonym]
        lifecycleConfiguration!.ttsName = [SDLTTSChunk(text: AppName, type: .text())]
        
        if let iconImage = UIImage(named: IconFile) {
            lifecycleConfiguration!.appIcon = SDLArtwork(image: iconImage, name: IconFile, as: .PNG)
        }
        
        // SDLConfiguration contains the lifecycle and lockscreen configurations
        let configuration = SDLConfiguration(lifecycle: lifecycleConfiguration!, lockScreen: .enabled())
        
        manager = SDLManager(configuration: configuration, delegate: self)
        
        self.addRPCObservers()
    }

// MARK: Proxy Lifecycle
    
    /**
    Start listening for SDL connections.
    */
    public func start() {
        print("starting proxy manager")
        manager.start { (success, error) in
            if let error = error, success == false {
                print("There was an error! \(error.localizedDescription)")
                return
            }
            
            print("Successfully connected!")
            self.addPermissionManagerObservers()
        }
    }
    
    /**
     Disconnect and destroy the current proxy.
     */
    public func stop() {
        print("stopping proxy manager")
        manager.stop()
    }
}

//MARK: SDLManagerDelegate
extension HSDLProxyManager: SDLManagerDelegate {
    
    /**
     Delegate method that runs when the app's HMI state on SDL changes.
     */
    func hmiLevel(_ oldLevel: SDLHMILevel, didChangeTo newLevel: SDLHMILevel) {
        print("HMIStatus notification from SDL")
        
        // Send AddCommands in first non-HMI NONE state (i.e., FULL, LIMITED, BACKGROUND)
        if newLevel != .none() && firstHmiNotNone == true {
            firstHmiNotNone = false
            addCommands()
            
            // Other app setup (SubMenu, CreateChoiceSet, etc.) would go here
            // NOTE: Keep the number of RPCs small, as there is a limit in HMI_NONE!
        }
        
        // Send welcome message on first HMI FULL
        if newLevel == .full() {
            if oldLevel == .none() {
                performWelcomeMessage()
                return
            }

            // Other HMI (Show, PerformInteraction, etc.) would go here
        }
    }
    
    /**
     Delegate method that runs on disconnect from SDL. You do not need to handle recycling the proxy.
     */
    func managerDidDisconnect() {
        print("Manager did disconnect")
        firstHmiNotNone = true
        isVehicleDataSubscribed = false
    }
}

//MARK: Observers
fileprivate extension HSDLProxyManager {
    fileprivate func addRPCObservers() {
        // Adding Response Observers
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveRegisterAppInterfaceResponse(_:)), name: SDLDidReceiveRegisterAppInterfaceResponse, object: nil)
        
        // Adding Notification Observers
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveVehicleData(_:)), name: .SDLDidReceiveVehicleData, object: nil)
    }
    
    fileprivate func addPermissionManagerObservers() {
        // Adding Permission Manager Observers
        // Since we do not want to remove the observer, we will not store the UUID it returns
        _ = self.manager.permissionManager.addObserver(forRPCs: ["SubscribeVehicleData"], groupType: .allAllowed) { (rpcStatus, groupStatus) in
            
            if groupStatus != .allowed {
                return
            }
            
            if self.isVehicleDataSubscribed == false {
                self.subscribeVehicleData()
            }
        }
    }
    
    @objc fileprivate func didReceiveVehicleData(_ notification: SDLRPCNotificationNotification) {
        guard let onVehicleData = notification.notification as? SDLOnVehicleData else {
            return
        }
        
        print("OnVehicleData notification from SDL")
        
        // TODO: Put your vehicle data code here!
        print("Speed: \(onVehicleData.speed)")
    }
    
    @objc fileprivate func didReceiveRegisterAppInterfaceResponse(_ notification : SDLRPCResponseNotification) {
        guard let response = notification.response as? SDLRegisterAppInterfaceResponse else {
            return
        }
        
        isGraphicsSupported = response.displayCapabilities.graphicSupported.boolValue
        
        if isGraphicsSupported {
            // Send images via SDLFileManager
        }
        
    }
}

//MARK: Subscribers & HMI Setup
fileprivate extension HSDLProxyManager {
    //MARK: Vehicle Data
    
    /**
     Subscribe to (periodic) vehicle data updates from SDL.
     */
    fileprivate func subscribeVehicleData() {
        print("subscribeVehicleData")
        if self.isVehicleDataSubscribed {
            return
        }
        let subscribe = SDLSubscribeVehicleData()!
        
        // TODO: Add the vehicle data items you want to subscribe to
        // Specify which items to subscribe to
        subscribe.speed = true
        
        self.manager.send(subscribe) { (request, response, error) in
            print("SubscribeVehicleData response from SDL: \(response?.resultCode) with info: \(response?.info)")
            if response?.resultCode == SDLResult.success() {
                print("Vehicle data subscribed!")
                self.isVehicleDataSubscribed = true
            }
        }
    }
    
    // MARK: HMI
    
    /**
     Send welcome message (Speak and Show).
     */
    fileprivate func performWelcomeMessage() {
        print("Send welcome message")
        let show = SDLShow(mainField1: WelcomeShow, mainField2: nil, alignment: .centered())!
        manager.send(show)
        
        let speak = SDLSpeak(tts: WelcomeSpeak)!
        manager.send(speak)
    }
    
    
    // MARK: Commands
    
    /**
     Add commands for the app on SDL.
     */
    fileprivate func addCommands() {
        print("Add Commands")
        let command = SDLAddCommand(id: TestCommandID, vrCommands: [TestCommandName], menuName: TestCommandName) { (notification) in
            guard let onCommand = notification as? SDLOnCommand else {
                return
            }
            
            if onCommand.cmdID.uint32Value == self.TestCommandID {
                let show = SDLShow(mainField1: "Test Command", mainField2: nil, alignment: .centered())!
                self.manager.send(show)
                
                let speak = SDLSpeak(tts: "Test Command")!
                self.manager.send(speak)
            }
            }!
        
        manager.send(command) { (request, response, error) in
            print("AddCommand response from SDL: \(response?.resultCode) with info: \(response?.info)")
        }
    }
}
