//
//  HSDLProxyManager.swift
//  HelloSDL
//
//  Created by Ford Developer on 11/3/15.
//  Copyright © 2015 Ford. All rights reserved.
//

import Foundation

// Notification strings used to show/hide lockscreen in the AppDelegate
let HSDLDisconnectNotification = "com.sdl.notification.sdldisconnect"
let HSDLLockScreenStatusNotification = "com.sdl.notification.sdlchangeLockScreenStatus"
let HSDLNotificationUserInfoObject = "com.sdl.notification.keys.sdlnotificationObject"


class HSDLProxyManager : NSObject, SDLProxyListener {
// TODO: Change these to match your app settings!!
    // TCP/IP (Emulator) configuration
    let RemoteIpAddress = "127.0.0.1"
    let RemotePort = "12345"
    
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
    let TestCommandID: UInt = 1

    // Proxy and state variables
    var proxy: SDLProxy?
    var correlationID: UInt = 1
    var appIconID: UInt?
    var remoteImages = Set<String>()
    var graphicsSuported = false
    var firstHmiFull = true
    var firstHmiNotNone = true
    var vehicleDataSubscribed = false

    
// MARK: Lifecycle
    
    // Singleton
    static let manager = HSDLProxyManager()
    
     /**
     Posts SDL notifications.
     
     - parameter name: The name of the SDL notification
     - parameter info: The data associated with the notification
     */
    func hsdl_postNotification(named name: String, info: AnyObject?) {
        var userInfo: Dictionary<String, AnyObject>?
        let notificationCenter = NotificationCenter.default

        if info != nil {
            userInfo = [HSDLNotificationUserInfoObject: info!]
        }
        notificationCenter.post(name: Notification.Name(rawValue: name), object: self, userInfo: userInfo)
    }


// MARK: Proxy Lifecycle
    
    /**
    Start listening for SDL connections.
    */
    func startProxy() {
        print("startProxy")
        
        // If connecting via USB (to a vehicle).
        self.proxy = SDLProxyFactory.buildSDLProxy(with: self)
        
        // If connecting via TCP/IP (to an emulator).
//        self.proxy = SDLProxyFactory.buildSDLProxy(with: self, tcpIPAddress: RemoteIpAddress, tcpPort: RemotePort)
    }
    
    /**
     Disconnect and destroy the current proxy.
     */
    func disposeProxy() {
        print("disposeProxy")
        self.proxy?.dispose()
        self.proxy = nil
    }
    
    /**
     Delegate method that runs on SDL connect.
     */
    @objc func onProxyOpened() {
        print("SDL Connect")
        
        // Build and send RegisterAppInterface request
        let raiRequest = SDLRPCRequestFactory.buildRegisterAppInterface(withAppName: self.AppName, languageDesired: SDLLanguage.en_US(), appID: self.AppId)
        raiRequest?.isMediaApplication = self.AppIsMediaApp as NSNumber!
        raiRequest?.ngnMediaScreenAppName = self.ShortAppName
        raiRequest?.vrSynonyms = [self.AppVrSynonym]
        raiRequest?.ttsName = [SDLTTSChunkFactory.buildTTSChunk(for: self.AppName, type: SDLSpeechCapabilities.text())]
        self.proxy?.sendRPC(raiRequest)
    }
    
    /**
     Delegate method that runs on disconnect from SDL.
     */
    @objc func onProxyClosed() {
        print("SDL Disconnect")
        
        // Reset state variables
        self.firstHmiFull = true
        self.firstHmiNotNone = true
        self.graphicsSuported = false
        self.remoteImages.removeAll()
        self.vehicleDataSubscribed = false
        self.appIconID = nil
        
        // Notify the app delegate to clear the lockscreen
        self.hsdl_postNotification(named: HSDLDisconnectNotification, info: nil)
        
        // Cycle the proxy
        self.disposeProxy()
        self.startProxy()
    }

