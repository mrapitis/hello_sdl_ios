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
    func hsdl_postNotification(name: String, info: AnyObject?) {
        var userInfo: Dictionary<String, AnyObject>?
        let notificationCenter = NSNotificationCenter.defaultCenter()

        if info != nil {
            userInfo = [HSDLNotificationUserInfoObject: info!]
        }
        notificationCenter.postNotificationName(name, object: self, userInfo: userInfo)
    }


// MARK: Proxy Lifecycle
    
    /**
    Start listening for SDL connections.
    */
    func startProxy() {
        print("startProxy")
        self.proxy = SDLProxyFactory.buildSDLProxyWithListener(self)
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
        let raiRequest = SDLRPCRequestFactory.buildRegisterAppInterfaceWithAppName(self.AppName, languageDesired: SDLLanguage.EN_US(), appID: self.AppId)
        raiRequest.isMediaApplication = self.AppIsMediaApp
        raiRequest.ngnMediaScreenAppName = self.ShortAppName
        raiRequest.vrSynonyms = [self.AppVrSynonym]
        raiRequest.ttsName = [SDLTTSChunkFactory.buildTTSChunkForString(self.AppName, type: SDLSpeechCapabilities.TEXT())]
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
        self.hsdl_postNotification(HSDLDisconnectNotification, info: nil)
        
        // Cycle the proxy
        self.disposeProxy()
        self.startProxy()
    }

    /**
     Delegate method that runs when the registration response is received from SDL.
     */
    @objc func onRegisterAppInterfaceResponse(response: SDLRegisterAppInterfaceResponse?) {
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
        return ++self.correlationID
    }
    

