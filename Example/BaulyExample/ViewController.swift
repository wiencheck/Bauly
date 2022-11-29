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
        
        Task.detached(priority: .low, operation: {
            await Bauly.present(withConfiguration: configuration,
                                completion: { [weak self] state in
                switch state {
                case .willPresent(let banner):
                    if #available(iOS 14.0, *) {
                        banner.addAction(UIAction() { _ in
                            print("Tapped!")
                        }, for: .primaryActionTriggered)
                    }
                    self?.presentedBanner = banner
                    
                case .presented:
                    sender.setTitle("Dismiss", for: .normal)
                    self?.presentedBanner?.overrideUserInterfaceStyle = .dark
                    self?.presentedBanner?.iconView.preferredSymbolConfiguration = .init(pointSize: 60)
                    self?.presentedBanner?.layoutIfNeeded()
                    
                case .dismissed:
                    sender.setTitle("Present", for: .normal)
                }
            })
        })
    }
    
}

