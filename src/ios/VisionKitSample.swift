/****VisionKitSample.swift ****/

import Foundation
import Vision
import VisionKit

let INVALIDINPUTERROR = "Invalid input. Please check whether valid input is passed to the plugin"
let TEXTNOTAVAILABLERROR = "Text doesn't have a suitable match in the scanned page"
let SCANNINGFAILEDERROR = "Scanning failed"
let CANCELLEDERROR = "Scanning is cancelled"
let SCANNERNOTAVAILABLE = "Scanner is not available"
let PROCESSFAILURE = "Text processing failed"
let LINESIDENTIFIED_KEY = "linesIdentified"

///@objc is added to expose the class to Objective C classes
@objc(VisionKitSample) class VisionKitSample: CDVPlugin {
    
    var callbackId: String?
    var searchText: String?
    
    ///@objc is added to expose the function  to Objective C classes
    ///Function that will be called from JS to scan a page and identify the lines that contain the text that was passed as input
    @objc(scanAndRetreiveLines:)
    func scanAndRetreiveLines(command: CDVInvokedUrlCommand) {
        
        ///callbackId is saved for sending the responses  back to JS from other functions using the same callbackId
        self.callbackId = command.callbackId
        
        ///VisionKit is available only from iOS 13, error message is returned if this is executed in a lower version
        if #available(iOS 13.0, *) {
            ///Convert the passed parameter to String representation.
            ///If the String conversion succeeds, VNDocumentCameraViewController() will be presented
            ///enabling the user to scan a page by providing camera permission
            ///If the string conversion is nil or string contains only white spaces or new line characters, then error message is returned
            
            self.commandDelegate.run {[weak self] in
                let inputReceived = String(describing: command.argument(at: 0) ?? "")
                if (inputReceived.isEmpty || (inputReceived.trimmingCharacters(in: .whitespacesAndNewlines) == "")) {
                    self?.sendFailureMessage(message: INVALIDINPUTERROR)
                    return
                }
                self?.searchText = inputReceived
                DispatchQueue.main.async {
                    let scanVC = VNDocumentCameraViewController()
                    scanVC.delegate = self
                    self?.viewController.present(scanVC, animated: true)
                }
            }
        }else{
            self.sendFailureMessage(message: SCANNERNOTAVAILABLE)
        }
    }
    
    @available(iOS 13.0, *)
    ///Function to initialize the processing of the scanned image
    ///@param image to be processed
    func processScannedImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)
        let request = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)
        do {
            ///Process the text recognize request and pass the result to the completion handler
            try requestHandler.perform([request])
        } catch {
            sendFailureMessage(message: PROCESSFAILURE)
        }
    }
    
    @available(iOS 13.0, *)
    ///Function to recognize the strings from the observation result and returns back the lines which contain the text passed from JS
    func recognizeTextHandler(request: VNRequest, error: Error?) {
        guard let observations =
            request.results as? [VNRecognizedTextObservation] else {
                return
        }
        
        var recognizedStrings = observations.compactMap { observation in
            ///Return the string of the top VNRecognizedText instance.
            return observation.topCandidates(1).first?.string
        }
        
        recognizedStrings = recognizedStrings.filter{$0.lowercased().contains(self.searchText!.lowercased())}
        if recognizedStrings.count == 0 {
            sendFailureMessage(message: TEXTNOTAVAILABLERROR)
        }else{
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: [LINESIDENTIFIED_KEY: recognizedStrings])
            self.commandDelegate!.send(pluginResult, callbackId: self.callbackId!);
        }
    }
    
    ///Function to sent error responses
    ///@param message to be sent as plugin response
    func sendFailureMessage(message: String) {
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: message)
        self.commandDelegate!.send(pluginResult, callbackId: self.callbackId!);
    }
}

@available(iOS 13.0, *)
extension VisionKitSample: VNDocumentCameraViewControllerDelegate {
    
    ///Function gets called when user clicks Save after successfully scanning the pages
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        ///If the scanned page count is zero, error response will be sent back to JS
        guard scan.pageCount >= 1 else {
            sendFailureMessage(message: SCANNINGFAILEDERROR)
            controller.dismiss(animated: true)
            return
        }
        
        ///This plugin will be processing the text in a single page scanned by the user,
        ///if there are more than 1 page scanned, only the first page will be used for processing.
        ///Processing of the image is executed in background, so that the screen is not hanged during the processing of the scanned page
        self.commandDelegate.run {[weak self] in
            self?.processScannedImage(scan.imageOfPage(at: 0))
        }
        
        controller.dismiss(animated: true)
    }
    
    ///Function gets called  when any failure happens while scanning or when user clicks Cancel after denying the camera permission
    ///Error response will be sent back to JS
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        sendFailureMessage(message: SCANNINGFAILEDERROR)
        controller.dismiss(animated: true)
    }
    
    ///Function gets called when user clicks Cancel, error response will be sent back to JS
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        sendFailureMessage(message: CANCELLEDERROR)
        controller.dismiss(animated: true)
    }
}