// MARK: HMI

    /**
    Delegate method that runs when the app's HMI state on SDL changes.
    */
    @objc func onOnHMIStatus(notification: SDLOnHMIStatus?) {
        print("HMIStatus notification from SDL")
        
        // Send welcome message on first HMI FULL
        if notification?.hmiLevel == SDLHMILevel.FULL() {
            if self.firstHmiFull {
                self.firstHmiFull = false
                self.hsdl_performWelcomeMessage()
            }
            
            // Other HMI (Show, PerformInteraction, etc.) would go here
        }
        
        // Send AddCommands in first non-HMI NONE state (i.e., FULL, LIMITED, BACKGROUND)
        if notification?.hmiLevel != SDLHMILevel.NONE() {
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
        show.mainField1 = WelcomeShow
        show.alignment = SDLTextAlignment.CENTERED()
        show.correlationID = self.hsdl_getNextCorrelationId()
        self.proxy?.sendRPC(show)
        
        let speak = SDLRPCRequestFactory.buildSpeakWithTTS(WelcomeSpeak, correlationID: self.hsdl_getNextCorrelationId())
        self.proxy?.sendRPC(speak)
    }
    
    /**
     Delegate method that runs when driver distraction mode changes.
     */
    @objc func onOnDriverDistraction(notification: SDLOnDriverDistraction?) {
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
        list.correlationID = self.hsdl_getNextCorrelationId()
        self.proxy?.sendRPC(list)
    }
    
    /**
     Delegate method that runs when the list files response is received from SDL.
     */
    @objc func onListFilesResponse(response: SDLListFilesResponse?) {
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
    func hsdl_uploadImage(imageName: String, corrId : UInt) {
        print("hsdl_uploadImage: \(imageName)")
        let pngImage = UIImage(named: imageName)
        if pngImage != nil {
            let pngData = UIImagePNGRepresentation(pngImage!)
            if pngData != nil {
                let putFile = SDLPutFile()
                putFile.syncFileName = imageName
                putFile.fileType = SDLFileType.GRAPHIC_PNG()
                putFile.persistentFile = false
                putFile.systemFile = false
                putFile.offset = 0
                putFile.length = pngData!.length
                putFile.bulkData = pngData
                putFile.correlationID = corrId
                self.proxy?.sendRPC(putFile)
            }
        }
        
    }
    
    /**
     Delegate method that runs when a PutFile is complete.
     */
    @objc func onPutFileResponse(response: SDLPutFileResponse?) {
        print("PutFile response from SDL: \(response?.resultCode) with info: \(response?.info)")
        if response?.success == true && response?.correlationID == self.appIconID {
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
        setIcon.syncFileName = IconFile
        setIcon.correlationID = self.hsdl_getNextCorrelationId()
        self.proxy?.sendRPC(setIcon)
    }
    

// MARK: Lockscreen
    
    /**
    Delegate method that runs when lockscreen status changes.
    */
    @objc func onOnLockScreenNotification(notification: SDLLockScreenStatus?) {
        print("OnLockScreen notification from SDL")
        
        // Notify the app delegate
        self.hsdl_postNotification(HSDLLockScreenStatusNotification, info: notification)
    }


// MARK: Commands

    /**
    Add commands for the app on SDL.
    */
    func hsdl_addCommands() {
        print("hsdl_addCommands")
        let menuParams = SDLMenuParams()
        menuParams.menuName = TestCommandName
        let command = SDLAddCommand()
        command.vrCommands = [TestCommandName]
        command.menuParams = menuParams
        command.cmdID = TestCommandID
        self.proxy?.sendRPC(command)
    }
    
    /**
     Delegate method that runs when the add command response is received from SDL.
     */
    @objc func onAddCommandResponse(response: SDLAddCommandResponse?) {
        print("AddCommand response from SDL: \(response?.resultCode) with info: \(response?.info)")
    }

    /**
     Delegate method that runs when a command is triggered on SDL.
     */
    @objc func onOnCommand(notification: SDLOnCommand?) {
        print("OnCommand notification from SDL")

        // Handle sample command when triggered
        if notification?.cmdID == TestCommandID {
            let show = SDLShow()
            show.mainField1 = "Test Command"
            show.alignment = SDLTextAlignment.CENTERED()
            show.correlationID = self.hsdl_getNextCorrelationId()
            self.proxy?.sendRPC(show)
            
            let speak = SDLRPCRequestFactory.buildSpeakWithTTS("Test Command", correlationID: self.hsdl_getNextCorrelationId())
            self.proxy?.sendRPC(speak)
        }
    }


// MARK: VehicleData
    
// TODO: Uncomment the methods below for vehicle data

    /**
    Delegate method that runs when the app's permissions change on SDL.
    */
    @objc func onOnPermissionsChange(notification: SDLOnPermissionsChange?) {
        print("OnPermissionsChange notification from SDL")

        // Check for permission to subscribe to vehicle data before sending the request
        if let permissions = notification?.permissionItem {
            if let permissionArray = NSArray(array:permissions) as? [SDLPermissionItem] {
                for item in permissionArray {
                    if item.rpcName == "SubscribeVehicleData" && item.hmiPermissions?.allowed.count > 0 {
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
            subscribe.correlationID = self.hsdl_getNextCorrelationId()
            
// TODO: Add the vehicle data items you want to subscribe to
            // Specify which items to subscribe to
            subscribe.speed = true
            
            self.proxy?.sendRPC(subscribe)
        }
    }
    
    /**
     Delegate method that runs when the subscribe vehicle data response is received from SDL.
     */
    @objc func onSubscribeVehicleDataResponse(response: SDLSubscribeVehicleDataResponse?) {
        print("SubscribeVehicleData response from SDL: \(response?.resultCode) with info: \(response?.info)")
        if response?.resultCode == SDLResult.SUCCESS() {
            print("Vehicle data subscribed!")
            self.vehicleDataSubscribed = true
        }
    }

    /**
     Delegate method that runs when new vehicle data is received from SDL.
     */
    @objc func onOnVehicleData(notification: SDLOnVehicleData?) {
        print("OnVehicleData notification from SDL")

// TODO: Put your vehicle data code here!
        print("Speed: \(notification?.speed)")
    }


// MARK: Notification callbacks
    
    @objc func onOnAppInterfaceUnregistered(notification: SDLOnAppInterfaceUnregistered?) {
        print("onAppInterfaceUnregistered notification from SDL: \(notification)")
    }
    
    @objc func onOnAudioPassThru(notification: SDLOnAudioPassThru?) {
        print("onAudioPassThru notification from SDL: \(notification)")
    }
    
    @objc func onOnButtonEvent(notification: SDLOnButtonEvent?) {
        print("onButtonEvent notification from SDL: \(notification)")
    }
    
    @objc func onOnButtonPress(notification: SDLOnButtonPress?) {
        print("onButtonPress notification from SDL: \(notification)")
    }
    
    @objc func onOnEncodedSyncPData(notification: SDLOnEncodedSyncPData?) {
        print("onEncodedSyncPData notification from SDL: \(notification)")
    }
    
    @objc func onOnHashChange(notification: SDLOnHashChange?) {
        print("onHashChange notification from SDL: \(notification)")
    }
    
    @objc func onOnLanguageChange(notification: SDLOnLanguageChange?) {
        print("onLanguageChange notification from SDL: \(notification)")
    }
    
    @objc func onOnSyncPData(notification: SDLOnSyncPData?) {
        print("onSyncPData notification from SDL: \(notification)")
    }
    
    @objc func onOnSystemRequest(notification: SDLOnSystemRequest?) {
        print("onSystemRequest notification from SDL: \(notification)")
    }
    
    @objc func onOnTBTClientState(notification: SDLOnTBTClientState?) {
        print("onTBTClientState notification from SDL: \(notification)")
    }
    
    @objc func onOnTouchEvent(notification: SDLOnTouchEvent?) {
        print("onTouchEvent notification from SDL: \(notification)")
    }
    
    @objc func onReceivedLockScreenIcon(icon: UIImage?) {
        print("ReceivedLockScreenIcon notification from SDL")
    }
    
    
// MARK: Other callbacks
    
    @objc func onAddSubMenuResponse(response: SDLAddSubMenuResponse?) {
        print("AddSubMenuResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onAlertManeuverResponse(request: SDLAlertManeuverResponse?) {
        print("AlertManeuverResponse response from SDL with result code: \(request?.resultCode) and info: \(request?.info)")
    }
    
    @objc func onAlertResponse(response: SDLAlertResponse?) {
        print("AlertResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onChangeRegistrationResponse(response: SDLChangeRegistrationResponse?) {
        print("ChangeRegistrationResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onCreateInteractionChoiceSetResponse(response: SDLCreateInteractionChoiceSetResponse?) {
        print("CreateInteractionChoiceSetResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onDeleteCommandResponse(response: SDLDeleteCommandResponse?) {
        print("DeleteCommandResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onDeleteFileResponse(response: SDLDeleteFileResponse?) {
        print("DeleteFileResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onDeleteInteractionChoiceSetResponse(response: SDLDeleteInteractionChoiceSetResponse?) {
        print("DeleteInteractionChoiceSetResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onDeleteSubMenuResponse(response: SDLDeleteSubMenuResponse?) {
        print("DeleteSubMenuResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onDiagnosticMessageResponse(response: SDLDiagnosticMessageResponse?) {
        print("DiagnosticMessageResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onDialNumberResponse(request: SDLDialNumberResponse?) {
        print("DialNumberResponse response from SDL with result code: \(request?.resultCode) and info: \(request?.info)")
    }
    
    @objc func onEncodedSyncPDataResponse(response: SDLEncodedSyncPDataResponse?) {
        print("EncodedSyncPDataResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onEndAudioPassThruResponse(response: SDLEndAudioPassThruResponse?) {
        print("EndAudioPassThruResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onError(e: NSException?) {
        print("Error response from SDL with error: \(e)")
    }
    
    @objc func onGenericResponse(response: SDLGenericResponse?) {
        print("GenericResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onGetDTCsResponse(response: SDLGetDTCsResponse?) {
        print("GetDTCsResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onGetVehicleDataResponse(response: SDLGetVehicleDataResponse?) {
        print("GetVehicleDataResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onPerformAudioPassThruResponse(response: SDLPerformAudioPassThruResponse?) {
        print("PerformAudioPassThruResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onPerformInteractionResponse(response: SDLPerformInteractionResponse?) {
        print("PerformInteractionResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onReadDIDResponse(response: SDLReadDIDResponse?) {
        print("ReadDIDResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onResetGlobalPropertiesResponse(response: SDLResetGlobalPropertiesResponse?) {
        print("ResetGlobalPropertiesResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onScrollableMessageResponse(response: SDLScrollableMessageResponse?) {
        print("ScrollableMessageResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onSendLocationResponse(request: SDLSendLocationResponse?) {
        print("SendLocationResponse response from SDL with result code: \(request?.resultCode) and info: \(request?.info)")
    }
    
    @objc func onSetAppIconResponse(response: SDLSetAppIconResponse?) {
        print("SetAppIconResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onSetDisplayLayoutResponse(response: SDLSetDisplayLayoutResponse?) {
        print("SetDisplayLayoutResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onSetGlobalPropertiesResponse(response: SDLSetGlobalPropertiesResponse?) {
        print("SetGlobalPropertiesResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onSetMediaClockTimerResponse(response: SDLSetMediaClockTimerResponse?) {
        print("SetMediaClockTimerResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onShowConstantTBTResponse(response: SDLShowConstantTBTResponse?) {
        print("ShowConstantTBTResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onShowResponse(response: SDLShowResponse?) {
        print("ShowResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onSliderResponse(response: SDLSliderResponse?) {
        print("SliderResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onSpeakResponse(response: SDLSpeakResponse?) {
        print("SpeakResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onSubscribeButtonResponse(response: SDLSubscribeButtonResponse?) {
        print("SubscribeButtonResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onSyncPDataResponse(response: SDLSyncPDataResponse?) {
        print("SyncPDataResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onUpdateTurnListResponse(response: SDLUpdateTurnListResponse?) {
        print("UpdateTurnListResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onUnregisterAppInterfaceResponse(response: SDLUnregisterAppInterfaceResponse?) {
        print("UnregisterAppInterfaceResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onUnsubscribeButtonResponse(response: SDLUnsubscribeButtonResponse?) {
        print("UnsubscribeButtonResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
    
    @objc func onUnsubscribeVehicleDataResponse(response: SDLUnsubscribeVehicleDataResponse?) {
        print("UnsubscribeVehicleDataResponse response from SDL with result code: \(response?.resultCode) and info: \(response?.info)")
    }
}
