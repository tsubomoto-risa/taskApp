//
//  InputViewController.swift
//  taskapp
//
//  Created by 坪本 梨沙 on 2022/06/15.
//

import UIKit
import RealmSwift
import UserNotifications

class InputViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    /** outlet */
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var contentsTextView: UITextView!
    @IBOutlet weak var categoryTextField: UITextField!
    @IBOutlet weak var dateTextField: UITextField!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    /** propaty */
    let realm = try! Realm()
    var task: Task!
    
    var categoryList = try! Realm().objects(Category.self)
    
    var categoryPicker: UIPickerView!
    
    var nowCategoryId: Int = 0
    
    //VC生成時に１度だけ呼ばれる
    override func viewDidLoad() {
        super.viewDidLoad()
        // 背景をタップしたらdismissKeyboardメソッドを呼ぶように設定する
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target:self, action:#selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)
        
        //初期値の設定
        titleTextField.text = task.title
        contentsTextView.text = task.contents
        datePicker.date = task.date
        nowCategoryId = task.categoryId
        let categoryName = self.categoryList.filter("id == %@", self.nowCategoryId)
        categoryTextField.text = categoryName.first?.name ?? ""
    
        //picker設定
        let toolbar = UIToolbar()
        toolbar.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 44)
        let doneButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.donePicker))
        toolbar.setItems([doneButtonItem], animated: true)
        self.categoryTextField.inputAccessoryView = toolbar
        self.categoryPicker = UIPickerView()
        self.categoryPicker.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 120.0)
        categoryPicker.delegate = self
        categoryPicker.dataSource = self
        self.view.addSubview(categoryPicker)
        categoryTextField.inputView = categoryPicker
        
        //contentに枠が欲しかったのでつけてみる
        contentsTextView.layer.borderColor = UIColor(hex: "eeeeee").cgColor
        contentsTextView.layer.borderWidth = 1.0
        contentsTextView.layer.cornerRadius = 5.0
        contentsTextView.layer.masksToBounds = true
    }
    
    //画面が消える前に呼び出される
    override func viewWillDisappear(_ animated: Bool) {
        //画面を閉じる処理なので最後に書く
        super.viewWillDisappear(animated)
    }
    
    //segue遷移時の設定
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        if segue.identifier != "addCategorySegue" {
            self.upsertTask()
            
            //ローカル通知の設定
            setNotification(task: task)
        }
    }
    
    // 入力画面から戻ってきた時に TableView を更新させる
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        categoryPicker.reloadAllComponents()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        categoryTextField.endEditing(true)
    }
    
    @IBAction func unwind(segue: UIStoryboardSegue) {
    }
    
    //addボタン押下時の挙動
    @IBAction func addTask(_ sender: Any) {
        self.upsertTask()
    }
    
    @objc func dismissKeyboard(){
        // キーボードを閉じる
        view.endEditing(true)
    }
    
    @objc func donePicker() {
        self.categoryTextField.endEditing(true)
    }
    
    // タスクのローカル通知を登録する
    func setNotification(task: Task) {
        let content = UNMutableNotificationContent()
        // タイトルと内容を設定(中身がない場合メッセージ無しで音だけの通知になるので「(xxなし)」を表示する)
        content.title = task.title == "" ? "(タイトルなし)" : task.title
        content.body = task.contents == "" ? "(内容なし)" : task.contents
        
        content.sound = UNNotificationSound.default

        // ローカル通知が発動するtrigger（日付マッチ）を作成
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: task.date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        // identifier, content, triggerからローカル通知を作成（identifierが同じだとローカル通知を上書き保存）
        let request = UNNotificationRequest(identifier: String(task.id), content: content, trigger: trigger)

        // ローカル通知を登録
        let center = UNUserNotificationCenter.current()
        center.add(request) { (error) in
            print(error ?? "ローカル通知登録 OK")  // error が nil ならローカル通知の登録に成功したと表示します。errorが存在すればerrorを表示します。
        }

        // 未通知のローカル通知一覧をログ出力
        center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
            for request in requests {
                print("/---------------")
                print(request)
                print("---------------/")
            }
        }
    }
    
    //taskの登録
    func upsertTask() {
        try! realm.write {
            self.task.title = self.titleTextField.text!
            self.task.contents = self.contentsTextView.text
            self.task.date = self.datePicker.date
            self.task.categoryId = self.nowCategoryId
            self.realm.add(self.task, update: .modified)
        }
    }
    
    // UIPickerViewの行数、要素の全数
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.categoryList.count
    }
    
    // UIPickerViewに表示する配列
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.categoryList[row].name
    }
    
    // UIPickerViewのRowが選択された時の挙動
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.categoryTextField.text = self.categoryList[row].name
        self.nowCategoryId = self.categoryList[row].id
    }
    
    // ひとつのPickerViewに対して、横にいくつドラムロールを並べるかを指定。通常は1でOK
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
        
    }
    
    
}
