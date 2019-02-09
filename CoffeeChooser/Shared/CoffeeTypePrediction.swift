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


class CoffeeTypePrediction {
    
    static let shared = CoffeeTypePrediction()
	let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)
	

    func predict(_ location:CLLocationCoordinate2D, completion: @escaping (_ prediction: coffee_predictionOutput?, _ jsonResponse:JSON?) -> Void) {
        
        OpenWeatherAPI.sharedInstance.weatherDataFor(location: location, completion: {
            (response: JSON?) in
            
            guard let json = response else {
                return
            }

            if #available(iOS 11.0, *) {
                let model = coffee_prediction()
                guard let mlMultiArray = try? MLMultiArray(shape:[23,1], dataType:MLMultiArrayDataType.double) else {
                    fatalError("Unexpected runtime error. MLMultiArray")
                }
                var values = [json["clouds"]["all"].doubleValue,
                              json["main"]["humidity"].doubleValue,
                              round(json["main"]["temp"].doubleValue),
                              round(json["visibility"].doubleValue / 1609.344),
                              round(json["wind"]["speed"].doubleValue),
                              ]
				
				
				let day_of_week = Calendar.current.component(.weekday, from: Date()) // 1 - 7\
				values.append(Double(day_of_week))

				let is_weekend  = (day_of_week == 1 || day_of_week == 7)
				values.append(is_weekend ? 1 : 0)
				
			
				
				//season_fall
				let month = Calendar.current.component(.month, from: Date())
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
				
				values.append(contentsOf: self.toOneHot(json["weather"][0]["main"].stringValue))
			
				
                for (index, element) in values.enumerated() {
                    mlMultiArray[index] = NSNumber(floatLiteral: element )
                }
				print("mlMultiArray",mlMultiArray)
                let input = coffee_predictionInput(input: mlMultiArray)
				
				do {
					let prediction = try model.prediction(input: input)
					completion(prediction, json)
				} catch {
					print(error)
				}

                
            } else {
                // Fallback on earlier versions
            }
        })
    }
    
    func toOneHot(_ string:String) -> [Double] {
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

}
