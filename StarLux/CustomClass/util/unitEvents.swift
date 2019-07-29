

import UIKit

class unitEvents: NSObject {
    
    var unitEvent: String?
    var eventETA: String?
    var eventStartTime: String?
    var eventEndTime: String?
    var eventProgressTime: String?
    var eventStatus: String?
    var eventRunningStatus: String?
    
    init(unitEvent: String, eventETA: String, eventStartTime: String,eventEndTime: String,eventProgressTime: String, eventStatus: String, eventRunningStatus: String){
        self.unitEvent = unitEvent
        self.eventETA = eventETA
        self.eventStartTime = eventStartTime
        self.eventEndTime = eventEndTime
        self.eventProgressTime = eventProgressTime
        self.eventStatus = eventStatus
        self.eventRunningStatus = eventRunningStatus
    }
    
}
