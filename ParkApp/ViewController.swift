//
//  ViewController.swift
//  ParkApp
//
//  Created by Michael Bharrat on 7/13/16.
//  Copyright © 2016 Michael Bharrat. All rights reserved.
//


import UIKit
import MapKit
import AWSMobileHubHelper
import AWSCore
import AWSDynamoDB
import CoreLocation
import AVFoundation


//*************************************************************************************************************************
//                      GLOBAL VARIABLES
//*************************************************************************************************************************
var lat: NSNumber = 0   //lat of car
var long: NSNumber = 0  //long of car
var patrolLat: NSNumber = 0 //lat of patrol
var patrolLong: NSNumber = 0   //long of patrol
var timeStamp: String = "empty"
var coordinateArrLat: [Double] = [Double]()
var coordinateArrLong: [Double] = [Double]()
typealias FinishedArray = () -> ()

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UIPickerViewDelegate, UIPickerViewDataSource, FBSDKLoginButtonDelegate {
//**************************************************************************
//                          VARIABLES
//**************************************************************************
    
    @IBOutlet weak var Friends: UIButton!
    @IBOutlet weak var faceBookLogout: FBSDKLoginButton!
    @IBOutlet weak var picker: UIPickerView!  //actual picker object
    @IBOutlet var pickerView: UIView!
    @IBOutlet weak var direction: UITextView!
    @IBOutlet var dir: UIView!
    var didFriend = false
    var loading = false
    var alertWalk1 = false
    var addTime = false
    var pickerDate: [String] = [String]()
    var pickerDate2: [String] = [String]()
    var count = 0
    var location = MKUserLocation() //user location
    var finalNum = 0.0 //number selected from picker before done clicked
    var endNum = 0.0 //this is the number that is actually counted down from
    var endNumAdd = 0.0 //number that is final number when time is added and done clicked
    var timer = NSTimer() //timer that runs continuous action aka meter and travel time (used to be two but consolidated to one timer)
    var travelTime = 0.0 //constantly updated travel time to car
    var didPark = false //did user already park
    var didDirect = false //was the direction menu revealed
    var didMeter = false    //did the user park at a meter
    var center: CLLocationCoordinate2D! //???????
    var mapAnnotation: ColorPointAnnotation! //map annotation with custom picture used (Patrol)
    var mapAnnotationCar: ColorPointAnnotation!//map annotation with custom picture used (Car)
    @IBOutlet weak var bottomMenu: UIStackView!//bottom menu
    var destination:MKMapItem = MKMapItem() //destination aka where car is placed if placed
    var locationManager = CLLocationManager()
    @IBOutlet weak var Map: UIButton!
    @IBOutlet weak var onAround: UIButton!
    @IBOutlet var friendView: UIView!
    @IBOutlet weak var Park: UIButton!
    @IBOutlet weak var Report: UIButton!
    @IBOutlet weak var parkingMap: MKMapView! //map of parking areas
//*************************************************************************************************************************
//                      PAN AROUND MAP METHODS
//*************************************************************************************************************************
    //physical look-around button
    // update, can't change title of button so no need for this reference
    @IBAction func onFriend(sender: UIButton) {
        if Friends.selected == true {
            hideMenuFriend()
            didFriend = false
            Friends.selected = false
            
        }else if Friends.selected == false{
            hideMenuDir()
            showMenuFriend()
            didFriend = true
            Friends.selected = true
            
            let fbRequest = FBSDKGraphRequest(graphPath:"/me/friends", parameters: nil)
            fbRequest.startWithCompletionHandler { (connection : FBSDKGraphRequestConnection!, result : AnyObject!, error : NSError!) -> Void in
                
                if error == nil {
                    if let userNameArray : NSArray = result.valueForKey("data") as? NSArray
                    {
                        var i:Int = 0
                        for ; i<userNameArray.count ; i++ {
                            print(userNameArray[i].valueForKey("name"))
                        }      
                        
                    } else {
                        
                        print("Error Getting Friends \(error)");
                        
                    }
                }

            }
        }

    }

    
    
    //when button is clicked, allow for pan of map
    @IBAction func onLook(sender: UIButton) {
        if tempUser == 1{
            self.alertLook()
        }
        if onAround.selected == false{
            self.locationManager.stopUpdatingLocation()
            onAround.selected = true
        }else{
            self.locationManager.startUpdatingLocation()
            onAround.selected = false
        }
    }
    //when two fingers tap twice, pull screen to user location
    //two finger tap
    @IBAction func onLookTap(sender: AnyObject) {
        if onAround.selected == true {
            self.locationManager.startUpdatingLocation()
            onAround.selected = false
        }
        //print("tap registered")
    }
    
  
//*************************************************************************************************************************
//                          METHODS CALLED FOR THE TIMER PICKER (CANCEL BUTTON, DONE BUTTON)
//*************************************************************************************************************************

    @IBAction func onCancelPicker(sender: UIButton) {
        hideTimePicker()
    }
    @IBAction func onDonePicker(sender: UIButton) {
        didMeter = true
        self.alertWalk1 = false
        //if first setting time
        if addTime == false{
            endNum = finalNum
            self.startUpdating()
            
        //if adding time
        }else if addTime == true{
            endNumAdd = finalNum
            //print(endNumAdd)
            endNum = endNum + endNumAdd
            //print(endNum)
        }
        hideTimePicker()
    }
//*************************************************************************************************************************
//                  THINGS CALLED WHEN REPORT BUTTON CLICKED
//*************************************************************************************************************************
    @IBAction func onReport(sender: UIButton) {
        //instantiate alert and tell user theyre filing a report
        alert()
    }
    
//*************************************************************************************************************************
//                  METHODS CALLED ONCE DURING FIRST LOAD OF THIS VIEW
//                      alot of first creation of stuff/delegate/data source stuff
//*************************************************************************************************************************
    override func viewDidLoad() {
        super.viewDidLoad()
        self.parkingMap.delegate = self
        if tempUser == 1{
            tempUserAlert()
        }
        //autoresize fix for direction pop up menu and make menu slightly see through since its big
        dir.translatesAutoresizingMaskIntoConstraints = false
        dir.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.5)
        friendView.translatesAutoresizingMaskIntoConstraints = false
        friendView.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.5)
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        
        //startup of map selected
        Map.selected = true
        
        //aws test...don't really deal with this anymore
        //the way i do this is like this now v
        //AWSIdentityManager.defaultIdentityManager().identityId
        //let identityManager = AWSIdentityManager.defaultIdentityManager()
        //let identityUserName = identityManager.userName
    
        
        //starts up the GPS stuff for location
        //***problem****
        //how to make dot only update with MOVEMENT not every time
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest //gps
        locationManager.requestWhenInUseAuthorization()
        
        locationManager.startUpdatingLocation()
        
        //shows blue dot
        self.parkingMap.showsUserLocation = true
        
        //set-up picker
        self.picker.delegate = self
        self.picker.dataSource = self
        
        //one time populate of picker data
        for i in 0 ..< 60 {
            self.pickerDate.append( String(i)+" min")
        }
        for i in 0 ..< 24 {
            self.pickerDate2.append( String(i)+" hours")
        }
        //facebook stuff -> now linked with AWS Cognito
        if (FBSDKAccessToken.currentAccessToken() != nil){
            AWSFacebookSignInProvider.sharedInstance().setPermissions(["public_profile", "email", "user_friends"])
            //faceBookLogout.readPermissions = ["public_profile", "email", "user_friends"]
            faceBookLogout.delegate = self
        }else{
            AWSFacebookSignInProvider.sharedInstance().setPermissions(["public_profile", "email", "user_friends"])
            //faceBookLogout.readPermissions = ["public_profile", "email", "user_friends"]
            faceBookLogout.delegate = self
        }
        
        
    }
    
