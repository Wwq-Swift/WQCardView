//
//  ViewController.swift
//  WQCardView
//
//  Created by 王伟奇 on 2019/4/22.
//  Copyright © 2019 王伟奇. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var cardView: WQCardView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cardView = WQCardView(frame: CGRect(x: 25, y: 150, width: UIScreen.width - 50, height: 420))
        cardView.backgroundColor = UIColor.lightGray
        cardView.dataSource = self
        cardView.delegate = self
        cardView.visibleCount = 4
        cardView.lineSpacing = 15
        cardView.maxAngle = 10
//        cardView.is
        cardView.maxRemoveDistance = 100
        cardView.layer.cornerRadius = 10
        
        
        cardView.register(CardViewItem.self, forItemReuseIdentifier: "typeOne")
        view.addSubview(cardView)
        //        let item = WQCardViewBaseItem(reuseIdentifier: "sdfsd")
//        item.frame = CGRect(x: 0, y: 0, width: 200, height: 200)
//        item.backgroundColor = UIColor.red
//        item.center = view.center
//        view.addSubview(item)
        // Do any additional setup after loading the view, typically from a nib.
    }


}

extension ViewController: WQCardViewDelegate, WQCardViewDataSource {

    func numberOfItems(in cardView: WQCardView) -> Int {
        return 8
    }
    
    func cardView<Operation>(_ cardView: WQCardView, itemAt index: Int) -> WQCardViewItem<Operation> where Operation : WQCardViewItemOperationable {
        let item = cardView.dequeueReusableItem(withIdentifier: "typeOne", for: index)!
        item.backgroundColor = .red
        item.layer.borderWidth = 5
        item.layer.borderColor = UIColor.green.cgColor
        
        return item as! WQCardViewItem<Operation>
    }
    
    func cardView(_ cardView: WQCardView, didSelectItemAt index: Int) {
        
    }
    
    func cardView<Operaion>(_ cardView: WQCardView, didRemove item: WQCardViewItem<Operaion>, forAt index: Int) where Operaion : WQCardViewItemOperationable {
        print(index)
    }
    
    func cardView<Operaion>(_ cardView: WQCardView, didRemoveLast item: WQCardViewItem<Operaion>) where Operaion : WQCardViewItemOperationable {
        
    }
    
    func cardView<Operaion>(_ cardView: WQCardView, didEndDisplaying item: WQCardViewItem<Operaion>, forAt index: Int) where Operaion : WQCardViewItemOperationable {
        
    }
    
    func cardView<Operaion>(_ cardView: WQCardView, didMove item: WQCardViewItem<Operaion>, forAt index: Int) where Operaion : WQCardViewItemOperationable {
        
    }
}

class CardViewItem: WQCardViewBaseItem {
    
}
