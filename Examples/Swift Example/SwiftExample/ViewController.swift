//
//  ViewController.swift
//  SwiftExample
//
//  Created by Nick Lockwood on 30/07/2014.
//  Copyright (c) 2014 Charcoal Design. All rights reserved.
//

import UIKit

class ViewController: UIViewController, iCarouselDataSource, iCarouselDelegate {
    
    var items: [Int] = []
    @IBOutlet var carousel : iCarousel!
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        for i in 0...99
        {
            items.append(i)
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        carousel.type = .CoverFlow2
    }
    
    func numberOfItemsInCarousel(carousel: iCarousel!) -> Int
    {
        return items.count
    }
    
    
    @objc func carousel(carousel: iCarousel!, viewForItemAtIndex index: Int, reusingView view: UIView!) -> UIView!
    {
        var label: UILabel! = nil
        var newView = view
        
        //create new view if no view is available for recycling
        if (newView == nil)
        {
            //don't do anything specific to the index within
            //this `if (view == nil) {...}` statement because the view will be
            //recycled and used with other index values later
            newView = UIImageView(frame:CGRectMake(0, 0, 200, 200))
            (newView as! UIImageView!).image = UIImage(named: "page.png")
            newView.contentMode = .Center
            
            label = UILabel(frame:newView.bounds)
            label.backgroundColor = UIColor.clearColor()
            label.textAlignment = .Center
            label.font = label.font.fontWithSize(50)
            label.tag = 1
            newView.addSubview(label)
            
            var button:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
            button.frame = CGRectMake(0, 0, 200, 200)
            
            button.addTarget(self, action: "buttonTapped:", forControlEvents: UIControlEvents.TouchUpInside)
            
            newView.addSubview(button)
            newView.userInteractionEnabled = true
        }
        else
        {
            //get a reference to the label in the recycled view
            label = newView.viewWithTag(1) as! UILabel!
        }
        
        //set item label
        //remember to always set any properties of your carousel item
        //views outside of the `if (view == nil) {...}` check otherwise
        //you'll get weird issues with carousel item content appearing
        //in the wrong place in the carousel
        label.text = "\(items[index])"
        
        return newView
    }
    
    func carousel(carousel: iCarousel!, valueForOption option: iCarouselOption, withDefault value: CGFloat) -> CGFloat
    {
        if (option == .Spacing)
        {
            return value * 1.1
        }
        return value
    }
    
    func buttonTapped(sender: UIButton!) {
        let index = carousel.indexOfItemViewOrSubview(sender)
        
        let alert = UIAlertController(title: nil, message: "You tapped: " + String(index), preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }

}

