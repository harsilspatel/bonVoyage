//
//  CalendarViewController.swift
//  bon-voyage
//
//  Created by Harsil Patel on 9/5/19.
//  Copyright © 2019 Harsil Patel. All rights reserved.
//

import UIKit
import Firebase
import CalendarKit
import DateToolsSwift

class CalendarViewController: DayViewController, AddEventDelegate {
    
    
    let dateFormat = "yyyy-MM-dd HH:mm:ss"
    var user = "test"
    var trip: String = ""
    
    var raw_events_ref: DatabaseReference?
    
//    var raw_events: Array<Dictionary<String, Any>>?
    
    var raw_events = [["description": ["Breakfast at Tiffany's", "New York, 5th avenue"],
                 "start": "2019-05-30 14:00:00",
                 "duration": 60],
                
                ["description": ["Workout", "Tufteparken"],
                 "start": "2019-05-30 8:00:00",
                 "duration": 90],
                
                ["description": ["Meeting with Alex",
                                 "Home",
                                 "Oslo, Tjuvholmen"],
                 "start": "2019-05-31 18:30:00",
                 "duration": 60],
                
                ["description": ["Beach Volleyball",
                                 "Ipanema Beach",
                                 "Rio De Janeiro"],
                 "start": "2019-05-29 13:30:00",
                 "duration": 120],
                
                ["description": ["WWDC",
                                 "Moscone West Convention Center",
                                 "747 Howard St"],
                 "start": "2019-05-30 17:00:00",
                 "duration": 90],
                
                ["description": ["Google I/O",
                                 "Shoreline Amphitheatre",
                                 "One Amphitheatre Parkway"],
                 "start": "2019-05-29 12:00:00",
                 "duration": 120],
                
                ["description": ["Software Development Lecture",
                                 "Mikpoli MB310",
                                 "Craig Federighi"],
                 "start": "2019-05-31 14:00:00",
                 "duration": 60],
    ]
    
    var colors = [UIColor.blue,
                  UIColor.yellow,
                  UIColor.green,
                  UIColor.red]
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        let raw_events_ref = Database.database().reference().child("users").child(user).child("trips").child(trip).child("events")
        print(trip)
        print("before prep")
        self.prepareData()
        print("after prep")
        
        self.navigationItem.title = trip

        reloadData()
    }
    
    func prepareData() {
        print("inside prepdata")
        self.raw_events_ref?.observe(.childChanged, with: { snapshot in
            print("snappppy")
            print(snapshot)
            if let raw_events_snapshot = snapshot.value as? Array<Dictionary<String, Any>> {
                self.raw_events = raw_events_snapshot
            }
            self.reloadData()
        })
        print("finishing prepdata")

    }
    
//    func observe
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "addEventSegue" {
            let destination = segue.destination as! AddEventViewController
            destination.addEventDelegate = self
        }
    }
    
    override func eventsForDate(_ date: Date) -> [EventDescriptor] {
        var events = [Event]()
        
        for iterator in raw_events.indices {
            let raw_event = raw_events[iterator]
            let event = Event()
            let duration = raw_event["duration"] as! Int
            let datePeriod = TimePeriod(beginning: self.stringToDate(raw_event["start"] as! String),
                                        chunk: TimeChunk.dateComponents(minutes: duration))
            
            event.startDate = datePeriod.beginning!
            event.endDate = datePeriod.end!
            
            var info = raw_event["description"] as! [String]
            
            let timezone = TimeZone.ReferenceType.default
            info.append(datePeriod.beginning!.format(with: "dd.MM.YYYY", timeZone: timezone))
            info.append("\(datePeriod.beginning!.format(with: "HH:mm", timeZone: timezone)) - \(datePeriod.end!.format(with: "HH:mm", timeZone: timezone))")
            event.text = info.reduce("", {$0 + $1 + "\n"})
            event.color = colors[Int(arc4random_uniform(UInt32(colors.count)))]
            event.isAllDay = false
            
            events.append(event)
            
            event.userInfo = iterator
        }
        print("returning the eventsForDate")
        return events
    }
    
    override func dayViewDidSelectEventView(_ eventView: EventView) {
        guard let descriptor = eventView.descriptor as? Event else {
            return
        }
        print("Event has been selected: \(descriptor) \(String(describing: descriptor.userInfo))")
    }
    
    override func dayViewDidLongPressEventView(_ eventView: EventView) {
        guard let descriptor = eventView.descriptor as? Event else {
            return
        }
//        raw_events.remove(at: descriptor.userInfo! as! Int)
        self.showAlertWithDistructiveButton(index: descriptor.userInfo! as! Int)
        print("Event has been longPressed: \(descriptor) \(String(describing: descriptor.userInfo))")
    }
    
    func showAlertWithDistructiveButton(index: Int) {
        let alert = UIAlertController(title: "Delete?", message: "Are you sure you want to delete", preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler: { _ in
            //Cancel Action
        }))
        alert.addAction(UIAlertAction(title: "Delete",
                                      style: UIAlertAction.Style.destructive,
                                      handler: {(_: UIAlertAction!) in
                                        self.raw_events.remove(at: index)
                                        self.reloadData()

        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    override func dayView(dayView: DayView, willMoveTo date: Date) {
        print("DayView = \(dayView) will move to: \(date)")
    }
    
    override func dayView(dayView: DayView, didMoveTo date: Date) {
        print("DayView = \(dayView) did move to: \(date)")
    }
    
    @IBAction func openChatView(_ sender: Any) {
        let user = Auth.auth().currentUser!
        let channel = Channel(name: self.trip, id: self.trip)
        let chatVC = ChatViewController(user: user, channel: channel)
        navigationController?.pushViewController(chatVC, animated: true)
    }
    
    func dateToString(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        return dateFormatter.string(from: date)
    }
    
    func stringToDate(_ string: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        return dateFormatter.date(from: string)!
    }
    
    func addEvent(newEvent: Dictionary<String, Any>) -> Bool {
        raw_events.append(newEvent)
        self.reloadData()
        return true
    }
    
}
