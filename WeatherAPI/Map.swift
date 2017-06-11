//
//  Map.swift
//  ThunderAPI
//
//  Created by System Administrator on 6/3/17.
//  Copyright © 2017 System Administrator. All rights reserved.
//


import UIKit
import CoreLocation
import MapKit

/**
 Displays map with current user's location at the center, and weather info 
 for surrounding cities attached as annotations
 */
class Map: UIViewController {

    @IBOutlet var mapView: MKMapView?

    var mWeatherDataSet = Array<CityWeatherAnnotation>();
    var userLocation : CLLocationCoordinate2D!;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = ""
        
        let region = MKCoordinateRegionMake(userLocation, MKCoordinateSpan(latitudeDelta: 2.5, longitudeDelta: 2.5))
        mapView!.setRegion(region, animated: false)
        mapView?.delegate = self;
        
        //Then attach objects to map
        for city in self.mWeatherDataSet {
            if city.coordinates != nil {
                self.mapView!.addAnnotation(city.getMapAnnotation())
            }
        }
        mapView!.showAnnotations(self.mapView!.annotations, animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}


extension Map: MKMapViewDelegate {
    
    
    // Adds annotations to map
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        
        if let annotation = annotation as? MapAnnotation {
            
            // Don't want to show a custom image if the annotation is the user's location.
            guard !annotation.isKindOfClass(MKUserLocation) else {
                return nil
            }
            
            let annotationIdentifier = "AnnotationIdentifier"
            
            var annotationView: MKAnnotationView?
            if let dequeuedAnnotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(annotationIdentifier) {
                annotationView = dequeuedAnnotationView
                annotationView?.annotation = annotation
            } else {
                let av = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
                av.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
                annotationView = av
            }
            
            if let annotationView = annotationView {
                annotationView.canShowCallout = true
                if let customPinImage = annotation.pinCustomImageName {
                    annotationView.image = UIImage(named: customPinImage)?.imageWithRenderingMode(.AlwaysOriginal);
                }
                
                            }
            annotationView!.detailCalloutAccessoryView = self.configureDetailView(annotation.discipline)
            annotationView?.rightCalloutAccessoryView?.hidden = true
            return annotationView
            
        }
        return nil
    }
    

    /**
     Creates an expanded annotation Callout view, so that the breakdown of weather detail is fully visible when
     a city's pin is selected
     
     - parameter detailtext : detail text that will be shown in callout
     */
    func configureDetailView(detailText : String) -> UIView {
        let detailView = UITextView()
        detailView.text = detailText
        detailView.font = detailView.font!.fontWithSize(16)
        let views = ["detailView": detailView]
        detailView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[detailView(120)]", options: [], metrics: nil, views: views))
        detailView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:[detailView(160)]", options: [], metrics: nil, views: views))

        //do your work
        return detailView
    }
    

}

