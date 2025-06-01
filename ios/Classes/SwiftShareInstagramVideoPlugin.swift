import Flutter
import UIKit
import Photos

import PhotosUI


public class SwiftShareInstagramVideoPlugin:  UIViewController, FlutterPlugin,PHPickerViewControllerDelegate   {
    
    
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        
        let channel = FlutterMethodChannel(name: "instagram_share_plus", binaryMessenger: registrar.messenger())
        
        let instance = SwiftShareInstagramVideoPlugin()
        
        
        
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard call.method == "shareVideoToInstagram"
        else {
            result(FlutterMethodNotImplemented)
            return
            
        }
        if let args = call.arguments as? [String: Any], let path = args["path"] as? String, let type = args["type"] as? String {
            print("Path: \(path), Type: \(type)")
            
            PHPhotoLibrary.requestAuthorization { status in
                guard status == .authorized else {
                    print("Permission denied to access Photos Library.")
                    return result(String("Permission denied to access Photos Library"))
                }
                
                var localIdentifier: String?
                
                // Save the image to the Photos Library
                PHPhotoLibrary.shared().performChanges({
                    let assetRequest = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: URL(string: path)!)
                    localIdentifier = assetRequest?.placeholderForCreatedAsset?.localIdentifier
                }) { success, error in
                    if success {
                        print("Image saved successfully. Local Identifier: \(localIdentifier ?? "unknown")")
                        DispatchQueue.main.async {
                            let url = URL(string: "instagram://library?LocalIdentifier=\(localIdentifier ?? "unknown")")
                            guard UIApplication.shared.canOpenURL(url!) else {
                                return result(String("Instagram app not installed"))
                            }
                            UIApplication.shared.open(url!, options: [:]) { success in
                              if success {

                              } else {
                                    return result(String("Instagram app not installed"))
                              }
                            }
                        }
                    } else if let error = error {
                        print("Error saving image: \(error.localizedDescription)")
                        return result(String("Error saving image: \(error.localizedDescription)"))
                    }
                }
            }
        }
    }
    
    @IBAction private func shareVideoToInstagram(result: FlutterResult) {
        if #available(iOS 14, *) {
            self.presentPicker(self)
        } else {
            return result(String("error"))
        }
        return result(String("success"))
    }
    
    
    
    @available(iOS 14, *)
    @IBAction func presentPicker(_ sender: Any) {
        let photoLibrary = PHPhotoLibrary.shared()
        let configuration = PHPickerConfiguration(photoLibrary: photoLibrary)
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        UIApplication.shared.keyWindow?.rootViewController?.present(picker, animated: true)
    }
    
    @available(iOS 14, *)
    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        let identifiers = results.compactMap(\.assetIdentifier)
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
        
        if(fetchResult.firstObject == nil) {
            return
        }
        let localId = fetchResult.firstObject!.localIdentifier
        
        let url = URL(string: "instagram://library?LocalIdentifier=\(localId)")
        guard UIApplication.shared.canOpenURL(url!) else {
            return
        }
        UIApplication.shared.open(url!, options: [:], completionHandler: nil)
    }
    
}