    /**
     Delegate method that runs when the registration response is received from SDL.
     */
    @objc func onRegisterAppInterfaceResponse(_ response: SDLRegisterAppInterfaceResponse?) {
        print("RegisterAppInterface response from SDL: \(response?.resultCode) with info: \(response?.info)")
        
        if response?.success == 1 {
            // Check for graphics capability, and upload persistent graphics (app icon) if available
            if let displayCapabilities = response?.displayCapabilities {
                self.graphicsSuported = displayCapabilities.graphicSupported != nil ? displayCapabilities.graphicSupported!.boolValue : false
            }
            
            if self.graphicsSuported {
                self.hsdl_uploadImages()
            }
        } else {
            print("Failed to register with SDL: \(response)")
        }
    }
    
    /**
     Auto-increment and return the next correlation ID for an RPC.
     
     - returns: The next correlation ID.
     */
    func hsdl_getNextCorrelationId() -> UInt {
        self.correlationID += 1
        return self.correlationID
    }
    

// MARK: HMI

    /**
    Delegate method that runs when the app's HMI state on SDL changes.
    */
    @objc func on(_ notification: SDLOnHMIStatus?) {
        print("HMIStatus notification from SDL")
        
        // Send welcome message on first HMI FULL
        if notification?.hmiLevel == SDLHMILevel.full() {
            if self.firstHmiFull {
                self.firstHmiFull = false
                self.hsdl_performWelcomeMessage()
            }
            
            // Other HMI (Show, PerformInteraction, etc.) would go here
        }
        
        // Send AddCommands in first non-HMI NONE state (i.e., FULL, LIMITED, BACKGROUND)
        if notification?.hmiLevel != SDLHMILevel.none() {
            if self.firstHmiNotNone {
                self.firstHmiNotNone = false
                self.hsdl_addCommands()
                
                // Other app setup (SubMenu, CreateChoiceSet, etc.) would go here
                // NOTE: Keep the number of RPCs small, as there is a limit in HMI_NONE!
            }
        }
    }

    /**
     Send welcome message (Speak and Show).
     */
    func hsdl_performWelcomeMessage() {
        print("Send welcome message")
        let show = SDLShow()
        show?.mainField1 = WelcomeShow
        show?.alignment = SDLTextAlignment.centered()
        show?.correlationID = self.hsdl_getNextCorrelationId() as NSNumber!
        self.proxy?.sendRPC(show)
        
        let speak = SDLRPCRequestFactory.buildSpeak(withTTS: WelcomeSpeak, correlationID: self.hsdl_getNextCorrelationId() as NSNumber!)
        self.proxy?.sendRPC(speak)
    }
    
    /**
     Delegate method that runs when driver distraction mode changes.
     */
    @objc func on(_ notification: SDLOnDriverDistraction?) {
        print("OnDriverDistraction notification from SDL")
        
        // Some RPCs (depending on region) cannot be sent when driver distraction is active.
    }
    

// MARK: AppIcon

    /**
    Requests list of images to SDL, and uploads images that are missing.
    Called automatically by the onRegisterAppInterfaceResponse method.
    Note: Don't need to check for graphics support here; it is checked by the caller.
    */
    func hsdl_uploadImages() {
        print("hsdl_uploadImages")
        self.remoteImages.removeAll()
        
        // Perform a ListFiles RPC to check which files are already present on SDL
        let list = SDLListFiles()
        list?.correlationID = self.hsdl_getNextCorrelationId() as NSNumber!
        self.proxy?.sendRPC(list)
    }
    
    /**
     Delegate method that runs when the list files response is received from SDL.
     */
    @objc func onListFilesResponse(_ response: SDLListFilesResponse?) {
        print("ListFiles response from SDL: \(response?.resultCode) with info: \(response?.info)")

        // If the ListFiles was successful, store the list in a mutable set
        if response?.success == true {
            if let filenames = response?.filenames {
                if let filenameArray = NSArray(array:filenames) as? [String] {
                    for filename in filenameArray {
                        self.remoteImages.insert(filename)
                    }
                }
            }
        }
        
        // Check the mutable set for the AppIcon
        // If not present, upload the image
        if !self.remoteImages.contains(IconFile) {
            self.appIconID = self.hsdl_getNextCorrelationId()
            self.hsdl_uploadImage(IconFile, corrId: self.appIconID!)
        } else {
            // If the file is already present, send the SetAppIcon request
            self.hsdl_setAppIcon()
        }
        
        // Other images (for Show, etc.) could be added here
    }
    