//*************************************************************************************************************************
//              METHODS CALLED EVERYTIME THIS MAPVIEW APPEARS
//*************************************************************************************************************************
    override func viewDidAppear(animated: Bool) {
        if tempUser == 1{
         //print("demo")
        popPatrol()
        }else{
            //print("good")
            popCar()
            popPatrol()
            //populate map is called in popPatrol (asynchronous issues if called in viewDidAppear)
            //populatePatrolMap()
        }
    }
    override func viewDidDisappear(animated: Bool) {
        tempUser = 0    //reset the tempUser checker
        FBSDKAccessToken.currentAccessToken()
        let loginManager = FBSDKLoginManager()
        loginManager.logOut() // this is an instance function
    }
//*************************************************************************************************************************
//                      SWIPE GESTURES
//*************************************************************************************************************************
    //TO CLOSE DIRECTION MENU WHEN SWIPED LEFT
    @IBAction func onCloseDir(sender: UISwipeGestureRecognizer) {
        if didDirect == true {
            hideMenuDir()
            self.direction.text = nil
            didDirect = false
        }
    }
    //TO CLOSE FRIEND MENU WHEN SWIPED Right
    @IBAction func onCloseFriend(sender: UISwipeGestureRecognizer) {
        if didFriend == true {
            hideMenuFriend()
            didFriend = false
        }
        print("right swipe")
    }
