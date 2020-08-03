/****VisionKitSample.swift ****/

import Foundation
import Vision
import VisionKit

fileprivate struct Constants {
    static let INVALIDINPUTERROR = "Invalid input. Please check whether valid input is passed to the plugin"
    static let TEXTNOTAVAILABLERROR = "Text doesn't have a suitable match in the scanned page"
    static let SCANNINGFAILEDERROR = "Scanning failed"
    static let CANCELLEDERROR = "Scanning is cancelled"
    static let SCANNERNOTAVAILABLE = "Scanner is not available"
    static let PROCESSFAILURE = "Text processing failed"
    static let LINESIDENTIFIED_KEY = "linesIdentified"
    static let INPROGRESSERROR = "Previous text processing is in progress"
}

//@objc is added to expose the class to Objective C classes
@objc(VisionKitSample) public class VisionKitSample: CDVPlugin {
    private var callbackId: String?
    private var searchText: String?
    
    /**
    Function that wil be called from JS to retreive the lines of a given text by scanning a page.
    
    All the text validations are performed in the JS side and only valid input is passed to this function.
    
    `Callback`
    - callbackId is saved for responding back to JS from delegate methods.
    - Text processing is performed asynchronously.
    - When a processing is in progress and if this method gets invoked again with new callbackId,
    error indicating an existing process will be sent back to JS .
    
    `Camera view`
    - Once searchText is extracted, VNDocumentCameraViewController is presented for scanning a page.
    - User permissions are automatically handled in the VNDocumentCameraViewController and its delegate
    methods are called based on user actions.
    
    - Parameter command: Input from JS with callbacks and arguments.
    */
    @objc(scanAndRetreiveLines:)
    public func scanAndRetreiveLines(command: CDVInvokedUrlCommand) {
        if let _ = callbackId{
            self.sendFailureMessage(message: Constants.INPROGRESSERROR, callbackId: command.callbackId)
            return
        }else{
            self.callbackId = command.callbackId
        }
        
        //VisionKit is available only from iOS 13, error message is returned if this is executed in a lower version
        if #available(iOS 13.0, *) {
            if let inputText = command.argument(at: 0) as? String{
                self.searchText = inputText
                let scanVC = VNDocumentCameraViewController()
                scanVC.delegate = self
                self.viewController.present(scanVC, animated: true)
            }else{
                self.sendFailureMessage(message: Constants.INVALIDINPUTERROR, callbackId: command.callbackId)
            }
        }else{
            self.sendFailureMessage(message: Constants.SCANNERNOTAVAILABLE, callbackId: command.callbackId)
        }
    }
    
    ///Process the scanned image.
    ///- Parameter image: scanned image to be processed.
    @available(iOS 13.0, *)
    private func processScannedImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)
        let request = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)
        do {
            //Process the text recognize request and pass the result to the completion handler
            try requestHandler.perform([request])
        } catch {
            if let callbackId = self.callbackId {
                sendFailureMessage(message: Constants.PROCESSFAILURE, callbackId: callbackId)
            }
        }
    }
    
    ///Retreive the lines from the observations result of the scanned page processing.
    ///- Parameter request: processed request that contains the result from which observations can be extracted.
    ///- Parameter error: error occured during the image processing.
    @available(iOS 13.0, *)
    private func recognizeTextHandler(request: VNRequest, error: Error?) {
        guard let callbackId = self.callbackId else { return }
        
        guard let searchText = self.searchText else {
            sendFailureMessage(message: Constants.INVALIDINPUTERROR, callbackId: callbackId)
            return
        }
        
        guard let observations =
            request.results as? [VNRecognizedTextObservation] else {
                sendFailureMessage(message: Constants.TEXTNOTAVAILABLERROR, callbackId: callbackId)
                return
        }
        
        var recognizedStrings = observations.compactMap { observation in
            //Return the string of the top VNRecognizedText instance.
            return observation.topCandidates(1).first?.string
        }
        
        recognizedStrings = recognizedStrings.filter{$0.lowercased().contains(searchText.lowercased())}
        if recognizedStrings.count == 0 {
            sendFailureMessage(message: Constants.TEXTNOTAVAILABLERROR, callbackId: callbackId)
        }else{
            self.sendSuccessMessage(withLines: recognizedStrings, callbackId: callbackId)
        }
    }
    
    ///Send error responses back to JS and clear self.callbackId to accept new callback.
    ///- Parameter message: message to be passed as response.
    ///- Parameter callbackId:callbackId to which plugin result should be sent.
    private func sendFailureMessage(message: String, callbackId: String) {
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: message)
        pluginResult?.setKeepCallbackAs(false)
        self.commandDelegate.send(pluginResult, callbackId: callbackId)
        if callbackId == self.callbackId{
            self.callbackId = nil
        }
    }
    
    ///Send success response back to JS along with the recognized lines of the text passed as input to the plugin and clear self.callbackId to accept new callback.
    ///- Parameter lines: Lines that contain the text.
    ///- Parameter callbackId: callbackId to which plugin result should be sent.
    private func sendSuccessMessage(withLines lines: [String], callbackId: String) {
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: [Constants.LINESIDENTIFIED_KEY: lines])
        pluginResult?.setKeepCallbackAs(false)
        self.commandDelegate.send(pluginResult, callbackId: callbackId)
        if callbackId == self.callbackId{
            self.callbackId = nil
        }
    }
    
    ///Send response with no message, to keep the callback active
    ///- Parameter callbackId: callbackId to which plugin result should be sent.
    private func sendNoResponseMessage(callbackId: String) {
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_NO_RESULT)
        pluginResult?.setKeepCallbackAs(true)
        self.commandDelegate.send(pluginResult, callbackId: callbackId)
    }
}

@available(iOS 13.0, *)
extension VisionKitSample: VNDocumentCameraViewControllerDelegate {
    
    //Function gets called when user clicks Save after successfully scanning the page.
    public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        //If the scanned page count is zero, error response will be sent back to JS.
        guard scan.pageCount >= 1 else {
            if let callbackId = self.callbackId {
                sendFailureMessage(message: Constants.SCANNINGFAILEDERROR, callbackId: callbackId)
            }
            controller.dismiss(animated: true)
            return
        }
        
        guard let callbackId = self.callbackId else { return }
        
        self.sendNoResponseMessage(callbackId: callbackId)
        self.commandDelegate.run {[weak self] in
            guard let self = self else { return }
            
            //If there are more than 1 page scanned, only the first page is used for processing.
            self.processScannedImage(scan.imageOfPage(at: 0))
        }
        
        controller.dismiss(animated: true)
    }
    
    //Function gets called when any failure happens while scanning or when user clicks Cancel after denying the camera permission.
    //Error response will be sent back to JS.
    public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        if let callbackId = self.callbackId {
            sendFailureMessage(message: Constants.SCANNINGFAILEDERROR, callbackId: callbackId)
        }
        controller.dismiss(animated: true)
    }
    
    //Function gets called when user clicks Cancel, error response will be sent back to JS.
    public func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        if let callbackId = self.callbackId {
            sendFailureMessage(message: Constants.CANCELLEDERROR, callbackId: callbackId)
        }
        controller.dismiss(animated: true)
    }
}
