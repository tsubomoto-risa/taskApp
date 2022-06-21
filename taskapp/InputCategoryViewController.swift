//
//  InputCategoryViewController.swift
//  taskapp
//
//  Created by 坪本 梨沙 on 2022/06/17.
//

import UIKit
import RealmSwift

class InputCategoryViewController: UIViewController {

    /** outlet */
    @IBOutlet weak var categoryTextField: UITextField!
    
    /** propaty */
    let realm = try! Realm()
    var categoryList = try! Realm().objects(Category.self)
    
    //VC生成時に１度だけ呼ばれる
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    //addボタンを押下したときの処理
    @IBAction func addCategory(_ sender: Any) {
        //重複チェック
        let checkText = self.categoryTextField.text ?? ""
        let categoryExists = try! Realm().objects(Category.self).filter("name == %@", checkText)
        if categoryExists.count == 0 && checkText != "" {
            //重複なしの場合、追加
            let newCategory = Category()
            if self.categoryList.count != 0 {
                newCategory.id = self.categoryList.max(ofProperty: "id")! + 1
            }
            newCategory.name = self.categoryTextField.text ?? ""
            try! realm.write {
                self.realm.add(newCategory, update: .modified)
            }
        }
    }

}