//*************************************************************************************************************************
//                              picker conforming methods
//*************************************************************************************************************************
    //two components (hours and minutes)
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 2
    }
    
    //how many rows to have in each component (.count)
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 {
            return pickerDate2.count
        }else{
            return pickerDate.count
        }
    }
    //populate the row with titles aka numbers
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component == 0 {
            return pickerDate2[row]
        }else{
            return pickerDate[row]
        }
    }
    
    //selecter method which calls helper method
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int){
            updateValue()
        
    }
    //helper method when selected
    //this converts all values to seconds for timer to use and inserts into finalnum variable
    func updateValue(){
        let hour = pickerDate2[picker.selectedRowInComponent(0)]
        let hourArray = hour.componentsSeparatedByString(" ")
        var numHour = Double(hourArray[0])
        numHour = numHour! * 3600.0
        
       
        let min = pickerDate[picker.selectedRowInComponent(1)]
        let minArray = min.componentsSeparatedByString(" ")
        var numMin = Double(minArray[0])
        numMin = numMin! * 60.0
        
        finalNum = numHour! + numMin!
        //print(finalNum)
    }
   
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
//*************************************************************************************************************************
//                      TIMER METHODS
//*************************************************************************************************************************
    //start up the timer and call the helper function (oneTimer)
    func startUpdating(){
            self.timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(ViewController.oneTimer), userInfo: nil, repeats: true)
    }
    //before had one timer to call showTravelTime and another for showMeterTime, but now one timer to call method that calls both at once
    func oneTimer(){
        showTravelTime()
        showMeterTime()
    }
    //shows travel time to get back to car
    func showTravelTime(){
        let request = MKDirectionsRequest()
        //set start location to your location
        request.source = MKMapItem.mapItemForCurrentLocation()
        
        //destination is set when car is placed
        request.destination = destination
        request.requestsAlternateRoutes = true
        
        let directions = MKDirections(request: request)
        directions.calculateETAWithCompletionHandler{ (response, error) in
            if error != nil{
                print("Could not calculate travel time.")
            }else{
                //keep updating travel time
                self.travelTime = response!.expectedTravelTime
                // print(self.travelTime)
            }
        }
    }
    //method to constantly check if alert needs to be sounded
    func showMeterTime(){
        //compare
        if endNum <= 180 || endNum <= (travelTime + 180.0){
            //if statement needed so this alert isnt called every second (once called once, never call again)
            if alertWalk1 == false{
                alertWalk1 = true
                alertWalkOut()
            }
        }
       //call alert that meter expired
        if endNum == 0.0 {
            alertExpire()
            timer.invalidate()
            didMeter = false
            addTime = false
        }
        //subtract and repeat
        endNum = endNum - 1.0
        //print(endNum)
    }
