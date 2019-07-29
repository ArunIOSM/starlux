
//

import UIKit
import UserNotifications
import SQLite3

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UNUserNotificationCenterDelegate {
    
    @IBOutlet var tblView : STCollapseTableView!
    @IBOutlet var titleBarButton : UIBarButtonItem!
    var selectedSegmentSection: Int! = -1
    var prevHeader : UIView?
    var unitId : String?
    var unitMemberId : String?
    var isShowDetails : Bool! = false
    var selectedSection : Int! = -1
    var db: OpaquePointer?
    var flightInfoList = [flightInfo]()
    var unitEventsList = [unitEvents]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = false
        UNUserNotificationCenter.current().delegate = self
        tblView.exclusiveSections = true
        titleBarButton.setTitleTextAttributes([ NSAttributedString.Key.font: UIFont(name: "HelveticaNeue-Bold", size: 22)!], for: UIControl.State.normal)
        tblView.delegate = self
        tblView.dataSource = self
        tblView.rowHeight = UITableView.automaticDimension
        tblView.estimatedRowHeight = 44.0
        getFlightInfo()
        tblView.reloadData()
        selectedSection = 0
        tblView.openSection(0, animated: false)
    }

    func onSelectionChangeColor(superView : UIView){
        for view in superView.subviews{
            for subviews in view.subviews{
//                if subviews.isKind(of: UIView.self){
//                    if let subview = subviews as? UIView{
//                        subview.backgroundColor = UIColor.init(red: 156.0/255.0, green: 107.0/255.0, blue: 107.0/255.0, alpha: 1)
//                    }
//                }else
                
                if subviews.isKind(of: UILabel.self){
                    if let subview = subviews as? UILabel{
                        subview.textColor = .white
                    }
                }else if subviews.isKind(of: UIButton.self){
                    if let subview = subviews as? UIButton{
                        subview.titleLabel?.textColor = .white
                    }
                }else{

                    view.backgroundColor = UIColor.init(red: 156.0/255.0, green: 107.0/255.0, blue: 107.0/255.0, alpha: 1)
                }
            }
            
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return flightInfoList.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderViewCell") as! HeaderViewCell
        cell.currentActivity.text = flightInfoList[section].flightCurrentActivity
        cell.flightNumber.text = flightInfoList[section].flightName
        cell.flightTime.text = String.init(format:"%@ %@", flightInfoList[section].flightDate!, flightInfoList[section].ETATime!)
        cell.flightTATtime.text = flightInfoList[section].flightTAT
        cell.flightTimeStatus.text = "ON - TIME"
        cell.flightStatus.text = "Schedule"
        if cell.isCellSelected{
            
            cell.isCellSelected = false
            
            //prevHeader = cell
            
        }else{
            cell.isCellSelected = true
            prevHeader = cell
        }
        
//        if section == selectedSection{
//            onSelectionChangeColor(superView: cell.contentView)
//        }
        
        return cell.contentView
    }
    
    func StringToDate(strDate : String)->Date{
        let dateString = strDate.replacingOccurrences(of: "- ", with: "00:").replacingOccurrences(of: "+ ", with: "00:").replacingOccurrences(of: "ETA ", with: "").replacingOccurrences(of: "ETD ", with: "").replacingOccurrences(of: "BLOCK IN ", with: "").replacingOccurrences(of: "-", with: "00:").replacingOccurrences(of: "+", with: "00:").replacingOccurrences(of: "+ ", with: "00:")
       // let dateString = dateString
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm"
        let dateObj = dateFormatter.date(from: dateString)
        dateFormatter.dateFormat = "dd MM yyyy HH:mm"
        print("Dateobj: \(dateFormatter.string(from: dateObj!))")
        return dateObj!
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return unitEventsList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "CustomActiveViewCell") as! CustomActiveViewCell
        cell.activityStartStopBtn.tag = indexPath.row
        
        //cell.activityStartStopBtn.addTarget(self, action: #selector(startEventAction), for: .touchUpInside)
        cell.currentActivityName.text = unitEventsList[indexPath.row].unitEvent
        cell.currentActivityStartTime.text = unitEventsList[indexPath.row].eventStartTime
        if (unitEventsList[indexPath.row].unitEvent! == "Landed" || unitEventsList[indexPath.section].unitEvent! == "Block In"){
            cell.currentActivityExpectedTime.text = String.init(format:"END AT - %@", differenceTwoTimes(arrivalTime: flightInfoList[indexPath.section].ETATime!, eventETATime: unitEventsList[indexPath.row].eventStartTime! == "0" ? unitEventsList[indexPath.section].eventEndTime!: unitEventsList[indexPath.row].eventStartTime!, flightBlockTime: flightInfoList[indexPath.section].flightBlockTime!))
        }else if (unitEventsList[indexPath.row].unitEvent! == "LNF IRR"){
            cell.currentActivityExpectedTime.text = ""
        }else{
            cell.currentActivityExpectedTime.text = String.init(format:"START AT - %@", differenceTwoTimes(arrivalTime: flightInfoList[indexPath.section].ETATime!, eventETATime: unitEventsList[indexPath.row].eventStartTime! == "0" ? unitEventsList[indexPath.section].eventEndTime!: unitEventsList[indexPath.row].eventStartTime!, flightBlockTime: flightInfoList[indexPath.section].flightBlockTime!))
            scheduleNotification(at: (StringToDate(strDate: String.init(format:"%@ %@", flightInfoList[indexPath.section].flightDate!,  unitEventsList[indexPath.row].eventStartTime! == "0" ? unitEventsList[indexPath.section].eventEndTime! : unitEventsList[indexPath.row].eventStartTime!))), Info: unitEventsList[indexPath.row].unitEvent!)
        }
        cell.currentActivityProgressTime.text = unitEventsList[indexPath.row].eventProgressTime
        cell.currentActivityStatus.text = unitEventsList[indexPath.row].eventStatus
        if cell.currentActivityProgressTime.text != "0" && cell.currentActivityProgressTime.text != ""{
            cell.currentActivityPlayPauselbl.text = "PAUSE"
            if let image = UIImage(named: "Pause_SX") {
                cell.activityStartStopBtn.setImage(image, for: .normal)
            }
        }else{
            cell.currentActivityProgressTime.text = ""
            cell.currentActivityPlayPauselbl.text = ""
            if let image = UIImage(named: "Play_SX") {
                cell.activityStartStopBtn.setImage(image, for: .normal)
            }
        }
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 146
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    func tableView(_ tableView:UITableView, didSelect header:UIView, isOpen open: (Bool),section:Int){
        selectedSegmentSection = section
        //let cell = Bundle.main.loadNibNamed("HeaderViewCell", owner: self, options: nil)?.first as! HeaderViewCell
        if (header as! HeaderViewCell).isCellSelected == true{
            (header as! HeaderViewCell).isCellSelected = true
            selectedSection = section
            isShowDetails = true
            //cell.showDetails.setImage(UIImage(named: "minus"), for: .selected)
            self.tblView.reloadData()
        }else{
            selectedSection = section
            isShowDetails = false
            (header as! HeaderViewCell).isCellSelected  = false
            self.tblView.reloadData()
            //cell.showDetails.setImage(UIImage(named: "plusIcon"), for: .normal)
        }
    }
    
    
    
    func getFlightInfo(){
        let resourcePath = Bundle.main.url(forResource: "starlux", withExtension: "db")
        if sqlite3_open(resourcePath?.absoluteString, &db) != SQLITE_OK {
            print("error opening database")
        }else{
            print("opening database")
        }
        
        _ = readValues()
        _ = readUnitEventsValues()
    }
    
    func readValues()->([flightInfo]){
        let queryString = "SELECT  E.date_of_flight SCHFLIGHTDATE, E.ETA_Time ETA,  E.ETD_Time ETD, D.flight_code FLIGHTCODE, D.flight_name FLIGHTNAME, E.flight_TAT TAT, E.flight_block_time FROM 'flightSchedule' E JOIN 'flight' D ON (E.flight_id = D.flight_id) AND E.flight_id = '1' "
        var stmt:OpaquePointer?
        
        if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK{
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error preparing insert: \(errmsg)")
            return (flightInfoList)
        }
        
        while(sqlite3_step(stmt) == SQLITE_ROW){
            let schFlightDate = String(cString: sqlite3_column_text(stmt, 0))
            let ETATime = String(cString: sqlite3_column_text(stmt, 1))
            let ETDTime = String(cString: sqlite3_column_text(stmt, 2))
            let flightCode = String(cString: sqlite3_column_text(stmt, 3))
            let flightName = String(cString: sqlite3_column_text(stmt, 4))
            let flightTAT = String(cString: sqlite3_column_text(stmt, 5))
            let flightBlockTime = String(cString: sqlite3_column_text(stmt, 6))

            flightInfoList.append(flightInfo.init(flightName: flightName, flightDate: schFlightDate, flightScheduleStatus: "", flightTAT: flightTAT, flightStatus: "", flightCurrentActivity: "NO ACTIVITY", flightCode: flightCode, ETATime : ETATime, ETDTime: ETDTime, flightBlockTime: flightBlockTime))
        }
        return (flightInfoList)
    }
    
    func readUnitEventsValues()->([unitEvents]){
        let queryString = "select e.event_name, e.event_type, e.event_start_time, e.event_end_time from 'unitMemberinfo' uM JOIN 'events' e ON (uM.unitMember_assignedFlight_id = '\(unitId!)') And uM.unit_id == e.unit_id and e.event_type = 'Arrival' and uM.unitMember_id = '\(unitMemberId!)' AND uM.unit_id = '\(unitId!)'"
        var stmt:OpaquePointer?
        
        if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK{
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error preparing insert: \(errmsg)")
            return (unitEventsList)
        }
        
        while(sqlite3_step(stmt) == SQLITE_ROW){
            let eventName = String(cString: sqlite3_column_text(stmt, 0))
            var event_startTime = String(cString: sqlite3_column_text(stmt, 2))
            //let event_type = String(cString: sqlite3_column_text(stmt, 1))
            var event_end_time = String(cString: sqlite3_column_text(stmt, 3))
            if event_startTime.contains("-"){
                event_startTime = "ETA \(event_startTime)"
            }else if event_startTime.contains("0"){
                event_startTime = "BLOCK IN \(event_end_time)"
            }else if event_end_time.contains("+"){
                event_end_time = "ETD \(event_end_time)"
            }
            unitEventsList.append(unitEvents.init(unitEvent: eventName, eventETA: event_startTime, eventStartTime: event_startTime, eventEndTime: event_end_time, eventProgressTime: "", eventStatus: "", eventRunningStatus: ""))
        }
        return (unitEventsList)
    }
    
    func differenceTwoTimes(arrivalTime : String, eventETATime : String, flightBlockTime : String)-> String{
        var eventETA : String = ""
        
        eventETA = eventETATime.replacingOccurrences(of: "- ", with: "00:").replacingOccurrences(of: "+ ", with: "00:").replacingOccurrences(of: "ETA ", with: "").replacingOccurrences(of: "ETD ", with: "").replacingOccurrences(of: "BLOCK IN ", with: "").replacingOccurrences(of: "-", with: "00:")
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        //let timeDiff = String.localizedStringWithFormat("%d:%02d", hour, min)
        if eventETATime.contains("-"){
            let date1 = timeFormatter .date(from: arrivalTime)
            let date2 = timeFormatter .date(from: eventETA)
            let difference = Calendar.current.dateComponents([.hour, .minute], from: date1!, to: date2!)
            let formattedString = String(format: "%02ld:%02ld", difference.hour!, difference.minute!)
            print(formattedString.replacingOccurrences(of: "-", with: ""))
            return formattedString.replacingOccurrences(of: "-", with: "")
        }else if eventETATime.contains("+"){
            let flightBlock_Time = timeFormatter .date(from: flightBlockTime)
            let eventETA = eventETATime.replacingOccurrences(of: "- ", with: "").replacingOccurrences(of: "+ ", with: "").replacingOccurrences(of: "ETA ", with: "").replacingOccurrences(of: "ETD ", with: "").replacingOccurrences(of: "BLOCK IN ", with: "").replacingOccurrences(of: "+", with: "")
            let calendar = Calendar.current
            let formattedString = calendar.date(byAdding: .minute, value: Int(eventETA)!, to: flightBlock_Time!)
            timeFormatter.dateFormat = "HH:mm"
            let time = timeFormatter.string(from: formattedString!)
           // print(time)
            return time//formattedString.replacingOccurrences(of: "-", with: "")
        }
        
       return ""
    }
    
//    @objc func startEventAction(sender : UIButton){
//        let cell = tblView.dequeueReusableCell(withIdentifier: "CustomActiveViewCell") as! CustomActiveViewCell
//        if sender.isSelected{
//            if let image = UIImage(named: "Play_SX") {
//                sender.setImage(image, for: .normal)
//            }
//            cell.currentActivityPlayPauselbl.text = ""
//            sender.isSelected = false
//        }else{
//            cell.currentActivityPlayPauselbl.text = "PAUSE"
//            if let image = UIImage(named: "Pause_SX") {
//                sender.setImage(image, for: .normal)
//            }
//            sender.isSelected = true
//        }
//    }
    
    //Schedule Notification
    func scheduleNotification(at date: Date, Info: String) {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(in: .current, from: date)
        let newComponents = DateComponents(calendar: calendar, timeZone: .current, month: components.month, day: components.day, hour: components.hour, minute: components.minute)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: newComponents, repeats: false)
        
        let content = UNMutableNotificationContent()
        content.title = "STARLUX - TAT"
        content.body = Info
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "myCategory"
        
        if let path = Bundle.main.path(forResource: "logo", ofType: "png") {
            let url = URL(fileURLWithPath: path)
            
            do {
                let attachment = try UNNotificationAttachment(identifier: "logo", url: url, options: nil)
                content.attachments = [attachment]
            } catch {
                print("The attachment was not loaded.")
            }
        }
        
        let request = UNNotificationRequest(identifier: "textNotification", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().delegate = self
        //UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().add(request) {(error) in
            if let error = error {
                print("Uh oh! We had an error: \(error)")
            }
        }
    }
    
    @IBAction func backToViewController(){
        self.navigationController?.popViewController(animated: true)
    }
}


