//
//  InputViewController.swift
//  taskapp
//
//  Created by 坪本 梨沙 on 2022/06/15.
//

import UIKit
import RealmSwift
import UserNotifications

class InputViewController: UIViewController {

    /** outlet */
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var contentsTextView: UITextView!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var categoryTextField: UITextField!
    
    /** propaty */
    let realm = try! Realm()
    var task: Task!
    var category: Category!
    
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
        
        if self.task.id == 0 {
            self.category = Category()
            categoryTextField.text = self.category.name
        } else {
            let categoryResult = try! Realm().objects(Category.self).filter("id == %@", self.task.id)
            self.category = categoryResult.first
            categoryTextField.text = categoryResult.first?.name
        }
        
        //枠が欲しかったのでつけてみる
        contentsTextView.layer.borderColor = UIColor(hex: "eeeeee").cgColor
        contentsTextView.layer.borderWidth = 1.0
        contentsTextView.layer.cornerRadius = 5.0
        contentsTextView.layer.masksToBounds = true
    }
    
    //画面が消える前に呼び出される
    override func viewWillDisappear(_ animated: Bool) {
        //カテゴリチェック
        var categoryId: Int = 0
        if self.category.name != self.categoryTextField.text {
            //変更あり
            let categoryExists = try! Realm().objects(Category.self).filter("category == %@", self.category.name)
            if categoryExists.count == 0 {
                //重複なしの場合、追加
                let newCategory = Category()
                let allCategories = realm.objects(Category.self)
                if allCategories.count != 0 {
                    newCategory.id = allCategories.max(ofProperty: "id")! + 1
                }
                try! realm.write {
                    self.category.id = newCategory.id
                    self.category.name = self.categoryTextField.text!
                    self.realm.add(self.category, update: .modified)
                }
                categoryId = newCategory.id
            } else {
                //重複ありの場合、取得
                categoryId = categoryExists.first?.id ?? 0
            }
        } else {
            //変更なし
            categoryId = self.category.id
        }

        try! realm.write {
            self.task.title = self.titleTextField.text!
            self.task.contents = self.contentsTextView.text
            self.task.date = self.datePicker.date
            self.task.categoryId = categoryId
            self.realm.add(self.task, update: .modified)
        }
        //catchは握りつぶす
        
        //ローカル通知の設定
        setNotification(task: task)
        
        //画面を閉じる処理なので最後に書く
        super.viewWillDisappear(animated)
    }
    
    @objc func dismissKeyboard(){
        // キーボードを閉じる
        view.endEditing(true)
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
    
    func checkCategory() {
        
    }
    
    
}
