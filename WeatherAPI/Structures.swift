//
//  Structures.swift
//  ThunderAPI
//
//  Created by System Administrator on 6/3/17.
//  Copyright © 2017 System Administrator. All rights reserved.
//


import MapKit

/**
 Represents weather data for a single city. Parent 
 structure for other weather-related structs 
 */
class CityWeatherAnnotation: NSObject {
    var cityID : Int; //id
    var cityName: String; //name

    
    var mainWeather : Main?; //main
    var currentConditions : Weather?; //weather
    var coordinates : Coordinates?; //coord
    var wind : Wind?; //wind
    var clouds : Clouds?; //clouds
    var rain : Rain?; // rain
    
    init(id: Int? = 0, name: String? = "") {
        self.cityID = id!;
        self.cityName = name!;

    }
    
    
    /**
     Returns icon image name (name of icon in assets) for a given weathermap weather code
     
     weatherID CODES:
     200s - Thunder
     300s - Drizzle
     500s - Rain
     600s - Snow
     700s - Atmosphere
     800 = clear
     800s - cloudy
     900s - extreme
 
     */
    func getImageName(weatherCode : Int?) -> String {
        if(weatherCode == nil) {
            return "clear"
        }
        if(weatherCode>=200 && weatherCode<300) {
            return "thunder";
        } else if(weatherCode>=300 && weatherCode<400) {
            return "drizzly";
        }  else if(weatherCode>=500 && weatherCode<600) {
            return "rainy";
        }  else if(weatherCode>=600 && weatherCode<700) {
            return "snowy";
        }  else if(weatherCode==800) {
            return "clear";
        }  else if(weatherCode>800 && weatherCode<804) {
            return "partly_cloudy";
        }  else if(weatherCode>=804 && weatherCode<900) {
            return "cloudy";
        }   else if(weatherCode>=900 && weatherCode<910) {
            return "thunder";
        } else {
            return "clear"
        }
        
    }
    
    
    func getWeatherInfoString() -> String{
        var weatherInfo = " ";
        
        if let conditionsDesc = currentConditions?.description {
            weatherInfo = weatherInfo.stringByAppendingString(conditionsDesc)
        }
        
        if let conditionsTemp = mainWeather?.temp {
            weatherInfo = weatherInfo.stringByAppendingString("\n temp: " + (NSString(format: "%.1f", conditionsTemp) as String) + "C")
        }

        if let conditionshumidity = mainWeather?.humidity {
            weatherInfo = weatherInfo.stringByAppendingString("\n humidity: \(conditionshumidity)%")
        }

        if let conditionsCloudCover = clouds?.cloudCoverPercent {
            weatherInfo = weatherInfo.stringByAppendingString("\n cloud cover: \(conditionsCloudCover)%")
        }

        return weatherInfo;
        
    }
    
    func getMapAnnotation() -> MKAnnotation {
        
        var imageNameString : String = "clear";
        if (currentConditions?.weatherID != nil) {
            imageNameString = getImageName((currentConditions?.weatherID)!)
        }
        
            return MapAnnotation(title: cityName,
                                 locationName: "",
                                 discipline: getWeatherInfoString(),
                                 coordinate: coordinates!.get2DCoords(),
                                 imageName: imageNameString);
            
    }
    
}

/**
 Mapkit annotation object.
 */
class MapAnnotation: NSObject, MKAnnotation {
    let title: String?
    let locationName: String
    let discipline: String
    let coordinate: CLLocationCoordinate2D
    let pinCustomImageName : String?
    
    init(title: String, locationName: String, discipline: String, coordinate: CLLocationCoordinate2D, imageName: String) {
        self.title = title
        self.locationName = locationName
        self.discipline = discipline
        self.coordinate = coordinate
        self.pinCustomImageName = imageName
        super.init()
    }
    
    var subtitle: String? {
        return locationName
    }
}


//Main weather variables (temperature, pressure, humidity)
struct Main {
    var temp : Double; //id
    var pressure : Double; //pressure
    var humidity : Int; //description
//    var temp_min : Double; //icon
//    var temp_max : Double; //icon
    
    init(temp: Double? = 0.0, pressure: Double? = 0.0, humidity: Int? = 0) {
        self.temp = temp!;
        self.pressure = pressure!;
        self.humidity = humidity!;
    }
    
}

struct Coordinates {
    var latitude : Double; //lat
    var longitude : Double; //lon
    
    
    init(latitude: Double? = 0.0, longitude: Double? = 0.0) {
        self.latitude = latitude!;
        self.longitude = longitude!;

    }
    
    //Returns a 2d location coordinate object for this coordinate set
    func get2DCoords() -> CLLocationCoordinate2D {
        return  CLLocationCoordinate2D(latitude: latitude,longitude: longitude)
    }
}


/** Current weather conditions for city
 
    Note:   Unlike the "Main", which has temps/pressure/humidity stats, "Weather" has
            information on the current weather condition like "snowy", "partly cloudy" etc
 */
struct Weather {
    var weatherID : Int; //id
    var group : String //main
    var description : String //description
    var icon : String //icon
    
    init(id: Int? = 0, group: String? = "", description: String? = "", icon: String? = "") {
        self.weatherID = id!;
        self.group = group!;
        self.description = description!;
        self.icon = icon!;
    
    }

    
}

//Wind speed/direction
struct Wind {
    var speed: Double; //speed
    var degrees: Int; //deg
}


//Cloudiness %
struct Clouds {
    var cloudCoverPercent : Int; //all
    
    init(cloudCoverPercent: Int? = 0) {
        self.cloudCoverPercent = cloudCoverPercent!;
    }
}

//Rain in last 3 hours
struct Rain {
    var rain3Hour : Double; //3h
}