//*************************************************************************************************************************
//                      BUTTON CLICKED FUNCTIONS
//*************************************************************************************************************************
    //when park button is clicked
    @IBAction func onPark(sender: UIButton) {
        //every time park button clicked, reset the start position of picker to 0 hours and 0 minutes
        self.picker.selectRow(0, inComponent: 1, animated: false)
        self.picker.selectRow(0, inComponent: 0, animated: false)
        
        //if car is not parked yet
        if didPark == false {
            
            //this is the code required to drop a pin
            mapAnnotationCar = ColorPointAnnotation()
            mapAnnotationCar.coordinate = locationManager.location!.coordinate
            mapAnnotationCar.title = "My Car"
            mapAnnotationCar.imageName = "car.png"
            parkingMap.addAnnotation(mapAnnotationCar)
            alertMeter()        //ask if user parked at meter
            //this allows car to show even when app is killed and restarted (MAKE SURE ADDED IN VIEWDIDAPPEAR METHOD
            let placeMark = MKPlacemark(coordinate: mapAnnotationCar.coordinate, addressDictionary: nil)
            destination = MKMapItem(placemark: placeMark)
            didPark = true      //now car is parked
            if tempUser == 0{
            lat = mapAnnotationCar.coordinate.latitude     //add coordinates to global variables
            long = mapAnnotationCar.coordinate.longitude
            
            //hard coded dynamoDB Query for userID (aka find user settings)
            let objectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
            let queryExpression = AWSDynamoDBQueryExpression()
            queryExpression.keyConditionExpression = "#userId = :userId"
            queryExpression.expressionAttributeNames = ["#userId": "userId"]
            queryExpression.expressionAttributeValues = [":userId": AWSIdentityManager.defaultIdentityManager().identityId!,]
            objectMapper.query(UserData.self, expression: queryExpression){ (response: AWSDynamoDBPaginatedOutput?, error: NSError?) -> Void in
                if error != nil {
                    print("User profile could not be found.")
                }else{
                    let output = response
                    //update the user settings so the new coordinates of your car are pushed to database and saved
                    UserDataTable().updateItem((output?.items[0])!, completionHandler: { (error) in
                        if error != nil {
                            print("The location of your car could not be saved to your user settings.")
                        }
                    })
                }
            }
        }
        }else{
            //prompt user for specific options now that car is parked
            alertPark(mapAnnotationCar)
        }
    }
    
    //simple toggle between satellite map and normal apple map
    //****idea maybe have 3D map option at some point***
    @IBAction func onMap(sender: UIButton) {
        if Map.selected == true {
            Map.setTitle("Normal Map", forState: UIControlState.Normal)
            parkingMap.mapType = MKMapType.Satellite
            Map.selected = false
        }else if Map.selected == false{
            Map.setTitle("Satellite Map", forState: UIControlState.Normal)
            parkingMap.mapType = MKMapType.Standard
            Map.selected = true
        }
    }