    /**
     Upload a persistent PNG image to SDL.
     The correlation ID can be used in the onPutFileResponse delegate method to determine when the upload is complete.
     
     - parameter imageName: The name of the image in the Assets catalog.
     - parameter corrId:    The correlation ID used in the request.
     */
    func hsdl_uploadImage(_ imageName: String, corrId : UInt) {
        print("hsdl_uploadImage: \(imageName)")
        let pngImage = UIImage(named: imageName)
        if pngImage != nil {
            let pngData = UIImagePNGRepresentation(pngImage!)
            if pngData != nil,
                let putFile = SDLPutFile() {
                putFile.syncFileName = imageName
                putFile.fileType = SDLFileType.graphic_PNG()
                putFile.persistentFile = false
                putFile.systemFile = false
                putFile.offset = 0
                putFile.length = pngData!.count as NSNumber!
                putFile.bulkData = pngData
                putFile.correlationID = corrId as NSNumber!
                self.proxy?.sendRPC(putFile)
            }
        }
        
    }
    
    /**
     Delegate method that runs when a PutFile is complete.
     */
    @objc func onPutFileResponse(_ response: SDLPutFileResponse?) {
        print("PutFile response from SDL: \(response?.resultCode) with info: \(response?.info)")
        if response?.success == true && response?.correlationID.uintValue == self.appIconID {
            self.hsdl_setAppIcon()
        }
    }

    /**
     Send the SetAppIcon request to SDL.
     Called automatically in the OnPutFileResponse method.
     */
    func hsdl_setAppIcon() {
        print("hsdl_setAppIcon")
        let setIcon = SDLSetAppIcon()
        setIcon?.syncFileName = IconFile
        setIcon?.correlationID = self.hsdl_getNextCorrelationId() as NSNumber!
        self.proxy?.sendRPC(setIcon)
    }
    

// MARK: Lockscreen
    
    /**
    Delegate method that runs when lockscreen status changes.
    */
    @objc func on(onLockScreenNotification notification: SDLOnLockScreenStatus?) {
        print("OnLockScreen notification from SDL")
        
        // Notify the app delegate
        self.hsdl_postNotification(named: HSDLLockScreenStatusNotification, info: notification)
    }


// MARK: Commands

    /**
    Add commands for the app on SDL.
    */
    func hsdl_addCommands() {
        print("hsdl_addCommands")
        let menuParams = SDLMenuParams()
        menuParams?.menuName = TestCommandName
        let command = SDLAddCommand()
        command?.vrCommands = [TestCommandName]
        command?.menuParams = menuParams
        command?.cmdID = TestCommandID as NSNumber!
        self.proxy?.sendRPC(command)
    }
    
    /**
     Delegate method that runs when the add command response is received from SDL.
     */
    @objc func onAddCommandResponse(_ response: SDLAddCommandResponse?) {
        print("AddCommand response from SDL: \(response?.resultCode) with info: \(response?.info)")
    }

    /**
     Delegate method that runs when a command is triggered on SDL.
     */
    @objc func on(_ notification: SDLOnCommand?) {
        print("OnCommand notification from SDL")

        // Handle sample command when triggered
        if notification?.cmdID.uintValue == TestCommandID {
            let show = SDLShow()
            show?.mainField1 = "Test Command"
            show?.alignment = SDLTextAlignment.centered()
            show?.correlationID = self.hsdl_getNextCorrelationId() as NSNumber!
            self.proxy?.sendRPC(show)
            
            let speak = SDLRPCRequestFactory.buildSpeak(withTTS: "Test Command", correlationID: self.hsdl_getNextCorrelationId() as NSNumber!)
            self.proxy?.sendRPC(speak)
        }
    }


// MARK: VehicleData
    
// TODO: Uncomment the methods below for vehicle data

