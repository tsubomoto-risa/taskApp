//
//  ViewController.swift
//  taskapp
//
//  Created by 坪本 梨沙 on 2022/06/15.
//

import UIKit
import RealmSwift
import UserNotifications

class ViewController: UIViewController,UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var filterTextField: UITextField!
    
    // Realmインスタンスを取得する
    let realm = try! Realm()
    
    //DBレコードが格納される入れる、日付でソート
    var taskList = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true)
    
    var categoryList = try! Realm().objects(Category.self)
    var categoryPicker: UIPickerView!
    
    //VC生成時に１度だけ呼ばれる
    override func viewDidLoad() {
        super.viewDidLoad()
        //デフォルトでは空セルが表示されないため、cellの高さを可変にする
        tableView.fillerRowHeight = UITableView.automaticDimension
        //VCにTableViewの処理を委譲
        tableView.delegate = self
        //tableviewのデータソースを自身(VC)とする
        tableView.dataSource = self
        
        //pickerの設定
        let pointY = self.view.bounds.height
        let toolbar = UIToolbar()
        toolbar.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 44)
        let doneButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.donePicker))
        toolbar.setItems([doneButtonItem], animated: true)
        self.categoryPicker = UIPickerView()
        self.categoryPicker.frame = CGRect(x: 0, y: pointY, width: self.view.bounds.width, height: 150.0)
        self.categoryPicker.delegate = self
        self.categoryPicker.dataSource = self
        self.view.addSubview(self.categoryPicker)
        self.filterTextField.inputAccessoryView = toolbar
        self.filterTextField.inputView = self.categoryPicker
    }
    
    // segue で画面遷移する時に呼ばれる
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        let inputViewController:InputViewController = segue.destination as! InputViewController
        
        if segue.identifier == "cellSegue" {
            //編集の場合
            let indexPath = self.tableView.indexPathForSelectedRow
            inputViewController.task = taskList[indexPath!.row]
        } else {
            //新規作成の場合
            let task = Task()

            let allTasks = realm.objects(Task.self)
            if allTasks.count != 0 {
                task.id = allTasks.max(ofProperty: "id")! + 1
            }

            inputViewController.task = task
        }
    }
    
    // 入力画面から戻ってきた時に TableView を更新させる
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    @IBAction func unwind(segue: UIStoryboardSegue) {
    }
    
    // UIPickerViewのRowが選択された時の挙動
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.filterTextField.text = self.categoryList[row].name
        let filteredTask = try! Realm().objects(Task.self).filter("categoryId == %@", self.categoryList[row].id).sorted(byKeyPath: "date", ascending: true)
        self.taskList = filteredTask
        tableView.reloadData()
    }
    
    // UIPickerViewの行数、要素の全数
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.categoryList.count
    }
    
    // UIPickerViewに表示する配列
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.categoryList[row].name
    }
    
    // ひとつのPickerViewに対して、横にいくつドラムロールを並べるかを指定。通常は1でOK
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
        
    }
    
    func CGRectMake(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    @objc func donePicker() {
        let allTask = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true)
        self.taskList = allTask
        self.filterTextField.text = ""
        tableView.reloadData()
        view.endEditing(true)
    }
    /** delegateされたメソッド */
    //データの数（＝セルの数）を返すメソッド
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.taskList.count
    }
    // 各セルの内容を返すメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 再利用可能な cell を得る
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        //cellに値を設定する
        //①title設定
        let task = self.taskList[indexPath.row]
        cell.textLabel?.text = task.title
        //②時刻フォーマット設定
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        //③詳細部分に②のフォーマットで時刻ラベルを設定
        let dateString:String = formatter.string(from: task.date)
        cell.detailTextLabel?.text = dateString
        
        return cell
    }

    // 各セルを選択した時に実行されるメソッド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //segueのIDを指定して遷移
        performSegue(withIdentifier: "cellSegue",sender: nil)
    }

    // セルが削除が可能なことを伝えるメソッド
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath)-> UITableViewCell.EditingStyle {
        return .delete
    }

    // Delete ボタンが押された時に呼ばれるメソッド
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // 削除するタスクを取得
            let task = self.taskList[indexPath.row]
            
            // ローカル通知をキャンセルする
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [String(task.id)])

            try! realm.write {
                //データベースから削除する
                self.realm.delete(self.taskList[indexPath.row])
                //取得し直すわけではないので格納配列も削除
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            //catchは握りつぶす
            
            // 未通知のローカル通知一覧をログ出力
            center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
                for request in requests {
                    print("/---------------")
                    print(request)
                    print("---------------/")
                }
            }
        }
    }
    
}