class HeaderViewCell : UITableViewCell {
    @IBOutlet var flightNumber : UILabel!
    @IBOutlet var flightTime : UILabel!
    @IBOutlet var flightStatus : UILabel!
    @IBOutlet var flightTimeStatus : UILabel!
    @IBOutlet var currentActivity : UILabel!
    @IBOutlet var flightTATtime : UILabel!
    @IBOutlet var showDetails : UIButton!
    @IBOutlet var cardView : UIView!
    var isCellSelected : Bool = false
}

class CustomComplectedActiveViewCell : UITableViewCell {
    @IBOutlet var currentActivityName : UILabel!
    @IBOutlet var currentActivityStartTime : UILabel!
    @IBOutlet var currentActivityEndTime : UILabel!
    @IBOutlet var currentActivityExpectedTime : UILabel!
    @IBOutlet var currentActivityStatus : UILabel!
}

class CustomActiveViewCell : UITableViewCell {
    @IBOutlet var currentActivityName : UILabel!
    @IBOutlet var currentActivityStartTime : UILabel!
    @IBOutlet var currentActivityEndTime : UILabel!
    @IBOutlet var currentActivityExpectedTime : UILabel!
    @IBOutlet var currentActivityStatus : UILabel!
    @IBOutlet var currentActivityProgressTime : UILabel!
    @IBOutlet var currentActivityPlayPauselbl : UILabel!
    @IBOutlet var activityStartStopBtn : UIButton!
    @IBOutlet var cellCardView : UIView!
    var timer: Timer?
    var secs = 0
    