//*************************************************************************************************************************
//                              ALERTS (YES THERES A TON OF THEM -______-)
//                              learned a new way to create just one alert and add custom messages to alert but
//                              learned that after all these were created
//*************************************************************************************************************************
    func alertLook(){
        let alert = UIAlertController(title: "", message:"To have location pulled back to yourself, double tap on screen with two fingers", preferredStyle: UIAlertControllerStyle.Alert)
        //add ok
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }

    func tempUserAlert(){
        let alert = UIAlertController(title: "Guest Access", message:"You're logged in as a guest, in order to sync your account with multiple devices, sign in with Facebook", preferredStyle: UIAlertControllerStyle.Alert)
        //add ok
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    //doesn't usually happen but take care of this case where user cant be authenticated
    func alertUserAuthenticate(){
        let alert = UIAlertController(title: "User Authentication Error", message:"Sorry, error finding your account please try logging in again", preferredStyle: UIAlertControllerStyle.Alert)
        //add ok
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    //alert function for when user should head back to car
    func alertWalkOut(){
        let alert = UIAlertController(title: "Time to Walk Back", message: "based on your location you have just enough time to walk back and pay for your meter", preferredStyle: UIAlertControllerStyle.Alert)
        //add simple ok button
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    //alert function saying meter is expired
    func alertExpire(){
        let alert = UIAlertController(title: "Uh-Oh", message: "Your meter has expired", preferredStyle: UIAlertControllerStyle.Alert)
        //add simple ok button
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    //function asking user if they parked at a meter
    func alertMeter(){
        let alert = UIAlertController(title: "Did you park at a meter?", message: "If so enter the time you reserved", preferredStyle: UIAlertControllerStyle.Alert)
        //add yes button
        alert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.Default, handler: {
            action in
            self.showTimePicker()       //action to show the pickerview
        }))
        //add simple no button
        alert.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    //alert telling user you are about to report a patrol
    func alert(){
        let alert = UIAlertController(title: "Report Patrol", message: "You are about to file a report", preferredStyle: UIAlertControllerStyle.Alert)
        //add continue button
        alert.addAction(UIAlertAction(title: "Continue", style: UIAlertActionStyle.Default, handler: {
            action in
            //action to drop pin (call helper function)
            self.addPatrol()
        }))
        //add simple cancel button
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    //alert function if car is already parked
    func alertPark(pin: MKPointAnnotation){
        let parkAlert = UIAlertController(title: "Already Parked!", message: "You have already placed down a parked pin", preferredStyle: UIAlertControllerStyle.Alert)
        //if you want to get back to car
        parkAlert.addAction(UIAlertAction(title: "Directions to car", style: UIAlertActionStyle.Default, handler: {
           action in
            //if the menu is already showing then refresh directions
            if(self.didDirect == true){
                self.direction.text = nil
                self.showDirection()
            }else{
                self.didDirect = true
                //self.showTravelTime()   //used for debugging
                self.showDirection()    //text box of directions
                self.showMenuDir()  //actually tannish popup menu
            }
        }))
        parkAlert.addAction(UIAlertAction(title: "Remove Pin", style: UIAlertActionStyle.Default, handler:{
           action in
            //set database locations to default aka no car parked
            
            self.parkingMap.removeAnnotation(pin)
            print("done")
            
            if tempUser == 0{
            lat = 30
            long = 160
            //hardcode dynamoDB query for userID
            let objectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
            let queryExpression = AWSDynamoDBQueryExpression()
            queryExpression.keyConditionExpression = "#userId = :userId"
            queryExpression.expressionAttributeNames = ["#userId": "userId"]
            queryExpression.expressionAttributeValues = [":userId": AWSIdentityManager.defaultIdentityManager().identityId!,]
            objectMapper.query(UserData.self, expression: queryExpression){ (response: AWSDynamoDBPaginatedOutput?, error: NSError?) -> Void in
                if error != nil {
                    print("User profile could not be found.")
                }else{
                    let output = response
                    UserDataTable().updateItem((output?.items[0])!, completionHandler: { (error) in
                        if error != nil {
                            print("The location of your car could not be saved to your user settings.")
                        }
                    })
                }
            }
            }
            //upkeep stuff
            self.timer.invalidate()
            self.addTime = false
            self.didDirect = false
            self.alertWalk1 = false
            self.direction.text = nil
            self.hideMenuDir()
            self.didPark = false
            self.didMeter = false
        }))
        //if you did park, show the option to add more time
        if didMeter == true{
            parkAlert.addAction(UIAlertAction(title: "Add More Time to Meter", style: UIAlertActionStyle.Default, handler:{
               action in
                self.showTimePicker()
                self.addTime = true
            }))
        }
        parkAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(parkAlert, animated: true, completion: nil)
    }
//*************************************************************************************************************************
//                                      LOCATION MANAGER SETUP
//                          figure out how to not constantly update, instead update when user moves
//*************************************************************************************************************************
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last       //gets last location from locations being passed in
        
        //gets center of that last location
        center = CLLocationCoordinate2D(latitude: location!.coordinate.latitude, longitude: location!.coordinate.longitude)
        
        //create region aka circle we want map to zoom to MKCoordinate span IS that circle
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        
        //set map view to that region
        self.parkingMap.setRegion(region, animated: true)
        
        //stop update the location
        //self.locationManager.stopUpdatingLocation()
    }
//*************************************************************************************************************************
//                                  METHOD TO SHOW PRINT OF DIRECTIONS
//*************************************************************************************************************************
    func showDirection(){
        let request = MKDirectionsRequest()     //create request
        request.source = MKMapItem.mapItemForCurrentLocation()  //start at user location
        
        request.destination = destination       //destination should be set at YOUR car
        request.requestsAlternateRoutes = true
        
        let directions = MKDirections(request: request)     //this is call for directions
        
        directions.calculateDirectionsWithCompletionHandler { (response, error) -> Void in
            
            if error != nil {
                print("Directions could not be calculated at this time")
            }else{
                
                //var overlays = self.parkingMap.overlays   get an overlay!
                //self.parkingMap.removeOverlays(overlays)
                
                for route in response!.routes {
                    
                    //self.parkingMap.addOverlay(route.polyline, level: MKOverlayLevel.AboveRoads)
                    
                    for next in route.steps{
                        //print(next.instructions)
                        //this adds to direction textbox
                        self.direction.text = self.direction.text + next.instructions
                        self.direction.text = self.direction.text + "\n\n"
                    }
                }
               // mapView(parkingMap, rendererForOverlay: )
            }
        }
    }
//*************************************************************************************************************************
//                              METHODS FOR POPUP MENUS AND SIZING
//*************************************************************************************************************************
    //showing direction menu
    func showMenuDir(){
        view.addSubview(dir)
        
        let bottomConstraint = dir.bottomAnchor.constraintEqualToAnchor(bottomMenu.topAnchor)
        let topConstraint = dir.topAnchor.constraintEqualToAnchor(parkingMap.topAnchor)
        let leftConstraint = dir.leftAnchor.constraintEqualToAnchor(parkingMap.leftAnchor)
        let rightConstraint = dir.rightAnchor.constraintEqualToAnchor(Park.rightAnchor)
        
        NSLayoutConstraint.activateConstraints([bottomConstraint, topConstraint, leftConstraint, rightConstraint])
        
        view.layoutIfNeeded()
        
        //animate
        self.dir.alpha = 0
        UIView.animateWithDuration(0.5){
            self.dir.alpha = 1.0
        }
        
    }
    //hide direction menu
    func hideMenuDir(){
        UIView.animateWithDuration(0.4, animations: {
            self.dir.alpha = 0
            }) { completed in
                if completed == true{
                    self.dir.removeFromSuperview()
                }
        }
    }
    //show friendView
    func showMenuFriend(){
        view.addSubview(friendView)
        
        let bottomConstraint = friendView.bottomAnchor.constraintEqualToAnchor(bottomMenu.topAnchor)
        let topConstraint = friendView.topAnchor.constraintEqualToAnchor(parkingMap.topAnchor)
        let leftConstraint = friendView.leftAnchor.constraintEqualToAnchor(Park.leftAnchor)
        let rightConstraint = friendView.rightAnchor.constraintEqualToAnchor(parkingMap.rightAnchor)
        
        NSLayoutConstraint.activateConstraints([bottomConstraint, topConstraint, leftConstraint, rightConstraint])
        
        view.layoutIfNeeded()
        
        //animate
        self.friendView.alpha = 0
        UIView.animateWithDuration(0.5){
            self.friendView.alpha = 1.0
        }
        
    }
    //hide direction menu
    func hideMenuFriend(){
        UIView.animateWithDuration(0.4, animations: {
            self.friendView.alpha = 0
        }) { completed in
            if completed == true{
                self.friendView.removeFromSuperview()
            }
        }
    }
    //show meter time picker
    func showTimePicker(){
        view.addSubview(pickerView)
        
        let bottomConstraint = pickerView.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor)
        let topConstraint = pickerView.heightAnchor.constraintEqualToConstant(150)
        let leftConstraint = pickerView.leftAnchor.constraintEqualToAnchor(view.leftAnchor)
        let rightConstraint = pickerView.rightAnchor.constraintEqualToAnchor(view.rightAnchor)
        
        NSLayoutConstraint.activateConstraints([bottomConstraint, topConstraint, leftConstraint, rightConstraint])
        
        view.layoutIfNeeded()
        
        //animate
        self.pickerView.alpha = 0
        UIView.animateWithDuration(0.5){
            self.pickerView.alpha = 1.0
        }
    }
    //hide meter time picker
    func hideTimePicker(){
        UIView.animateWithDuration(0.4, animations: {
            self.pickerView.alpha = 0
            }) { completed in
                if completed == true{
                    self.pickerView.removeFromSuperview()
                }
        }
    }
//*************************************************************************************************************************
//                                      MAP VIEW DELEGATE
//                            main use of this is to set custom annotations
//*************************************************************************************************************************
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if !(annotation is ColorPointAnnotation){
            return nil
        }
        let reuseId = "test"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId)
        if pinView == nil {
            pinView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            //for just change in color
            //pinView?.pinTintColor = ColorPointAnnotation.pinColor
        }else{
            pinView?.annotation = annotation
        }
        let cpa = annotation as! ColorPointAnnotation
        pinView!.image = UIImage(named: cpa.imageName)
        
        return pinView
    }
