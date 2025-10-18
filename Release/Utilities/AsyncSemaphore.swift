//
//  AsyncSemaphore.swift
//  Release
//
//  Created by Roger on 2025/10/6.
//

import Foundation

actor AsyncSemaphore {
    private let maxPermits: Int
    private var availablePermits: Int
    private var waitQueue: [CheckedContinuation<Void, Never>] = []
    
    init(value: Int) {
        precondition(value > 0, "Semaphore value must be greater than zero")
        self.maxPermits = value
        self.availablePermits = value
    }
    
    func acquire() async {
        if availablePermits > 0 {
            availablePermits -= 1
            return
        }
        
        await withCheckedContinuation { continuation in
            waitQueue.append(continuation)
        }
    }
    
    func release() {
        if !waitQueue.isEmpty {
            let continuation = waitQueue.removeFirst()
            continuation.resume()
        } else if availablePermits < maxPermits {
            availablePermits += 1
        }
    }
}
