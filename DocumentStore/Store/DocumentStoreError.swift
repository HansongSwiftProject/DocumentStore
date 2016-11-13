//
//  DocumentStoreError.swift
//  DocumentStore
//
//  Created by Mathijs Kadijk on 07-11-16.
//  Copyright © 2016 Mathijs Kadijk. All rights reserved.
//

import Foundation

public struct DocumentStoreError: Error, CustomStringConvertible {
  public enum ErrorKind: Int {
    case documentDescriptionInvalid = 1
    case documentDescriptionNotRegistered
    case fetchRequestFailed
    case documentDataAttributeCorruption
  }

  public let kind: ErrorKind
  public let message: String
  public let underlyingError: Error?

  public var description: String {
    let underlyingErrorDescription = underlyingError.map { " - \($0)" } ?? ""
    return "DocumentStoreError #\(kind.rawValue): \(message)\(underlyingErrorDescription)"
  }
}