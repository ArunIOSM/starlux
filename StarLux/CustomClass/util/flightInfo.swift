
import Foundation

class flightInfo {
    
    var flightName: String?
    var flightCode: String?
    var ETATime :  String?
    var ETDTime : String?
    var flightDate: String?
    var flightScheduleStatus: String?
    var flightTAT: String?
    var flightStatus: String?
    var flightCurrentActivity: String?
    var flightBlockTime: String?
    
    init(flightName: String, flightDate: String, flightScheduleStatus: String,flightTAT: String,flightStatus: String, flightCurrentActivity: String, flightCode : String, ETATime : String, ETDTime: String, flightBlockTime : String){
     
        self.flightName = flightName
        self.ETATime = ETATime
        self.ETDTime = ETDTime
        self.flightCode = flightCode
        self.flightDate = flightDate
        self.flightScheduleStatus = flightScheduleStatus
        self.flightTAT = flightTAT
        self.flightStatus = flightStatus
        self.flightCurrentActivity = flightCurrentActivity
        self.flightBlockTime = flightBlockTime
    }
    
}

