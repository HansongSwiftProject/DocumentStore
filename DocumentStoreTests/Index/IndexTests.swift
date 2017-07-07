//
//  IndexTests.swift
//  DocumentStore
//
//  Created by Mathijs Kadijk on 07-11-16.
//  Copyright © 2016 Mathijs Kadijk. All rights reserved.
//

import XCTest
@testable import DocumentStore

class IndexTests: XCTestCase {

  // TODO: Should move to storageInformation tests
  func testValid() {
    let index = Index<TestDocument, Bool>(name: "TestIndex", resolver: { _ in false })
    XCTAssertTrue(StorageInformation(from: index.storageInformation).validate().isEmpty)
  }

  func testEmptyIdentifier() {
    let index = Index<TestDocument, Bool>(name: "", resolver: { _ in false })
    XCTAssertEqual(StorageInformation(from: index.storageInformation).validate(), ["Name may not be empty."])
  }

  func testUnderscoreIdentifier() {
    for identifier in ["_", "_Index"] {
      let index = Index<TestDocument, Bool>(name: identifier, resolver: { _ in false })
      XCTAssertEqual(StorageInformation(from: index.storageInformation).validate(), ["`\(identifier)` is an invalid name, names may not start with an `_`."])
    }
  }

  func testEquatable() {
    let boolStorageInfo = StorageInformation<TestDocument>(propertyName: .userDefined("TestIndex"), storageType: Bool.storageType, isOptional: true, sourceKeyPath: nil)
    let untypedBoolStorageInfo = StorageInformation(from: boolStorageInfo)
    XCTAssertEqual(untypedBoolStorageInfo, untypedBoolStorageInfo)

    let stringStorageInfo = StorageInformation<TestDocument>(propertyName: .userDefined("TestIndex"), storageType: String.storageType, isOptional: true, sourceKeyPath: nil)
    let untypedStringStorageInfo = StorageInformation(from: stringStorageInfo)
    XCTAssertNotEqual(untypedBoolStorageInfo, untypedStringStorageInfo)

    let otherStringStorageInfo = StorageInformation<TestDocument>(propertyName: .userDefined("OtherTestIndex"), storageType: String.storageType, isOptional: true, sourceKeyPath: nil)
    let untypedOtherStringStorageInfo = StorageInformation(from: otherStringStorageInfo)
    XCTAssertNotEqual(untypedStringStorageInfo, untypedOtherStringStorageInfo)

    let otherDocumentStorageInfo = StorageInformation<OtherTestDocument>(propertyName: .userDefined("TestIndex"), storageType: String.storageType, isOptional: true, sourceKeyPath: nil)
    let untypedOtherDocumentStorageInfo = StorageInformation(from: otherDocumentStorageInfo)
    XCTAssertNotEqual(untypedStringStorageInfo, untypedOtherDocumentStorageInfo)
  }
}

private struct TestDocument: Document {
  static var documentDescriptor = DocumentDescriptor<TestDocument>(
    name: "TestDocument",
    identifier: Identifier { _ in return UUID().uuidString },
    indices: []
  )

  func serializeDocument() throws -> Data {
    return Data()
  }

  static func deserializeDocument(from data: Data) throws -> TestDocument {
    return TestDocument()
  }
}

private struct OtherTestDocument: Document {
  static var documentDescriptor = DocumentDescriptor<OtherTestDocument>(
    name: "OtherTestDocument",
    identifier: Identifier { _ in return UUID().uuidString },
    indices: []
  )

  func serializeDocument() throws -> Data {
    return Data()
  }

  static func deserializeDocument(from data: Data) throws -> OtherTestDocument {
    return OtherTestDocument()
  }
}
