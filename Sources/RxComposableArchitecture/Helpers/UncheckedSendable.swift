//
//  File.swift
//  
//
//  Created by Dimas Agung Prabowo on 30/05/24.
//

import Foundation

#if compiler(<6.0) || !hasFeature(InferSendableFromCaptures)
// FIXME: Workaround trading a bunch of Strict Concurrency related warnings. To be removed when Swift 6.0 is available.
extension KeyPath: @unchecked Sendable {}
#endif
