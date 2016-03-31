//
//  ViewController.swift
//  TimShop
//
//  Created by Cloud on 2016/3/29.
//  Copyright © 2016年 TimCircle. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController,CLLocationManagerDelegate,UITableViewDelegate,UITableViewDataSource{
    
    @IBOutlet weak var tableView: UITableView!
    
    var locationManager : CLLocationManager!
    
    var shops = [Shop]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "提姆購"
        
        tableView.delegate = self
        tableView.dataSource = self
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Refresh, target: self, action: "Reload")
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(animated: Bool) {
        locationManager.startUpdatingLocation()
    }
    
    override func viewDidDisappear(animated: Bool) {
        locationManager.stopUpdatingLocation()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func Reload(){
        
        self.shops = [Shop]()
        
        self.tableView.reloadData()
        
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
        
        locationManager.stopUpdatingLocation()
        
        if locations.count > 0{
            
            let latitude = locations[0].coordinate.latitude
            
            let longitude = locations[0].coordinate.longitude
            
            let url = NSURL(string: "http://dev.timcircle.com:8080/banana/timshop/public/nearby?ll=\(latitude),\(longitude)")!
            
            let request = NSURLRequest(URL: url)
            
            NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {(response, data, error) in
                
                print(NSString(data: data!, encoding: NSUTF8StringEncoding))
                
                var datas = [Shop]()
                
                let jsons = JSON(data:data!)
                
                for (_,json) in jsons{
                    
                    let title = json["title"].stringValue
                    
                    let display = json["address"]["display"].stringValue
                    
                    let phone_number = json["phone_number"].stringValue
                    
                    let distance = json["distance"].stringValue
                    
                    let photos = json["photos"].arrayValue
                    
                    var urls = [String]()
                    
                    for photo in photos{
                        urls.append(photo.stringValue)
                    }
                    
                    let shop = Shop(Photos: urls, Name: title, Address: display, PhoneNumber: phone_number, Distance: distance)
                    
                    datas.append(shop)
                }
                
                self.shops = datas
                
                self.tableView.reloadData()
                
            }
        }
        
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError){
        print("error = \(error)")
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
    
        return shops.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        
        let shop = shops[indexPath.row]
        
        let cell = tableView.dequeueReusableCellWithIdentifier("ShopCell") as! ShopCell
        
        cell.Name.text = shop.Name
        
        cell.Address.text = shop.Address
        
        cell.PhoneNumber.text = shop.PhoneNumber
        
        cell.Distance.text = shop.Distance + " m"
        
        cell.Photo.image = shop.Photo
        
        if shop.Photo == nil {
            
            shop.UpdatePhoto({ () -> () in
                
                if let tempCell = tableView.cellForRowAtIndexPath(indexPath) as? ShopCell{
                    
                    tempCell.Photo.image = shop.Photo
                    
                    //tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                }
            })
        }
        
        return cell
    }
}

class Shop {
    
    static let DefaultIcon = UIImage(named: "Shop-48.png")
    
    var Photo : UIImage?
    
    var Photos : [String]
    
    var Name : String
    
    var Address : String
    
    var PhoneNumber : String
    
    var Distance : String
    
    init(Photos:[String],Name:String,Address:String,PhoneNumber:String,Distance:String){
        
        self.Photo = nil
        
        self.Photos = Photos
        
        self.Name = Name
        
        self.Address = Address
        
        self.PhoneNumber = PhoneNumber
        
        self.Distance = Distance
    }
    
    func UpdatePhoto(callback:(() -> ())){
        
        self.Photo = Shop.DefaultIcon
        
        dispatch_async(dispatch_get_main_queue(), {
        
            if self.Photos.count > 0 {
                
                let url = NSURL(string: self.Photos[0])!
                
                let request = NSURLRequest(URL: url)
                
                NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {(response, data, error) in
                    
                    if let img_data = data , let img = UIImage(data: img_data){
                        
                        self.Photo = img
                    }
                    
                    callback()
                }
            }
            else{
                
                callback()
            }
        })
    }
}

