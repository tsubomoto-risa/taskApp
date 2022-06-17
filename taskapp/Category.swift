//
//  Category.swift
//  taskapp
//
//  Created by 坪本 梨沙 on 2022/06/16.
//

import RealmSwift

class Category: Object {
    
    @objc dynamic var id = 1
    
    // 内容
    @objc dynamic var name = ""
    
    // id をプライマリーキーとして設定
    override static func primaryKey() -> String? {
        return "id"
    }
    
}
