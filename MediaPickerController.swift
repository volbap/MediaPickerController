//
//  MediaPickerController.swift
//  MediaPickerController
//
//  Created by Pablo Villar on 3/9/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices

enum MediaPickerControllerType {
	case ImageOnly
	case ImageAndVideo
}

@objc protocol MediaPickerControllerDelegate {
	optional func mediaPickerControllerDidPickImage(image: UIImage)
	optional func mediaPickerControllerDidPickVideoWithURL(url: NSURL, imageData: NSData, thumbnail: UIImage)
}

class MediaPickerController: NSObject {
	
	// MARK: - Public
	
	weak var delegate: MediaPickerControllerDelegate?
	
	init (type: MediaPickerControllerType, presentingViewController controller: UIViewController) {
		self.type = type
		self.presentingController = controller
		self.mediaPicker = UIImagePickerController()
		super.init()
		self.mediaPicker.delegate = self
	}
	
	func show() {
		let actionSheet = self.optionsActionSheet
		self.presentingController.presentViewController(actionSheet, animated: true, completion: nil)
	}
	
	// MARK: - Private
	
	private let presentingController: UIViewController
	private let type: MediaPickerControllerType
	private let mediaPicker: UIImagePickerController
	
}

extension MediaPickerController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	
	// MARK: - UIImagePickerControllerDelegate
	
	func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
		self.dismiss()
		let mediaType = info[UIImagePickerControllerMediaType] as! NSString
		
		if mediaType.isEqualToString(kUTTypeImage as NSString as String) {
			// Is Image
			let chosenImage = info[UIImagePickerControllerOriginalImage] as! UIImage
			self.delegate?.mediaPickerControllerDidPickImage?(chosenImage)
		} else if mediaType.isEqualToString(kUTTypeMovie as NSString as String) {
			// Is Video
			let url: NSURL = info[UIImagePickerControllerMediaURL] as! NSURL
			let chosenImage = info[UIImagePickerControllerMediaURL] as! NSURL
			let imageData = try! NSData(contentsOfURL: chosenImage, options: [])
			let thumbnail = url.generateThumbnail()
			self.delegate?.mediaPickerControllerDidPickVideoWithURL?(url, imageData: imageData, thumbnail: thumbnail)
		}
		
	}
	
	func imagePickerControllerDidCancel(picker: UIImagePickerController) {
		self.dismiss()
	}
	
	// MARK: - UINavigationControllerDelegate
	
	func navigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool) {
		UIApplication.sharedApplication().statusBarStyle = .LightContent
	}
	
}

// MARK: - Private

private extension MediaPickerController {
	
	var optionsActionSheet: UIAlertController {
		let actionSheet = UIAlertController(title: Strings.Title, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
		self.addChooseExistingMediaActionToSheet(actionSheet)
		
		if UIImagePickerController.isSourceTypeAvailable(.Camera) {
			self.addTakePhotoActionToSheet(actionSheet)
			if self.type == .ImageAndVideo {
				self.addTakeVideoActionToSheet(actionSheet)
			}
		}
		self.addCancelActionToSheet(actionSheet)
		return actionSheet
	}
	
	func addChooseExistingMediaActionToSheet(actionSheet: UIAlertController) {
		let chooseExistingAction = UIAlertAction(title: self.chooseExistingText, style: UIAlertActionStyle.Default) { (_) -> Void in
			self.mediaPicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
			self.mediaPicker.mediaTypes = self.chooseExistingMediaTypes
			self.presentingController.presentViewController(self.mediaPicker, animated: true, completion: nil)
		}
		actionSheet.addAction(chooseExistingAction)
	}
	
	func addTakePhotoActionToSheet(actionSheet: UIAlertController) {
		let takePhotoAction = UIAlertAction(title: Strings.TakePhoto, style: UIAlertActionStyle.Default) { (_) -> Void in
			self.mediaPicker.sourceType = UIImagePickerControllerSourceType.Camera
			self.mediaPicker.mediaTypes = [kUTTypeImage as String]
			self.presentingController.presentViewController(self.mediaPicker, animated: true, completion: nil)
		}
		actionSheet.addAction(takePhotoAction)
	}
	
	func addTakeVideoActionToSheet(actionSheet: UIAlertController) {
		let takeVideoAction = UIAlertAction(title: Strings.TakeVideo, style: UIAlertActionStyle.Default) { (_) -> Void in
			self.mediaPicker.sourceType = UIImagePickerControllerSourceType.Camera
			self.mediaPicker.mediaTypes = [kUTTypeMovie as String]
			self.presentingController.presentViewController(self.mediaPicker, animated: true, completion: nil)
		}
		actionSheet.addAction(takeVideoAction)
	}
	
	func addCancelActionToSheet(actionSheet: UIAlertController) {
		let cancel = Strings.Cancel
		let cancelAction = UIAlertAction(title: cancel, style: UIAlertActionStyle.Cancel) { (_) -> Void in
		}
		actionSheet.addAction(cancelAction)
	}
	
	func dismiss() {
		dispatch_async(dispatch_get_main_queue()) {
			self.presentingController.dismissViewControllerAnimated(true, completion: nil)
		}
	}
	
	private var chooseExistingText: String {
		switch self.type {
		case .ImageOnly: return Strings.ChoosePhoto
		case .ImageAndVideo: return Strings.ChoosePhotoOrVideo
		}
	}
	
	private var chooseExistingMediaTypes: [String] {
		switch self.type {
		case .ImageOnly: return [kUTTypeImage as String]
		case .ImageAndVideo: return [kUTTypeImage as String, kUTTypeMovie as String]
		}
	}
	
	// MARK: - Constants
	
	struct Strings {
		static let Title = NSLocalizedString("Adjuntar", comment: "Title for a generic action sheet for picking media from the device.")
		static let ChoosePhoto = NSLocalizedString("Seleccionar de la galería", comment: "Text for an option that lets the user choose an existing photo in a generic action sheet for picking media from the device.")
		static let ChoosePhotoOrVideo = NSLocalizedString("Seleccionar de la galería", comment: "Text for an option that lets the user choose an existing photo or video in a generic action sheet for picking media from the device.")
		static let TakePhoto = NSLocalizedString("Tomar una foto", comment: "Text for an option that lets the user take a picture with the device camera in a generic action sheet for picking media from the device.")
		static let TakeVideo = NSLocalizedString("Grabar un video", comment: "Text for an option that lets the user take a video with the device camera in a generic action sheet for picking media from the device.")
		static let Cancel = NSLocalizedString("Cancelar", comment: "Text for the 'cancel' action in a generic action sheet for picking media from the device.")
	}
	
}

private extension NSURL {
	
	func generateThumbnail() -> UIImage {
		let asset = AVAsset(URL: self)
		let generator = AVAssetImageGenerator(asset: asset)
		generator.appliesPreferredTrackTransform = true
		var time = asset.duration
		time.value = 0
		let imageRef = try? generator.copyCGImageAtTime(time, actualTime: nil)
		let thumbnail = UIImage(CGImage: imageRef!)
		return thumbnail
	}
	
}