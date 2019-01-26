//
//  ViewController.swift
//  CoffeeChooser
//
//  Created by Antonio Hung on 5/26/17.
//  Copyright © 2017 Dark Bear Interactive. All rights reserved.
//

import UIKit
import CoreLocation
import SwiftyJSON
import Firebase
import FirebaseDatabase
import SwiftLocation
import Intents
import IntentsUI


class TrainViewController: SuperViewController  {
    
	var ref: DatabaseReference!

    var jsonData:JSON?
	var lastlocation:CLLocation?
	
    
	var locationLoaded = false
	let hotCoffeeImage = UIImage.init(named: "coffee_hot")
	let icedCoffeeImage = UIImage.init(named: "coffee_iced")
    
	@IBOutlet weak var collectionView: UICollectionView!
	
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        
		NotificationCenter.default.addObserver(self, selector: #selector(locationUpdated(notification:)), name: .locationDidChange, object: nil)
		
		NotificationCenter.default.addObserver(self, selector: #selector(locationError(notification:)), name: Notification.Name.locationDidFail, object: nil)
    
		self.collectionView.backgroundColor = UIColor.clear
		
		// Create the info button
		let infoButton = UIButton(type: .infoLight)
		infoButton.addTarget(self, action: #selector(aboutBtnSelected), for: .touchUpInside)
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: infoButton)
    }
	
   override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    
        guard let lastLoc = LocationManager.shared.lastLocation() else {
            return
        }
        weatherDataLoaded(lastLoc)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
	
	@objc func locationUpdated(notification: NSNotification) {
		guard let location = notification.userInfo!["location"] as? CLLocation else {
            weatherDataLoaded(nil)

			return
		}
        weatherDataLoaded(location)
		
	}
    
    func weatherDataLoaded(_ location:CLLocation?) {
        print("locations",location?.coordinate as Any)
        self.lastlocation = location
        self.collectionView.reloadData()
    }


	@objc func locationError(notification:Notification) {
		presentAlert(title: "Unable to aquire location", message: "Please try again.")
	}

    @IBAction func aboutBtnSelected(_ sender: Any) {
		
		presentAlert(title: "About this app.", message: "Whenever you reach for a cup of coffee, open this app and select the type of coffee your are drinking (hot or iced) This will help the application be able to perdict what type of coffee you will have in the future")
    }
    
    func saveItem(_ coffeeType:Coffee) {
		
		print("selected")

		
		
        guard let location = self.lastlocation else {
            return
        }
		if #available(iOS 12.0, *) {
			if coffeeType == Coffee.Hot {
				SelectHotCoffeeIntent().donate("selected_hot_coffee")
			} else {
				SelectIcedCoffeeIntent().donate("selected_iced_coffee")
			}
		}
        CoffeeTypeTrain.shared.train(location, coffeeType: coffeeType) { (success) in
            
            let alert = UIAlertController(title: "Coffee Type Saved", message: "Your input was saved! Come back again to enter your enter coffee type when you order more coffee!", preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { (action) in
                alert.dismiss(animated: true, completion: nil)
            }));
			alert.addAction(UIAlertAction(title: "Undo", style: UIAlertAction.Style.default, handler: { (action) in
				CoffeeTypeTrain.shared.undo()
				self.presentAlert(title: "Your recent input was removed")
			}))
            self.present(alert, animated: true, completion: nil)

        }
    }
}

extension TrainViewController: UICollectionViewDelegate, UICollectionViewDataSource {
	
	func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 1
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return 2
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CollectionViewCell
        cell.delegate = self
		
		if (indexPath.row == 0) {
            cell.type = Coffee.Hot
			cell.imageView.image = hotCoffeeImage
			cell.label.text = "Hot Coffee"
		} else if (indexPath.row == 1) {
            cell.type = Coffee.Iced
			cell.imageView.image = icedCoffeeImage
			cell.label.text = "Iced Coffee"
		}
		
		if (self.lastlocation == nil) {
			cell.imageView.image = cell.imageView.image!.Noir()
		} else {
			if (indexPath.row == 0) {
				cell.imageView.image = hotCoffeeImage
			} else if (indexPath.row == 1) {
				cell.imageView.image = icedCoffeeImage
			}
		}
        
		return cell
	}
	
	func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
		
		switch kind {
		case UICollectionView.elementKindSectionHeader:
			let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
																			 withReuseIdentifier: "header",
																			 for: indexPath) as! HeaderView
			headerView.label.text = "Select the type of coffee you are currently having"
			return headerView
		default:
			assert(false, "Unexpected element kind")
		}
		
		return UICollectionReusableView()
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		if (self.lastlocation == nil) {
			return
		}
		
		if (indexPath.row == 0) {
			saveItem(Coffee.Hot)
		} else if (indexPath.row == 1) {
			saveItem(Coffee.Iced)
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		
		if #available(iOS 11.0, *) {
			return CGSize(width: (view.safeAreaLayoutGuide.layoutFrame.width), height: 200)
		} else {
			// Fallback on earlier versions
			return CGSize(width: (collectionView.frame.size.width), height: 200)
		}
	}
}

extension TrainViewController:CoffeeCellDelegate {
    
