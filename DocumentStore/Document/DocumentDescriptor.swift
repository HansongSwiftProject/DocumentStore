//
//  DocumentDescriptor.swift
//  DocumentStore
//
//  Created by Mathijs Kadijk on 04-11-16.
//  Copyright © 2016 Mathijs Kadijk. All rights reserved.
//

import Foundation

/// Description of a `Document` that among other things identifies it.
public struct DocumentDescriptor<DocumentType: Document> {
  let name: String
  let identifier: AnyIndex<DocumentType>
  let indices: [AnyIndex<DocumentType>]

  // TODO: Docs need update
  /// Create a description of a `Document`
  ///
  /// - Warning: Do never change the name, this is the only unique reference there is for the
  ///            storage system to know what `Document` you are describing. Changing it will result
  ///            in data loss!
  ///
  /// - Parameters:
  ///   - name: Unique (within one store) unchangable name of the described `Document`
  ///   - indices: List of all indices that should be created for the described `Document`
  public init<IdentifierValueType: StorableValue>(name: String, identifier: Identifier<DocumentType, IdentifierValueType>, indices: [AnyIndex<DocumentType>]) {
    self.name = name
    self.identifier = AnyIndex(from: identifier)
    self.indices = indices
  }
}

/// Type erased version of a `DocumentDescriptor`.
public struct AnyDocumentDescriptor: Validatable, Equatable {
  let name: String
  let identifier: UntypedAnyStorageInformation
  let indices: [UntypedAnyStorageInformation]

  // TODO
  public init<DocumentType>(from descriptor: DocumentDescriptor<DocumentType>) {
    self.name = descriptor.name
    self.identifier = UntypedAnyStorageInformation(from: descriptor.identifier.storageInformation)
    self.indices = descriptor.indices.map { UntypedAnyStorageInformation(from: $0.storageInformation) }
  }

  func validate() -> [ValidationIssue] {
    var issues: [ValidationIssue] = []

    // Name may not be empty
    if name.isEmpty {
      issues.append("DocumentDescriptor names may not be empty.")
    }

    // Name may not start with `_`
    if name.characters.first == "_" {
      issues.append("`\(name)` is an invalid DocumentDescriptor name, names may not start with an `_`.")
    }

    // Two indices may not have the same identifier
    issues += indices
      .map { $0.propertyName.keyPath }
      .duplicates()
      .map { "DocumentDescriptor `\(name)` has multiple indices with `\($0)` as name, every index name must be unique." }

    // Indices also should be valid
    issues += indices.flatMap { $0.validate() }

    return issues
  }

  public static func == (lhs: AnyDocumentDescriptor, rhs: AnyDocumentDescriptor) -> Bool {
    return lhs.name == rhs.name && lhs.indices == rhs.indices
  }
}