    /**
    Delegate method that runs when the app's permissions change on SDL.
    */
    @objc func on(_ notification: SDLOnPermissionsChange?) {
        print("OnPermissionsChange notification from SDL")

        // Check for permission to subscribe to vehicle data before sending the request
        if let permissions = notification?.permissionItem {
            if let permissionArray = NSArray(array:permissions) as? [SDLPermissionItem] {
                for item in permissionArray {
                    if let hmiPermissions = item.hmiPermissions, hmiPermissions.allowed.count > 0, item.rpcName == "SubscribeVehicleData" {
                        self.hsdl_subscribeVehicleData()
                    }
                }
            }
        }
    }
    
    /**
     Subscribe to (periodic) vehicle data updates from SDL.
     */
    func hsdl_subscribeVehicleData() {
        print("hsdl_subscribeVehicleData")
        if !self.vehicleDataSubscribed {
            let subscribe = SDLSubscribeVehicleData()
            subscribe?.correlationID = self.hsdl_getNextCorrelationId() as NSNumber!
            
// TODO: Add the vehicle data items you want to subscribe to
            // Specify which items to subscribe to
            subscribe?.speed = true
            
            self.proxy?.sendRPC(subscribe)
        }
    }
    
    /**
     Delegate method that runs when the subscribe vehicle data response is received from SDL.
     */
    @objc func onSubscribeVehicleDataResponse(_ response: SDLSubscribeVehicleDataResponse?) {
        print("SubscribeVehicleData response from SDL: \(response?.resultCode) with info: \(response?.info)")
        if response?.resultCode == SDLResult.success() {
            print("Vehicle data subscribed!")
            self.vehicleDataSubscribed = true
        }
    }

    /**
     Delegate method that runs when new vehicle data is received from SDL.
     */
    @objc func on(_ notification: SDLOnVehicleData?) {
        print("OnVehicleData notification from SDL")

// TODO: Put your vehicle data code here!
        print("Speed: \(notification?.speed)")
    }


// MARK: Notification callbacks
    
    @objc func on(_ notification: SDLOnAppInterfaceUnregistered?) {
        print("onAppInterfaceUnregistered notification from SDL: \(notification)")
    }
    
    @objc func on(_ notification: SDLOnAudioPassThru?) {
        print("onAudioPassThru notification from SDL: \(notification)")
    }
    
    @objc func on(_ notification: SDLOnButtonEvent?) {
        print("onButtonEvent notification from SDL: \(notification)")
    }
    
    @objc func on(_ notification: SDLOnButtonPress?) {
        print("onButtonPress notification from SDL: \(notification)")
    }
    
    @objc func on(_ notification: SDLOnEncodedSyncPData?) {
        print("onEncodedSyncPData notification from SDL: \(notification)")
    }
    
    @objc func on(_ notification: SDLOnHashChange?) {
        print("onHashChange notification from SDL: \(notification)")
    }
    
    @objc func on(_ notification: SDLOnLanguageChange?) {
        print("onLanguageChange notification from SDL: \(notification)")
    }
    
    @objc func on(_ notification: SDLOnSyncPData?) {
        print("onSyncPData notification from SDL: \(notification)")
    }
    
    @objc func on(_ notification: SDLOnSystemRequest?) {
        print("onSystemRequest notification from SDL: \(notification)")
    }
    
    @objc func on(_ notification: SDLOnTBTClientState?) {
        print("onTBTClientState notification from SDL: \(notification)")
    }
    
    @objc func on(_ notification: SDLOnTouchEvent?) {
        print("onTouchEvent notification from SDL: \(notification)")
    }
    
    @objc func onReceivedLockScreenIcon(_ icon: UIImage?) {
        print("ReceivedLockScreenIcon notification from SDL")
    }
    
    
// MARK: Other callbacks
    
