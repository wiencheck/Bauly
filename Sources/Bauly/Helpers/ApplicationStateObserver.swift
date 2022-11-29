//
//  File.swift
//  
//
//  Created by Adam Wienconek on 28/11/2022.
//

import Foundation
import UIKit
import Combine

class ApplicationStateObserver {
    
    private var applicationStateObservers: Set<AnyCancellable> = []
    private let applicationStateSubject: CurrentValueSubject<Bool, Never>
    
    init() {
        let state = UIApplication.shared.applicationState
        applicationStateSubject = .init(state == .active)
        
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.applicationStateSubject.value = false
            }
            .store(in: &applicationStateObservers)
        
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.applicationStateSubject.value = true
            }
            .store(in: &applicationStateObservers)
    }
    
    var applicationStatePublisher: AnyPublisher<Bool, Never> {
        applicationStateSubject.eraseToAnyPublisher()
    }
    
}
