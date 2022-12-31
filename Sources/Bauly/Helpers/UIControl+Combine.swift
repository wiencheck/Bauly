//
//  UIControl+Combine.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 11/08/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

// TAKEN FROM: https://www.avanderlee.com/swift/custom-combine-publisher/

import Combine
import UIKit

protocol CombineCompatible {}

/// A custom subscription to capture UIControl target events.
final class UIControlSubscription<SubscriberType: Subscriber>: Subscription where SubscriberType.Input == UIControl {
  private var subscriber: SubscriberType?
  private let control: UIControl

  init(subscriber: SubscriberType, control: UIControl, event: UIControl.Event) {
    self.subscriber = subscriber
    self.control = control
    control.addTarget(self, action: #selector(self.eventHandler), for: event)
  }

  func request(_ demand: Subscribers.Demand) {
    // We do nothing here as we only want to send events when they occur.
    // See, for more info: https://developer.apple.com/documentation/combine/subscribers/demand
  }

  func cancel() {
    self.subscriber = nil
  }

  @objc private func eventHandler() {
    _ = self.subscriber?.receive(self.control)
  }
}

/// A custom `Publisher` to work with our custom `UIControlSubscription`.
struct UIControlPublisher: Publisher {
  typealias Output = UIControl
  typealias Failure = Never

  let control: UIControl
  let controlEvents: UIControl.Event

  init(control: UIControl, events: UIControl.Event) {
    self.control = control
    self.controlEvents = events
  }

  func receive<S>(subscriber: S) where S: Subscriber, S.Failure == UIControlPublisher.Failure,
    S.Input == UIControlPublisher.Output
  {
    let subscription = UIControlSubscription(subscriber: subscriber, control: control, event: controlEvents)
    subscriber.receive(subscription: subscription)
  }
}

/// Extending the `UIControl` types to be able to produce a `UIControl.Event` publisher.
extension UIControl {
  func publisher(for events: UIControl.Event) -> UIControlPublisher {
    return UIControlPublisher(control: self, events: events)
  }
}

final class UIGestureRecognizerSubscription<SubscriberType: Subscriber, Recognizer: UIGestureRecognizer>: Subscription
  where SubscriberType.Input == Recognizer
{
  private var subscriber: SubscriberType?
  private let control: Recognizer

  init(subscriber: SubscriberType, control: Recognizer) {
    self.subscriber = subscriber
    self.control = control
    control.addTarget(self, action: #selector(self.eventHandler))
  }

  func request(_ demand: Subscribers.Demand) {
    // We do nothing here as we only want to send events when they occur.
    // See, for more info: https://developer.apple.com/documentation/combine/subscribers/demand
  }

  func cancel() {
    self.subscriber = nil
  }

  @objc private func eventHandler() {
    _ = self.subscriber?.receive(self.control)
  }
}

struct UIGestureRecognizerPublisher<Recognizer: UIGestureRecognizer>: Publisher {
  typealias Output = Recognizer
  typealias Failure = Never

  let control: Recognizer

  init(control: Recognizer) {
    self.control = control
  }

  func receive<S>(subscriber: S) where S: Subscriber, S.Failure == UIGestureRecognizerPublisher.Failure,
    S.Input == UIGestureRecognizerPublisher.Output
  {
    let subscription = UIGestureRecognizerSubscription(subscriber: subscriber, control: control)
    subscriber.receive(subscription: subscription)
  }
}

extension UIGestureRecognizer: CombineCompatible {}
extension CombineCompatible where Self: UIGestureRecognizer {
  func publisher() -> UIGestureRecognizerPublisher<Self> {
    return UIGestureRecognizerPublisher(control: self)
  }
}
