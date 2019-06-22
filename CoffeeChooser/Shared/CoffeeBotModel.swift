//
//  Model.swift
//  CoffeeChooser
//
//  Created by Tony Hung on 6/5/19.
//  Copyright © 2019 Dark Bear Interactive. All rights reserved.
//

import Foundation
import CoreML
import Alamofire
import SwiftyJSON
import Firebase

class CoffeeBotModel {
    
    static let shared = CoffeeBotModel()
    static var destinationFileUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.tonyhung.coffeechooser")?.appendingPathComponent("coffee_prediction.mlmodel")
	
		//documentsUrl.appendingPathComponent("coffee_prediction.mlmodel")
	
    static let defaults = UserDefaults(suiteName: "group.com.tonyhung.coffeechooser")

    func downloadModel(_ completion: @escaping (_ success: Bool) -> Void) {
		let storage = Storage.storage()
		let storageRef = storage.reference()
		let modelRef = storageRef.child("CoffeeBot.mlmodel")
		
		let downloadTask = modelRef.write(toFile: CoffeeBotModel.destinationFileUrl!) { url, error in
			if let error = error {
				print("error downloading model",error)
				// Uh-oh, an error occurred!
				completion(false)
			} else {
				print("downloaded new model")
				completion(true)
			}
		}
    }
	
    
    func checkForLatestVersion(_ completion: @escaping (_ updateAvailable: Bool) -> Void) {
		
		let storage = Storage.storage()
		let storageRef = storage.reference()
		let modelRef = storageRef.child("CoffeeBot.mlmodel")
		
		modelRef.getMetadata { metadata, error in
			if let error = error {
				// Uh-oh, an error occurred!
				print(error)	
			} else {
				//check the md5Hash
				let update = (metadata?.md5Hash != CoffeeBotModel.defaults?.string(forKey:"md5Hash"))
				print("DOWNLOAD MODEL? \(update)")
				
				 CoffeeBotModel.defaults?.set(metadata?.md5Hash, forKey: "md5Hash")
				completion(update)
			}
		}
	}

    
    func loadModel() -> MLModel? {
       
        do {
			let compiledUrl = try MLModel.compileModel(at: CoffeeBotModel.destinationFileUrl!)
            let model = try MLModel(contentsOf: compiledUrl)
            return model
        } catch {
            return nil
        }
    }
}