    @IBAction func startEventAction(sender : UIButton){
        if sender.isSelected{
            if let image = UIImage(named: "Play_SX") {
                sender.setImage(image, for: .normal)
            }
            currentActivityStatus.text = ""
            currentActivityPlayPauselbl.isHidden = true
            currentActivityStatus.isHidden = true
            sender.isSelected = false
            timer!.invalidate()
            timer = nil
        }else{
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(countdown), userInfo: nil, repeats: true)
            currentActivityStatus.text = "ACTIVE"
            currentActivityPlayPauselbl.text = "PAUSE"
            if let image = UIImage(named: "Pause_SX") {
                sender.setImage(image, for: .normal)
            }
            currentActivityPlayPauselbl.isHidden = false
            currentActivityStatus.isHidden = false
            sender.isSelected = true
            roundedView()
        }
    }
    
    func roundedView(){
        currentActivityStatus.layer.cornerRadius = 10.0
        currentActivityStatus.layer.masksToBounds = true
        currentActivityStatus.backgroundColor = UIColor.init(red: 238/255.0, green: 238/255.0, blue: 238/255.0, alpha: 1)
    }
    
    @objc func countdown() {
        secs = secs + 1
        if secs == 0 {
            print("CELL TIME HAS EXPIRED!")
            timer!.invalidate()
        } else {
            let hour = self.secs / 3600
            let mins = self.secs / 60 % 60
            let secsond = self.secs % 60
            let restTime = (((hour<10) ? "0" : "") + String(hour) + ":" + ((mins<10) ? "0" : "") + String(mins) + ":" + ((secsond<10) ? "0" : "") + String(secsond))
            currentActivityProgressTime.text = String.init(format: "TIME : %@", restTime)
        }
    }
    

}

extension UIView {
    
    func setCardView(view : UIView){
        
        view.layer.cornerRadius = 5.0
        view.layer.borderColor  =  UIColor.clear.cgColor
        view.layer.borderWidth = 5.0
        view.layer.shadowOpacity = 0.5
        view.layer.shadowColor =  UIColor.lightGray.cgColor
        view.layer.shadowRadius = 5.0
        view.layer.shadowOffset = CGSize(width:5, height: 5)
        view.layer.masksToBounds = true
    }
}