//*************************************************************************************************************************
//                                                  HELPER FUNCTIONS
//*************************************************************************************************************************
    func addPatrol(){
        self.mapAnnotation = ColorPointAnnotation()
        self.mapAnnotation.coordinate = self.locationManager.location!.coordinate
        self.mapAnnotation.title = "Police"
        self.mapAnnotation.imageName = "siren.png"
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd h:mm:ss"
        let timeOfPatrol = NSDate()
        let stimeOfPatrol = dateFormatter.stringFromDate(timeOfPatrol)
        self.parkingMap.addAnnotation(self.mapAnnotation)
        
        //set globals
        patrolLat = mapAnnotation.coordinate.latitude
        patrolLong = mapAnnotation.coordinate.longitude
        timeStamp = stimeOfPatrol
        
        if tempUser == 0{
        //add to DynamoDB
        PatrolsTable().insertSampleDataWithCompletionHandler { (errors) in
            if errors != nil{
                print("Patrol could not be added to community database")
            }else{
                print("patrol was added")
            }
        }
        }
    }
    func populatePatrolMap(){
        var z = 0
            PatrolsTable().scanWithCompletionHandler { (response, error) in
                if error != nil {
                    print("no patrols in table")
                }else{
                    let output = response
                    if output!.items.count == 0{
                        print("no patrols exist")
                    }else{

                        while z < output!.items.count {
                            //print("1111111111111111111111111111111111111")
                            //print("hi")
                            //print(coordinateArrLat[z])
                            //print(coordinateArrLong[z])
                            self.mapAnnotation = ColorPointAnnotation()
                            //cast is needed from NSNumber (DynamoDB to Double which is CLLCoordinate type)
                            self.mapAnnotation.coordinate.latitude = coordinateArrLat[z]
                            self.mapAnnotation.coordinate.longitude = coordinateArrLong[z]
                            self.mapAnnotation.title = "Police"
                            self.mapAnnotation.imageName = "siren.png"
                            //print(z)
                            //print(self.mapAnnotation.coordinate)
                            self.parkingMap.addAnnotation(self.mapAnnotation)
                            //print("1111111111111111111111111111111111111")
                            z = z+1
                        }
                    }
                }
            }
        
        }
    
    //bug check this!!!!! and add time checks to delete (eventually have time checks occur server side)
    //have to call populate Patrol map in this method due to async issues.
    func popPatrol(){
            PatrolsTable().scanWithCompletionHandler { (response, error) in
                if error != nil {
                    print("no patrols in table")
                }else{
                    let output = response
                    if output!.items.count == 0{
                        print("no patrols exist")
                    }else{
                        PatrolsTable().updateMap((output?.items[0])!, completionHandler:  { (error) in
                            if error != nil{
                                print("Could not populate from patrol DB.")
                            }else{
                                print("it worked")
                            }
                            self.populatePatrolMap() //enclose in completion handler not outside or else array not populated correctly
                        })
            
                    }
                }
            }
        

    }
    func popCar(){
        if tempUser == 0{
            UserDataTable().scanWithFilterWithCompletionHandler { (response, error) in
                if error != nil{
                    print("username does not exist in table")
                }else{
                    let output = response
                    UserDataTable().updateMap((output?.items[0])!, completionHandler: { (error) in
                        if error != nil{
                            print("Could not populate from user settings.")
                        }else{
                            if(lat != 30 && long != 160){
                                self.mapAnnotationCar = ColorPointAnnotation()
                                //cast is needed from NSNumber (DynamoDB to Double which is CLLCoordinate type)
                                self.mapAnnotationCar.coordinate.latitude = lat as Double
                                self.mapAnnotationCar.coordinate.longitude = long as Double
                                self.mapAnnotationCar.title = "My Car"
                                self.mapAnnotationCar.imageName = "car.png"
                                //print(self.mapAnnotationCar.coordinate)
                                self.parkingMap.addAnnotation(self.mapAnnotationCar)
                                //this placemark creation and adding as destination is so you can both create directions and traveltime
                                let placeMark = MKPlacemark(coordinate: self.mapAnnotationCar.coordinate, addressDictionary: nil)
                                self.destination = MKMapItem(placemark: placeMark)
                                self.didPark = true
                            }else{
                                print("no car")
                            }
                        }
                    })
                }
            }
        }
    }
//*************************************************************************************************************************
//                                                  FACEBOOKBUTTON DELEGATES
//*************************************************************************************************************************
    //login (for this view the login button should NEVER be used)
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        //print("User Logged In")
        
        if ((error) != nil){
            print("Problem logging user in")
        }else if result.isCancelled {
            // Handle cancellations
            print("access is cancelled")
        }else {
            if result.grantedPermissions.contains("email"){
            }
        }
    }
    //should always show log out
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        let nextViewController = storyBoard.instantiateViewControllerWithIdentifier("Login") as? LoginViewController
        self.presentViewController(nextViewController!, animated:true, completion:nil)
        //print("User Logged out")
    }
}
