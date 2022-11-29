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
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var subtitleTextField: UITextField!
    @IBOutlet weak var forcePresentButton: UIButton!
    
    weak var presentedBanner: BaulyView?
    
    var newColor: UIColor? {
        didSet {
            view.backgroundColor = newColor
        }
    }
    
    @IBAction func buttonPressed(_ sender: UIButton) {
        let configuration = BaulyView.Configuration(title: titleTextField.text,
                                                    subtitle: subtitleTextField.text,
                                                    image: .init(systemName: "heart.fill"))
        var options = Bauly.PresentationOptions()
        options.waitForDismissal = (sender !== forcePresentButton)
        
        Bauly.present(withConfiguration: configuration,
                      presentationOptions: options,
                      completion: { state in
            switch state {
            case .willPresent(let banner):
                banner.tintColor = .purple
                banner.iconView.preferredSymbolConfiguration = .init(pointSize: 26)
                
            default:
                break
            }
        })
    }
    
}