    @objc func onAddSubMenuResponse(_ response: SDLAddSubMenuResponse?) {
        print("AddSubMenuResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onAlertManeuverResponse(_ request: SDLAlertManeuverResponse?) {
        print("AlertManeuverResponse response from SDL with result code: \(request?.resultCode) and info: \(request?.info)")
    }
    
    @objc func onAlertResponse(_ response: SDLAlertResponse?) {
        print("AlertResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onChangeRegistrationResponse(_ response: SDLChangeRegistrationResponse?) {
        print("ChangeRegistrationResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onCreateInteractionChoiceSetResponse(_ response: SDLCreateInteractionChoiceSetResponse?) {
        print("CreateInteractionChoiceSetResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onDeleteCommandResponse(_ response: SDLDeleteCommandResponse?) {
        print("DeleteCommandResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onDeleteFileResponse(_ response: SDLDeleteFileResponse?) {
        print("DeleteFileResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onDeleteInteractionChoiceSetResponse(_ response: SDLDeleteInteractionChoiceSetResponse?) {
        print("DeleteInteractionChoiceSetResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onDeleteSubMenuResponse(_ response: SDLDeleteSubMenuResponse?) {
        print("DeleteSubMenuResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onDiagnosticMessageResponse(_ response: SDLDiagnosticMessageResponse?) {
        print("DiagnosticMessageResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onDialNumberResponse(_ request: SDLDialNumberResponse?) {
        print("DialNumberResponse response from SDL with result code: \(request?.resultCode) and info: \(request?.info)")
    }
    
    @objc func onEncodedSyncPDataResponse(_ response: SDLEncodedSyncPDataResponse?) {
        print("EncodedSyncPDataResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onEndAudioPassThruResponse(_ response: SDLEndAudioPassThruResponse?) {
        print("EndAudioPassThruResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onError(_ e: NSException?) {
        print("Error response from SDL with error: \(e)")
    }
    
    @objc func onGenericResponse(_ response: SDLGenericResponse?) {
        print("GenericResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onGetDTCsResponse(_ response: SDLGetDTCsResponse?) {
        print("GetDTCsResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onGetVehicleDataResponse(_ response: SDLGetVehicleDataResponse?) {
        print("GetVehicleDataResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onPerformAudioPassThruResponse(_ response: SDLPerformAudioPassThruResponse?) {
        print("PerformAudioPassThruResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onPerformInteractionResponse(_ response: SDLPerformInteractionResponse?) {
        print("PerformInteractionResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onReadDIDResponse(_ response: SDLReadDIDResponse?) {
        print("ReadDIDResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onResetGlobalPropertiesResponse(_ response: SDLResetGlobalPropertiesResponse?) {
        print("ResetGlobalPropertiesResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onScrollableMessageResponse(_ response: SDLScrollableMessageResponse?) {
        print("ScrollableMessageResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onSendLocationResponse(_ request: SDLSendLocationResponse?) {
        print("SendLocationResponse response from SDL with result code: \(request?.resultCode) and info: \(request?.info)")
    }
    
    @objc func onSetAppIconResponse(_ response: SDLSetAppIconResponse?) {
        print("SetAppIconResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onSetDisplayLayoutResponse(_ response: SDLSetDisplayLayoutResponse?) {
        print("SetDisplayLayoutResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onSetGlobalPropertiesResponse(_ response: SDLSetGlobalPropertiesResponse?) {
        print("SetGlobalPropertiesResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onSetMediaClockTimerResponse(_ response: SDLSetMediaClockTimerResponse?) {
        print("SetMediaClockTimerResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onShowConstantTBTResponse(_ response: SDLShowConstantTBTResponse?) {
        print("ShowConstantTBTResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onShowResponse(_ response: SDLShowResponse?) {
        print("ShowResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onSliderResponse(_ response: SDLSliderResponse?) {
        print("SliderResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onSpeakResponse(_ response: SDLSpeakResponse?) {
        print("SpeakResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onSubscribeButtonResponse(_ response: SDLSubscribeButtonResponse?) {
        print("SubscribeButtonResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onSyncPDataResponse(_ response: SDLSyncPDataResponse?) {
        print("SyncPDataResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onUpdateTurnListResponse(_ response: SDLUpdateTurnListResponse?) {
        print("UpdateTurnListResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onUnregisterAppInterfaceResponse(_ response: SDLUnregisterAppInterfaceResponse?) {
        print("UnregisterAppInterfaceResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onUnsubscribeButtonResponse(_ response: SDLUnsubscribeButtonResponse?) {
        print("UnsubscribeButtonResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onUnsubscribeVehicleDataResponse(_ response: SDLUnsubscribeVehicleDataResponse?) {
        print("UnsubscribeVehicleDataResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
}
