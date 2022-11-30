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
                if #available(iOS 14.0, *) {
                    banner.addAction(UIAction() { [weak self] in
                        self?.handleBannerTapped($0.sender as! BaulyView)
                    }, for: .primaryActionTriggered)
                }
                else {
                    banner.addTarget(self, action: #selector(ViewController.handleBannerTapped), for: .primaryActionTriggered)
                }
                
                banner.tintColor = .purple
                banner.iconView.preferredSymbolConfiguration = .init(pointSize: 26)
                
            default:
                break
            }
        })
    }
    
    @objc func handleBannerTapped(_ sender: BaulyView) {
        print("Banner tapped!")
    }
    
}