    @available(iOS 12.0, *)
    func presentAddVoiceShortcutvc(vc:INUIAddVoiceShortcutViewController) {
        present(vc, animated: true, completion: nil)
    }
    
    @available(iOS 12.0, *)
    func presentEditVoiceShortcutvc(vc:INUIEditVoiceShortcutViewController) {
        present(vc, animated: true, completion: nil)

    }
    
    @available(iOS 12.0, *)
    func dismissAddVoiceShortcutVC(vc:INUIAddVoiceShortcutViewController) {
        vc.dismiss(animated: true, completion: nil  )
    }
    
    @available(iOS 12.0, *)
    func dismissEditVoiceShortcutVC(vc:INUIEditVoiceShortcutViewController) {
        vc.dismiss(animated: true, completion: nil  )
    }

}


class CollectionViewCell:UICollectionViewCell {
    var type:Coffee? {
        didSet {
            if #available(iOS 12.0, *) {
                INPreferences.requestSiriAuthorization { (status) in
                    
                    if status != .authorized {
                        return
                    }

                    let addShortcutButton = INUIAddVoiceShortcutButton(style: .whiteOutline)

                    if self.type == Coffee.Hot {
                        let intent = SelectHotCoffeeIntent()
                        intent.suggestedInvocationPhrase = "I'm having hot coffee"
                        addShortcutButton.shortcut = INShortcut(intent: intent)

                    } else if self.type == Coffee.Iced {
                        let intent = SelectIcedCoffeeIntent()
                        intent.suggestedInvocationPhrase = "I'm having iced coffee"
                        addShortcutButton.shortcut = INShortcut(intent: intent)
                    }
                    
                    addShortcutButton.delegate = self as INUIAddVoiceShortcutButtonDelegate
                    
                    addShortcutButton.translatesAutoresizingMaskIntoConstraints = false
                    self.siriView.addSubview(addShortcutButton)
                    self.siriView.centerXAnchor.constraint(equalTo: addShortcutButton.centerXAnchor).isActive = true
                    self.siriView.centerYAnchor.constraint(equalTo: addShortcutButton.centerYAnchor).isActive = true
                }
    
            }
        }
    }
	
	
	
    var delegate:CoffeeCellDelegate?
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var siriView: UIView!
    
    
	override var isHighlighted: Bool {
		didSet{
			if self.isHighlighted {
				imageView.alpha = 0.5
			}
			else {
				imageView.alpha = 1
			}
		}
	}
}

@available(iOS 12.0, *)
extension CollectionViewCell: INUIAddVoiceShortcutButtonDelegate {
    
    func present(_ addVoiceShortcutViewController: INUIAddVoiceShortcutViewController, for addVoiceShortcutButton: INUIAddVoiceShortcutButton) {
        addVoiceShortcutViewController.delegate = self
        delegate?.presentAddVoiceShortcutvc(vc: addVoiceShortcutViewController)
    }
    
    /// - Tag: edit_phrase
    
    func present(_ editVoiceShortcutViewController: INUIEditVoiceShortcutViewController, for addVoiceShortcutButton: INUIAddVoiceShortcutButton) {
        editVoiceShortcutViewController.delegate = self
        delegate?.presentEditVoiceShortcutvc(vc: editVoiceShortcutViewController)
    }
}

@available(iOS 12.0, *)
extension CollectionViewCell: INUIAddVoiceShortcutViewControllerDelegate {
    
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController,
                                        didFinishWith voiceShortcut: INVoiceShortcut?,
                                        error: Error?) {
        if let error = error as NSError? {
            print(error)
        }
        delegate?.dismissAddVoiceShortcutVC(vc: controller)
    }
    
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        delegate?.dismissAddVoiceShortcutVC(vc: controller)
    }
}

@available(iOS 12.0, *)
extension CollectionViewCell: INUIEditVoiceShortcutViewControllerDelegate {
    
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController,
                                         didUpdate voiceShortcut: INVoiceShortcut?,
                                         error: Error?) {
        if let error = error as NSError? {
            print(error)
        }
        
        controller.dismiss(animated: true, completion: nil)
    }
    
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController,
                                         didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {
        delegate?.dismissEditVoiceShortcutVC(vc: controller)
    }
    
    func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController) {
        delegate?.dismissEditVoiceShortcutVC(vc: controller)
    }
}


class HeaderView: UICollectionReusableView {
	@IBOutlet weak var label: UILabel! {
		didSet {
			label.font = UIFont.init(name: "Helvetica Neue", size: 16)
		}
	}
	
}

protocol CoffeeCellDelegate {
    @available(iOS 12.0, *)
    func presentAddVoiceShortcutvc(vc:INUIAddVoiceShortcutViewController)
    
    @available(iOS 12.0, *)
    func presentEditVoiceShortcutvc(vc:INUIEditVoiceShortcutViewController)
    
    @available(iOS 12.0, *)
    func dismissAddVoiceShortcutVC(vc:INUIAddVoiceShortcutViewController)
    
    @available(iOS 12.0, *)
    func dismissEditVoiceShortcutVC(vc:INUIEditVoiceShortcutViewController)

}
