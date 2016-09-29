//
//  LoginViewController.swift
//  ParkApp
//
//  Created by Michael Bharrat on 7/22/16.
//  Copyright © 2016 Michael Bharrat. All rights reserved.
//

import UIKit
import AWSMobileHubHelper
import AWSCore
import AWSDynamoDB

//*************************************************************************************************************************
//                                  SET STORYBOARD TO VARIABLE FOR USE IN SCENE SWITCH
//*************************************************************************************************************************
let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
var tempUser = 0
class LoginViewController: UIViewController, UITextFieldDelegate, FBSDKLoginButtonDelegate {
    
//*************************************************************************************************************************
//                                              VARIABLES
//*************************************************************************************************************************
    @IBOutlet weak var faceBookLogin: FBSDKLoginButton!     //facebook login button
//*************************************************************************************************************************
//                                                  WHEN LOGIN VIEW FIRST LOADS
//                                      all delegate/datasource/one time set up code
//*************************************************************************************************************************
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "back.png")!)  //set background image
        
        
        //facebook login stuff
        //just use storyboard stuff now
        //make sure you set delegate to both cases even if in theory both cases wont show up!
        //adapted to AWS Cognito to set permissions
        AWSFacebookSignInProvider.sharedInstance().setPermissions(["public_profile", "email", "user_friends"])
        faceBookLogin.delegate = self
        AWSFacebookSignInProvider.sharedInstance().setLoginBehavior(FBSDKLoginBehavior.Web.rawValue)
        
        //aws test
        //let identityManager = AWSIdentityManager.defaultIdentityManager()
        //let identityUserName = identityManager.userName
        
       // let userId = identityManager.identityId
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
//*************************************************************************************************************************
//                                              EVERY TIME VIEW APPEARS
//*************************************************************************************************************************
    //just over ride and always log out when window is eliminated (security feauture)
    override func viewDidAppear(animated: Bool) {
        /*
        if (FBSDKAccessToken.currentAccessToken() != nil){     //if the access token exists just go to the main storyboard
            let nextViewController = storyBoard.instantiateViewControllerWithIdentifier("viewMain") as? UINavigationController
            self.presentViewController(nextViewController!, animated:true, completion:nil)
        }
 */
        //aws test
        //let identityManager = AWSIdentityManager.defaultIdentityManager()
        //let identityUserName = identityManager.userName
        //print("bye")
        //print(identityUserName)
        
        //let userId = identityManager.identityId
        //print(userId)
    }
//*************************************************************************************************************************
//                                          LOCAL CUSTOM LOGIN HANDLER (ADAPT TO COGNITO)
//*************************************************************************************************************************
    //allow temporary guest functionality
    @IBAction func onLogin(sender: UIButton) {
        tempUser = 1
        let nextViewController = storyBoard.instantiateViewControllerWithIdentifier("viewMain") as? UINavigationController
        self.presentViewController(nextViewController!, animated:true, completion:nil)
        //alert()
    }
    
//*************************************************************************************************************************
//                                                ALERTS
//*************************************************************************************************************************
  

    //now never used b/c no keyboard
//*************************************************************************************************************************
//                                          ELEGANT KEYBOARD INTERFACES
//*************************************************************************************************************************
    //when clicked away from keyboard, close keyboard
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }
    //textFieldDelegate (when return is hit)
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder();
        return true
    }
//*************************************************************************************************************************
//                                                 FACEBOOK DELEGATE METHODS
//*************************************************************************************************************************
    //when login
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        print("User Logged In")
        //loading.startAnimating()    //work on this
        print("load start")
        
        handleLoginWithSignInProvider(AWSFacebookSignInProvider.sharedInstance())   //helper function for facebookSDK to link with AWS
        //loading.stopAnimating()     //work on this
        print("load end")
        
    }
    //this should never be seen
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        print("logOut")
    }
    
    //extra method to grab user facebook data
    func returnUserData(){
        let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: nil)
        graphRequest.startWithCompletionHandler({ (connection, result, error) -> Void in
            
            if ((error) != nil){
                // Process error
                print("Couldn't grab data.")
            }else{
                print("fetched user: \(result)")
                let userName : NSString = result.valueForKey("name") as! NSString
               print("User Name is: \(userName)")
                let userEmail : NSString = result.valueForKey("email") as! NSString
               print("User Email is: \(userEmail)")
            }
        })
    }
    func handleLoginWithSignInProvider(signInProvider: AWSSignInProvider) {
        AWSIdentityManager.defaultIdentityManager().loginWithSignInProvider(signInProvider, completionHandler: {(result: AnyObject?, error: NSError?) -> Void in
            if error == nil {
                let objectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
                let queryExpression = AWSDynamoDBQueryExpression()
                queryExpression.keyConditionExpression = "#userId = :userId"
                queryExpression.expressionAttributeNames = ["#userId": "userId"]
                queryExpression.expressionAttributeValues = [":userId": AWSIdentityManager.defaultIdentityManager().identityId!,]
                objectMapper.query(UserData.self, expression: queryExpression){ (response: AWSDynamoDBPaginatedOutput?, error: NSError?) -> Void in
                    if error != nil {
                        print("User data could not be retrieved")
                    }else{
                        let output = response
                        if output!.items.count != 0{
                            print("the user exists already")
                            print(UserDataTable().getItemDescription())
                            print(AWSIdentityManager.defaultIdentityManager().identityId)
                        }else{
                            print("the user does not exist")
                            UserDataTable().insertSampleDataWithCompletionHandler({(errors: [NSError]?) -> Void in
                                if error != nil {
                                    print("Username could not be added")
                                }else{
                                    print(UserDataTable().getItemDescription())
                                    print(AWSIdentityManager.defaultIdentityManager().identityId)
                                }
                            })
                        }
                    }
                }
                
                let nextViewController = storyBoard.instantiateViewControllerWithIdentifier("viewMain") as? UINavigationController
                self.presentViewController(nextViewController!, animated:true, completion:nil)
            }
        })
    }
}
