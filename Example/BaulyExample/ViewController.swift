//
//  ViewController.swift
//  BaulyExample
//
//  Created by Adam Wienconek on 30/08/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit
import Bauly

class ViewController: UIViewController {
    
    var newColor: UIColor? {
        didSet {
            view.backgroundColor = newColor
        }
    }
    
    @IBAction func buttonPressed(_ sender: UIButton) {
        Bauly.shared.present(configurationHandler: { bauly in
            bauly.tintColor = self.newColor
            bauly.title = "This is Bauly!"
            bauly.subtitle = """
            Press me to have a little fun with colors.
            Btw, I support mutli-line text and emojis easily
            😏
            """
        }, in: view.window, feedbackStyle: .medium, pressHandler: {
            self.newColor = ([
                .red, .yellow, .blue, .green, .purple, .orange
            ] as [UIColor]).randomElement()
        }, completionHandler: {
            sender.setTitle("Present again", for: .normal)
        })
    }

}

