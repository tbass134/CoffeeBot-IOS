# Uncomment the next line to define a global platform for your project
platform :ios, '11.0'

def sharedPods
	pod 'Alamofire'
	pod 'SwiftyJSON'
	#pod 'SwiftyJSON',  '~> 4.0.0-alpha.1'
	pod 'Firebase'
	pod 'Firebase/Database'
	pod 'Firebase/Auth'
	pod 'Firebase/Core'
	pod 'SwiftSVG'
	pod 'SwiftLocation', '~> 3.2.3'
	pod 'KeychainAccess'

end

target 'CoffeeChooser' do
  # Comment the next line if you're not using Swift and don't want to use dynamic 	frameworks
  use_frameworks!
  sharedPods
	
end

target 'SiriKit' do
	use_frameworks!
	sharedPods
end
