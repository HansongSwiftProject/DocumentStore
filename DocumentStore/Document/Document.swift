//
//  Document.swift
//  DocumentStore
//
//  Created by Mathijs Kadijk on 03-11-16.
//  Copyright © 2016 Mathijs Kadijk. All rights reserved.
//

import Foundation

/// A type that provides an interface to transfer types to a document store and back.
public protocol Document: Codable {
  /// Description that indentifies the document and determens how it should be indexed.
  static var documentDescriptor: DocumentDescriptor<Self> { get }

  static func encode(_ document: Self) throws -> Data
  static func decode(from data: Data) throws -> Self
}

public extension Document {
  static func encode(_ document: Self) throws -> Data {
    return try JSONEncoder().encode(document)
  }

  static func decode(from data: Data) throws -> Self {
    return try JSONDecoder().decode(Self.self, from: data)
  }
}
