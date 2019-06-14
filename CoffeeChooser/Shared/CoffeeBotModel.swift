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

class CoffeeBotModel {
    
    static let shared = CoffeeBotModel()
    static var documentsUrl:URL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    static var destinationFileUrl = documentsUrl.appendingPathComponent("coffee_prediction.mlmodel")
    static let defaults = UserDefaults(suiteName: "group.com.tonyhung.coffeechooser")

    func downloadModel(_ completion: @escaping (_ success: Bool) -> Void) {
        checkForLatestVersion { (json) in
            print(json)
            
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
                    
                    if let Etag = (response as? HTTPURLResponse)?.allHeaderFields["Etag"] {
                        print("Etag: \(Etag)")
                        CoffeeBotModel.defaults?.set(Etag, forKey: "Etag")
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
        
    }
    
    func fileExists(_ completion: @escaping (_ success: Bool) -> Void) {
        

//        return FileManager.default.fileExists(atPath: CoffeeBotModel.destinationFileUrl.path)
    }
    
    func checkForLatestVersion(_ completion: @escaping (_ response: JSON?) -> Void) {
        let etag = "ee90747cab24f8aca2dcf8f5851c4d16"//CoffeeBotModel.defaults?.string(forKey: "Etag")

            let url = URL(string: "https://a401c6f6.ngrok.io/model?etag=\(etag)")!
            print(url)
            Alamofire.request(url).validate().responseJSON { response in
                switch response.result {
                case .success:
                    
                    guard let value = response.result.value else {
                        completion(nil)
                        return
                    }
                    let responseJSON = JSON(value)
                    
                    completion(responseJSON)
                    
                case .failure(let error):
                    print(error)
                }
            }
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
