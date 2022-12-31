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
    @IBOutlet weak var symbolNameField: UITextField!
    @IBOutlet weak var forcePresentButton: UIButton!
        
    var newColor: UIColor? {
        didSet {
            view.backgroundColor = newColor
        }
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        .fade
    }
    
    override var prefersStatusBarHidden: Bool {
        Bauly.currentBanner(in: view.window?.windowScene) != nil
    }
    
    @IBAction func buttonPressed(_ sender: UIButton) {
        var configuration = BaulyView.Configuration()
        
        configuration.title = (titleTextField.text?.nilIfEmpty ?? titleTextField.placeholder?.nilIfEmpty)
        configuration.subtitle = (subtitleTextField.text?.nilIfEmpty ?? subtitleTextField.placeholder?.nilIfEmpty)
        if let symbolName = (symbolNameField.text?.nilIfEmpty ?? symbolNameField.placeholder?.nilIfEmpty) {
            configuration.image = .init(systemName: symbolName)
        }
        
        var options = Bauly.PresentationOptions()
        options.presentImmediately = (sender === forcePresentButton)
        
        Bauly.present(withConfiguration: configuration,
                      presentationOptions: options,
                      onTap: { banner in
            print("Banner was tapped!")
        },
                      completion: { [weak self] state in
            
            UIView.animate(withDuration: options.animationDuration / 3) {
                self?.setNeedsStatusBarAppearanceUpdate()
            }
            
            switch state {
            case .willPresent(let banner):
                // banner.tintColor = .purple
                banner.iconView.preferredSymbolConfiguration = .init(pointSize: 26)
                
            default:
                break
            }
        })
    }
    
}

extension String {
    
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
    
}
