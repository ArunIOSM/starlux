

import UIKit

class userGroupMember: NSObject {
    
    var unitMembername: String?
    var unitid: String?
    var unitname: String?
    var unitmemberid: String?
    
    init(unitMembername: String, unitid: String, unitname: String, unitmemberid: String){
        self.unitMembername = unitMembername
        self.unitid = unitid
        self.unitname = unitname
        self.unitmemberid = unitmemberid
    }
    
}

