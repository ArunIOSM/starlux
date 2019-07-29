
import UIKit
import SQLite3


class SLLoginView: UIViewController {
    
    @IBOutlet weak var userType : UILabel!
    @IBOutlet weak var userPassword : UITextField!
    @IBOutlet weak var userName : UITextField!
    @IBOutlet weak var loginBtn : UIButton!
    @IBOutlet weak var userTypeSelectionBtn : UIButton!
    @IBOutlet weak var mainView : UIView!
    let chooseArticleDropDown = DropDown()
    let textField = UITextField()
    var userGroupMemberlist = [userGroupMember]()
    var userlist = [String]()
    var selectedIndex : Int = 0
    
    var db: OpaquePointer?
    
    lazy var dropDowns: [DropDown] = {
        return [
            self.chooseArticleDropDown
        ]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getFlightInfo()
        setupDropDowns()
//        self.navigationController?.navigationBar .setBackgroundImage(UIImage(), for: .default)
//        self.navigationController!.navigationBar.shadowImage = UIImage()
//        self.navigationController?.navigationBar.isTranslucent = true
//        self.navigationController!.view.backgroundColor = UIColor.clear
        self.navigationController?.navigationBar.isHidden = true
        roundedView(view: userTypeSelectionBtn)
        roundedView(view: loginBtn)
        
        dropDowns.forEach { $0.dismissMode = .onTap }
        dropDowns.forEach { $0.direction = .any }
        view.addSubview(textField)
    }
    
    func roundedView(view : Any){
        if ((view as? UIButton) != nil){
            (view as? UIButton)?.layer.cornerRadius = 3.0
            (view as? UIButton)?.layer.masksToBounds = true
            (view as? UIButton)?.layer.borderColor = UIColor.init(named: "BrownColor")?.cgColor
            (view as? UIButton)?.layer.borderWidth = 0.8
        }else if ((view as? UITextField) != nil){
            (view as? UITextField)?.layer.cornerRadius = 3.0
            (view as? UITextField)?.layer.masksToBounds = true
            (view as? UITextField)?.layer.borderColor = UIColor.init(named: "BrownColor")?.cgColor
            (view as? UITextField)?.layer.borderWidth = 0.8
        }
    }
    
    @IBAction func dropDownAction(sender : UIButton){
        chooseArticleDropDown.show()
    }
    
    func setupDropDowns() {
        setupChooseArticleDropDown()
    }

    func setupChooseArticleDropDown() {
        chooseArticleDropDown.anchorView = userTypeSelectionBtn
        chooseArticleDropDown.bottomOffset = CGPoint(x: 0, y: userTypeSelectionBtn.bounds.height + 5)
        
        // You can also use localizationKeysDataSource instead. Check the docs.
        chooseArticleDropDown.dataSource = userlist
        
        chooseArticleDropDown.selectionAction = { [weak self] (index, item) in
            self?.userTypeSelectionBtn.setTitle(item, for: .normal)
            self?.userName.text = self!.userGroupMemberlist[index].unitMembername
            self?.userPassword.text = self!.userGroupMemberlist[index].unitMembername
            self?.selectedIndex = index
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
        for index in 0..<userGroupMemberlist.count{
            userlist.append(userGroupMemberlist[index].unitname!)
        }
        
    }
    
    
    func readValues()->([userGroupMember]){
        
        let queryString = "SELECT unitMembername, uN.unit_id, un.unit_name, uM.unitmember_id  FROM 'unitMemberinfo' uM join 'unit' uN on (uN.unit_id = uM.unit_id) GROUP BY uM.unit_id"
        var stmt:OpaquePointer?
        
        if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK{
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error preparing insert: \(errmsg)")
            return (userGroupMemberlist)
        }
        
        while(sqlite3_step(stmt) == SQLITE_ROW){
            let unitMembername = String(cString: sqlite3_column_text(stmt, 0))
            let unitid = String(cString: sqlite3_column_text(stmt, 1))
            let unitname = String(cString: sqlite3_column_text(stmt, 2))
            let unitmemberid = String(cString: sqlite3_column_text(stmt, 3))
            userGroupMemberlist.append(userGroupMember.init(unitMembername: unitMembername, unitid: unitid, unitname: unitname,unitmemberid:unitmemberid))
        }
        return (userGroupMemberlist)
    }
    
    @IBAction func login(){
        let controller = self.storyboard?.instantiateViewController(withIdentifier: "ViewController") as? ViewController
        controller!.unitId = userGroupMemberlist[selectedIndex].unitid
        controller!.unitMemberId = userGroupMemberlist[selectedIndex].unitmemberid
        self.navigationController?.pushViewController(controller!, animated: true)
        
    }
}

