//
//  CoreDataTransaction.swift
//  DocumentStore
//
//  Created by Mathijs Kadijk on 12-11-16.
//  Copyright © 2016 Mathijs Kadijk. All rights reserved.
//

import Foundation
import CoreData

class CoreDataTransaction: ReadWritableTransaction {
  private let context: NSManagedObjectContext
  private let documentDescriptors: [AnyDocumentDescriptor]
  private let logger: Logger

  init(context: NSManagedObjectContext, documentDescriptors: [AnyDocumentDescriptor], logTo logger: Logger) {
    self.context = context
    self.documentDescriptors = documentDescriptors
    self.logger = logger
  }

  func validateUseOfDocumentType<DocumentType: Document>(_: DocumentType.Type) throws {
    guard documentDescriptors.contains(DocumentType.documentDescriptor.eraseType()) else {
      let error = DocumentStoreError(
        kind: .documentDescriptionNotRegistered,
        message: "The document description with identifier '\(DocumentType.documentDescriptor.identifier)' is not registered with the DocumentStore this transaction is associated with, please pass all DocumentDescriptions that are used to the DocumentStore initializer.",
        underlyingError: nil
      )
      throw TransactionError.DocumentStoreError(error)
    }
  }

  func count<CollectionType: Collection>(_ collection: CollectionType) throws -> Int {
    try validateUseOfDocumentType(CollectionType.DocumentType.self.self)

    let request: NSFetchRequest<NSNumber> = collection.fetchRequest()

    do {
      return try context.count(for: request)
    } catch let underlyingError {
      let error = DocumentStoreError(
        kind: .fetchRequestFailed,
        message: "Failed to count '\(CollectionType.DocumentType.documentDescriptor.identifier)' documents. This is an error in the DocumentStore library, please report this issue.",
        underlyingError: underlyingError
      )
      logger.log(level: .error, message: "Error while performing count.", error: error)
      throw TransactionError.DocumentStoreError(error)
    }
  }

  func fetch<CollectionType: Collection>(_ collection: CollectionType) throws -> [CollectionType.DocumentType] {
    try validateUseOfDocumentType(CollectionType.DocumentType.self)

    // Set up the fetch request
    let request: NSFetchRequest<NSManagedObject> = collection.fetchRequest()
    request.returnsObjectsAsFaults = false

    // Perform the fetch
    let fetchResult: [NSManagedObject]
    do {
      fetchResult = try context.fetch(request)
    } catch let underlyingError {
      let error = DocumentStoreError(
        kind: .fetchRequestFailed,
        message: "Failed to fetch '\(CollectionType.DocumentType.documentDescriptor.identifier)' documents. This is an error in the DocumentStore library, please report this issue.",
        underlyingError: underlyingError
      )
      logger.log(level: .error, message: "Error while performing fetch.", error: error)
      throw TransactionError.DocumentStoreError(error)
    }

    // Deserialize documents
    return try fetchResult
      .flatMap {
        do {
          guard let documentData = $0.value(forKey: DocumentDataAttributeName) as? Data else {
            let error = DocumentStoreError(
              kind: .documentDataAttributeCorruption,
              message: "Failed to retrieve '\(DocumentDataAttributeName)' attribute contents and cast it to `Data` for a '\(CollectionType.DocumentType.documentDescriptor.identifier)' document. This is an error in the DocumentStore library, please report this issue.",
              underlyingError: nil
            )
            logger.log(level: .error, message: "Encountered corrupt '\(DocumentDataAttributeName)' attribute.", error: error)
            throw DocumentDeserializationError(resolution: .Skip, underlyingError: error)
          }

          return try CollectionType.DocumentType.deserializeDocument(from: documentData)
        } catch let error as DocumentDeserializationError {
          logger.log(level: .warn, message: "Deserializing '\(CollectionType.DocumentType.documentDescriptor.identifier)' document failed, recovering with '\(error.resolution)' resolution.", error: error.underlyingError)

          switch error.resolution {
          case .Delete:
            context.delete($0)
          case .Skip:
            break
          }

          return nil
        } catch let error {
          throw TransactionError.SerializationFailed(error)
        }
    }
  }

  @discardableResult
  func delete<CollectionType: Collection>(_ collection: CollectionType) throws -> Int {
    try validateUseOfDocumentType(CollectionType.DocumentType.self)

    let request: NSFetchRequest<NSManagedObject> = collection.fetchRequest()
    request.includesPropertyValues = false

    do {
      let fetchResult = try context.fetch(request)
      fetchResult.forEach(context.delete)
      return fetchResult.count
    } catch let underlyingError {
      let error = DocumentStoreError(
        kind: .fetchRequestFailed,
        message: "Failed to fetch '\(CollectionType.DocumentType.documentDescriptor.identifier)' documents. This is an error in the DocumentStore library, please report this issue.",
        underlyingError: underlyingError
      )
      logger.log(level: .error, message: "Error while performing fetch.", error: error)
      throw TransactionError.DocumentStoreError(error)
    }
  }

  public func add<DocumentType: Document>(document: DocumentType) throws {
    try validateUseOfDocumentType(DocumentType.self)

    let entity = NSEntityDescription.insertNewObject(forEntityName: DocumentType.documentDescriptor.identifier, into: context)

    do {
      let documentData = try document.serializeDocument()
      entity.setValue(documentData, forKey: DocumentDataAttributeName)
    } catch let error {
      throw TransactionError.SerializationFailed(error)
    }

    DocumentType.documentDescriptor.indices.forEach {
      entity.setValue($0.resolver(document), forKey: $0.identifier)
    }
  }

  func saveChanges() throws {
    if context.hasChanges {
      try context.save()
    }
  }

}