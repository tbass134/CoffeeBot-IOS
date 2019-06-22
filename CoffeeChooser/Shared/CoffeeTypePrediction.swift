//
//  CoffeeTypePrediction.swift
//  CoffeeChooser
//
//  Created by Tony Hung on 8/28/18.
//  Copyright © 2018 Dark Bear Interactive. All rights reserved.
//

import Foundation
import CoreLocation
import SwiftyJSON
import CoreML
//import Firebase
import Intents

struct CoffeePrediction {
    var classLabel:Int64?
    var classProbability:Float?
}

class CoffeeTypePrediction {
    
    static let shared = CoffeeTypePrediction()
	let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)
	

    func predict(_ location:CLLocationCoordinate2D, completion: @escaping (_ prediction: CoffeePrediction?, _ jsonResponse:JSON?) -> Void) {
		
		//load the latest model
		CoffeeBotModel.shared.checkForLatestVersion { (avail) in
			if avail {
				CoffeeBotModel.shared.downloadModel({ (downloaded) in
					print("downloaded \(downloaded)")
					self.load(location, completion: completion)
				})
			} else {
				self.load(location, completion: completion)
			}
		}

		
    }
	
	func load(_ location:CLLocationCoordinate2D, completion: @escaping (_ prediction: CoffeePrediction?, _ jsonResponse:JSON?) -> Void) {
		
		OpenWeatherAPI.sharedInstance.weatherDataFor(location: location, completion: {
			(response: JSON?) in
			
			guard let json = response else {
				return
			}
			
			
			let model = CoffeeBotModel.shared.loadModel()
			
			
			guard let mlMultiArray = try? MLMultiArray(shape:[40,1], dataType:MLMultiArrayDataType.double) else {
				fatalError("Unexpected runtime error. MLMultiArray")
			}
			var values = [json["clouds"]["all"].doubleValue,
						  json["main"]["humidity"].doubleValue,
						  round(json["main"]["temp"].doubleValue),
						  round(json["visibility"].doubleValue / 1609.344),
						  self.wind_bft(json["wind"]["speed"].doubleValue)
			]
			
			
			let day_of_week = Calendar.current.component(.weekday, from: Date()) // 1 - 7\
			values.append(Double(day_of_week))
			
			let is_weekend  = (day_of_week == 1 || day_of_week == 7)
			values.append(is_weekend ? 1 : 0)
			
			
			//month
			let month = Calendar.current.component(.month, from: Date())
			values.append(Double(month))
			
			//season
			var season = [Double](repeating: 0.0, count: 4)
			if (month>2 && month <= 5) {
				season[0] = 1
			} else if (month >= 6 && month <= 8) {
				season[1] = 1
			} else if (month >= 9 && month <= 11) {
				season[2] = 1
			} else {
				season[3] = 1
			}
			values.append(contentsOf: season)
			
			//part of day
			let current_hour = Calendar.current.component(.hour, from: Date())
			var part_of_day = [Double](repeating: 0.0, count: 4)
			
			if (current_hour  >= 5 && current_hour <= 11) {
				part_of_day[0] = 1
			} else if (current_hour >= 12 && current_hour <= 17) {
				part_of_day[1] = 1
			} else if (current_hour >= 18 && current_hour <= 22) {
				part_of_day[2] = 1
			} else {
				part_of_day[3] = 1
			}
			values.append(contentsOf: (part_of_day))
			
			//weather condition
			values.append(contentsOf: self.cloundsToOneHot(json["weather"][0]["main"].stringValue))
			
			//wind direction
			values.append(contentsOf: self.windDegToOneHot(json["wind"]["deg"].doubleValue))
			
			
			
			for (index, element) in values.enumerated() {
				mlMultiArray[index] = NSNumber(floatLiteral: element )
			}
			let input = CoffeeBotInput(features: mlMultiArray)
			
			do {
				let prediction = try model!.prediction(from: input)
				let classLabel = prediction.featureValue(for: "type")?.int64Value
				let classProbability = Float(prediction.featureValue(for: "classProbability")!.dictionaryValue[classLabel]!)
				
				let result = CoffeePrediction(classLabel: classLabel, classProbability: classProbability)
				
				
				completion(result, json)
			} catch {
				print(error)
			}
		})
	}
    
    func cloundsToOneHot(_ string:String) -> [Double] {
        var str = string
        var items = [Double](repeating: 0.0, count: 8)
        let weather_conds:[String] = ["Clear", "Clouds", "Fog", "Haze", "Rain", "Smoke", "Snow", "Thunderstorm"]
        
        if str.lowercased().range(of:"cloud") != nil || str.lowercased().range(of:"overcast") != nil{
            str = "Clouds"
        }
        
        if str.lowercased().range(of:"snow") != nil {
            str = "Snow"
        }
        
        if str.lowercased().range(of:"rain") != nil  || str.lowercased().range(of:"drizzle") != nil || str.lowercased().range(of:"mist") != nil{
            str = "Rain"
        }
        
        if str.lowercased().range(of:"none") != nil {
            str = "Clear"
        }
        
        guard let index = weather_conds.index(of: str) else {
            items[0] = 1
            return items
        }
        
        items[index] = 1
        return items
    }
	
	
	
	func wind_bft(_ ms:Double) ->Double {
		//"Convert wind from metres per second to Beaufort scale"
		let _bft_threshold = [
			0.3, 1.5, 3.4, 5.4, 7.9, 10.7, 13.8, 17.1, 20.7, 24.4, 28.4, 32.6]

		for bft in _bft_threshold {
			if ms < bft {
				return bft
			}
		}

		return Double(_bft_threshold.count)
	}
	
	func windDegToOneHot(_ x:Double) -> [Double] {
		
		let _directions = ["E","ENE","ESE","N","NE","NNE","NNW","NW","S","SE","SSE","SSW","SW","W","WNW","WSW"]
		
		var mod = Double(x.truncatingRemainder(dividingBy: 360)) / 22.5
		mod = round(mod)
		let direction = _directions[Int(mod)]


		var items = [Double](repeating: 0.0, count: _directions.count)
		
		guard let index = _directions.index(of: direction) else {
			items[0] = 1
			return items
		}
		
		items[index] = 1
		return items
	}
}
