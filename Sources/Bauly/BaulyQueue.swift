//
//  BaulyQueue.swift
//
//  Copyright (c) 2020 Adam Wienconek (https://github.com/wiencheck)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

/**
 Internal class responsible for managing upcoming banners' configurations.
 */
final class BaulyQueue {
    
    /// Dictionary of pending snapshots.
    private var snapshots = [String: Bauly.Snapshot]()
    
    /// Set containing snapshots' `String` identifiers
    private let queue = NSMutableOrderedSet()
        
    /**
     Adds new snapshot object to the queue and optionally places it at first position.
     - Parameters:
        - snapshot: New snapshot object to be put in the queue.
        - afterCurrent: Flag indicating where new snapshot should be placed. If true, snapshot will be placed at first position. Methods `removeFirst` and `first` would return that object if the argument passed is `true`. If `false`, the snapshot will be placed at the end of the queue.
     */
    @discardableResult
    func insert(snapshot: Bauly.Snapshot, afterCurrent: Bool) -> Bool {
        snapshots.updateValue(snapshot, forKey: snapshot.identifier)
        if queue.count == 0 || !afterCurrent {
            queue.add(snapshot.identifier)
        } else {
            queue.insert(snapshot.identifier, at: 1)
        }
        return true
    }
    
    /**
    Removes first snapshot in the queue.
    - Returns: Removed snapshot object.
    */
    @discardableResult
    func removeFirst() -> Bauly.Snapshot? {
        guard let identifier = queue.firstObject as? String else {
            return nil
        }
        queue.removeObject(at: 0)
        return snapshots.removeValue(forKey: identifier)
    }
    
    /**
     Returns first snaphot object in the queue.
     - Returns: First snapshot object in the queue
     */
    func first() -> Bauly.Snapshot? {
        guard let identifier = queue.firstObject as? String else {
            return nil
        }
        return snapshots[identifier]
    }
}
