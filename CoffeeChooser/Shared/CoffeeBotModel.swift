//
//  Model.swift
//  CoffeeChooser
//
//  Created by Tony Hung on 6/5/19.
//  Copyright © 2019 Dark Bear Interactive. All rights reserved.
//

import Foundation
import CoreML

class CoffeeBotModel {
    
    static let shared = CoffeeBotModel()
    static var documentsUrl:URL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    static var destinationFileUrl = documentsUrl.appendingPathComponent("coffee_prediction.mlmodel")

    func downloadModel(_ completion: @escaping (_ success: Bool) -> Void) {
        if fileExists() {
            completion(true)
            return
        }
        let url = URL(string:"https://coffee-chooser-app.s3.amazonaws.com/models/coffee_prediction.mlmodel")

        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        let request = try! URLRequest(url: url!, method: .get)

        let task = session.downloadTask(with: request) { (tempLocalUrl, response, error) in
            if let tempLocalUrl = tempLocalUrl, error == nil {
                // Success
                if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                    print("Success: \(statusCode)")
                }

                do {
                    try FileManager.default.copyItem(at: tempLocalUrl, to: CoffeeBotModel.destinationFileUrl)
                    completion(true)
                } catch (let writeError) {
                    print(writeError)
                    completion(false)
                }

            } else {
                print("Failure: %@", error?.localizedDescription);
            }
        }
        task.resume()
    }
    
    func fileExists() ->Bool {
        return FileManager.default.fileExists(atPath: CoffeeBotModel.destinationFileUrl.path)
    }
    
    func loadModel() -> MLModel? {
       
        do {
            let compiledUrl = try MLModel.compileModel(at: CoffeeBotModel.destinationFileUrl)
            let model = try MLModel(contentsOf: compiledUrl)
            return model
        } catch {
            return nil
        }
    }
}
