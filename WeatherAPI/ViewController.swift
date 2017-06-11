//
//  ViewController.swift
//  ThunderAPI
//
//  Created by System Administrator on 6/3/17.
//  Copyright © 2017 System Administrator. All rights reserved.
//

import UIKit
import MapKit

/**
 View controller for main page. Clicking weather button runs the maakeAPICall method (on the main thread), and
 shows spinners. If call is successful it segues to Map VC which displays a map of user location with annotations 
 from openweathermap.org api
 */
class ViewController: UIViewController, CLLocationManagerDelegate {
   
    var locationManager = CLLocationManager()
    var mWeatherDataSet = Array<CityWeatherAnnotation>(); // dataset retrieved from api call, passed to Map VC
    var userLocation : CLLocationCoordinate2D? = nil; //current user location (from requestLocation func, passed to Map VC)
    
    
    @IBOutlet weak var weatherButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var notificationlabel: UILabel!
    @IBAction func weatherButtonClick(sender: AnyObject) {


        /* First request user location. If get user location succesful, the locationManager "didUpdateLocations"
         method will trigger the API call (makeAPICall method). If api call succesful, perform segue to Map VC. */
        notificationlabel.hidden = true;
        requestLocation()
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }

    override func viewWillAppear(animated: Bool) {
        showActivityProgressIndicator(false)
        self.title = "WeatherAPI"
        
        }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        if segue.identifier == "segueToMap" {
        let mapController = segue.destinationViewController as! Map
        mapController.mWeatherDataSet = mWeatherDataSet
        mapController.userLocation = userLocation
            self.title = "WeatherAPI"
        }
    }
    
    
    /**
     Asks user to enable location services and pulls current user location.
     On succesful completion, the MakeAPICall func runs, using the current user location as an input param
     */
    private func requestLocation() {
        showActivityProgressIndicator(true)
        
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
            locationManager.requestLocation()
        
        } else {
            self.notificationlabel.hidden = false
            self.notificationlabel.text = "Must enable location services to continue"
            showActivityProgressIndicator(false)
        }
        
    }
    
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Failed to find user's location: \(error.localizedDescription)")
        self.notificationlabel.hidden = false
        self.notificationlabel.text = "Unable to find user location"
        showActivityProgressIndicator(false)
    }
    
    
    
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if let currentLocation = locations.first {
            print("Found user's location: \(currentLocation)")

            //weak self used to make async segue on succesful api call
            weak var weakSelf = self

            if activityIndicator.isAnimating() {
                self.userLocation = currentLocation.coordinate
                print("locations = \(self.userLocation!.latitude) \(self.userLocation!.longitude)")
                
                makeAPICall(self.userLocation!, completion: { success in
                    
                    dispatch_async(dispatch_get_main_queue()) {

                    weakSelf!.showActivityProgressIndicator(false)
                    weakSelf!.performSegueWithIdentifier("segueToMap", sender: nil)
                    }
                })

            } else {
                print("Error - Loc manager nil")
                self.notificationlabel.hidden = false
                self.notificationlabel.text = "Unable to access user location"
                showActivityProgressIndicator(false)
            }
        }
    }
    
    
    /**
     Makes a call to openweathermap.org api for current weather conditions of all cities within a square "zone" 
     (defined in the bboxCreator func) centered around the current user location
     
     - parameter currentLocation: current user location, retrieved from requestLocation func
     */
    func makeAPICall(currentLocation:CLLocationCoordinate2D, completion: ((Bool)->())?) {
        
        showActivityProgressIndicator(true)
        
        
        let bboxRadius : Double = 0.5; // radius of box that will be created from centerpoint of current location
        let zoomScale  = "10" //api call zoom level (standard = 10)
        
        // Put together a URL With lat and lon
        let urlString : String = "http://api.openweathermap.org/data/2.5/box/city?bbox=" + bboxCreator(bboxRadius, latitude: currentLocation.latitude, longitude: currentLocation.longitude) + "," + zoomScale
            + "&APPID=d2e4c25158dff974713682089ac89ebd"
        
        let configuration = NSURLSessionConfiguration .defaultSessionConfiguration()
        let session = NSURLSession(configuration: configuration)
        let url = NSURL(string: urlString as String)
        print("url string is \(url)")
        
        let request : NSMutableURLRequest = NSMutableURLRequest()
        request.URL = NSURL(string: urlString)
        request.HTTPMethod = "GET"
        request.timeoutInterval = 30
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let dataTask = session.dataTaskWithRequest(request) {
            (let data: NSData?, let response: NSURLResponse?, let error: NSError?) -> Void in
            
            // 1: Check HTTP Response for successful GET request
            guard let httpResponse = response as? NSHTTPURLResponse, receivedData = data
                else {
                    self.notificationlabel.hidden = false
                    self.notificationlabel.text = "Error retrieving data from openweathermap.org"
                    self.showActivityProgressIndicator(false)
                    completion?(false)
                    return
            }
            
            switch (httpResponse.statusCode) {

            case 200:
                
                do {
                    
                    // If api call successful, retrieve and parse JSON array for the entry "list"
                    if let getResponse = try NSJSONSerialization.JSONObjectWithData(receivedData, options: .AllowFragments) as? [NSObject:AnyObject] {
                        if let myobj = getResponse["list"] as? [[NSObject:AnyObject]] {
                            
                            self.mWeatherDataSet=self.parseJson(myobj)
                            completion?(true)
                        }
                    }
    
                } catch {
                    self.showActivityProgressIndicator(false)
                    completion?(false)
                    print("error serializing JSON: \(error)")
                }
                
                break
            case 400:
                self.notificationlabel.hidden = false
                self.notificationlabel.text = "Error retrieving data from openweathermap.org"
                self.showActivityProgressIndicator(false)
                completion?(false)
                break
            default:
                self.notificationlabel.hidden = false
                self.notificationlabel.text = "Error retrieving data from openweathermap.org"
                print("GET request got response \(httpResponse.statusCode)")
                self.showActivityProgressIndicator(false)
                completion?(false)
            }
        }
        dataTask.resume()
        
    }
    
    
    
    
    /**
     Parses openweathermap.org JSON response into an array of CityWeatherAnnotation objects
     - parameter anyObj: array of JSON objects. Each collection represents the current weather data for
     a city within the specified lat/lon box
     
     */
    func parseJson(anyObj: [[NSObject:AnyObject]]) -> Array<CityWeatherAnnotation>{
        var list: Array<CityWeatherAnnotation> = []
        
        for json in anyObj {
            let cityWeather: CityWeatherAnnotation = CityWeatherAnnotation()
            cityWeather.cityID = (json["id"] as? Int) ?? 0
            cityWeather.cityName = (json["name"] as? String) ?? ""
            
            
            
            //Extract weather conditions for city. For simplicity's sake, take only the first weather condition available for a city (if any)
            if let weatherObj = json["weather"] as? [[NSObject:AnyObject]] {
                
                if(weatherObj.count>0) {
                    var weatherConditions = Weather();
                    
                    print("weatherobject: \(weatherObj)")
                    weatherConditions.weatherID = (weatherObj[0]["id"] as? Int) ?? 0
                    weatherConditions.group = (weatherObj[0]["main"] as? String) ?? ""
                    weatherConditions.description = (weatherObj[0]["description"] as? String) ?? ""
                    weatherConditions.icon = (weatherObj[0]["icon"] as? String) ?? ""
                    
                    cityWeather.currentConditions = weatherConditions
                    
                }
            }
            
            //Extract coordinates for city
            if let coordsObject = json["coord"] as? [NSObject:AnyObject] {
                var cityCoords = Coordinates();
                
                print("coordsObject: \(coordsObject)")
                cityCoords.latitude = (coordsObject["Lat"] as? Double) ?? 0.0
                cityCoords.longitude = (coordsObject["Lon"] as? Double) ?? 0.0
                cityWeather.coordinates = cityCoords
            }
            

            //Extract temp/pressure/humidity for city
            if let mainWeatherObject = json["main"] as? [NSObject:AnyObject] {
                var mainWeather = Main();
                
                print("mainWeatherObject: \(mainWeatherObject)")
                mainWeather.temp = (mainWeatherObject["temp"] as? Double) ?? 0.0
                mainWeather.pressure = (mainWeatherObject["pressure"] as? Double) ?? 0.0
                mainWeather.humidity = (mainWeatherObject["humidity"] as? Int) ?? 0
                
                cityWeather.mainWeather = mainWeather
            }

            //Extract temp/pressure/humidity for city
            if let cloudsObject = json["clouds"] as? [NSObject:AnyObject] {
                var clouds = Clouds();
                
                print("cloudsObject: \(cloudsObject)")
                clouds.cloudCoverPercent = (cloudsObject["today"] as? Int) ?? 0
                cityWeather.clouds = clouds
            }
            
            print("DATASET CITY: \(cityWeather.cityName), weathercode: \(cityWeather.currentConditions?.weatherID), latlon: \(cityWeather.coordinates)")
            
            list.append(cityWeather)
        }
        return list
    }
    
    
    
    
    /**
     The call made to the openweathermap api is not just for one city, but for square "box" of space
     within which the weather for all cities will be displayed. This method creates that box using the user's current
     location as the center point
     - parameter radius: radius of box (i.e. distance from center point to nearest wall)
     - parameter latitude: current latitude of user
     - parameter longitude: current longitude of user
     
     NOTE! I'm pretty sure this version does not handle maps boxes that are right next to the north pole or whatever. The box bounds should be capped
     at the maximum values of latitude and longitude, but I am too lazy to do so.
     */
    func bboxCreator(radius: Double, latitude: Double, longitude: Double)-> String {
        /**
         Request weather in bounding box: bbox [lon-left,lat-bottom,lon-right,lat-top,zoom]
         */
        let leftBound = longitude - radius;
        let rightBound = longitude + radius;
        let bottomBound = latitude - radius;
        let topBound = latitude + radius;
        
        var bboxString = "";
        bboxString = bboxString.stringByAppendingString((NSString(format: "%.5f", leftBound) as String) + ",")
        bboxString = bboxString.stringByAppendingString((NSString(format: "%.5f", bottomBound) as String) + ",")
        bboxString = bboxString.stringByAppendingString((NSString(format: "%.5f", rightBound) as String) + ",")
        bboxString = bboxString.stringByAppendingString((NSString(format: "%.5f", topBound) as String))
        
        return bboxString
        
    }

    /** Shows progress indicator (and prevents button clicks) while api call is underway
     - parameter show: bool true to show indicator, false to hide it
     */
    func showActivityProgressIndicator(show: Bool) {
        if(show) {
            weatherButton.enabled = false
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            activityIndicator.startAnimating()
        } else {
            weatherButton.enabled = true
            activityIndicator.stopAnimating()
        }
        
    }
    
    
    

}

