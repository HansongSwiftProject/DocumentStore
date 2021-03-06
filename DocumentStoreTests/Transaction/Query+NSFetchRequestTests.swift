//
//  Query+NSFetchRequestTests.swift
//  DocumentStore
//
//  Created by Mathijs Kadijk on 13-11-16.
//  Copyright © 2016 Mathijs Kadijk. All rights reserved.
//

import XCTest
@testable import DocumentStore
import CoreData

class QueryNSFetchRequestTests: XCTestCase {

  private var query = Query<TestDocument>()

  override func setUp() {
    super.setUp()

    query = Query<TestDocument>()
    query.predicate = !TestDocument.isTest
    query.skip = 42
  }

  func testFetchRequestEntityName() {
    let request: NSFetchRequest<NSManagedObject> = query.fetchRequest()
    XCTAssertEqual(request.entityName, TestDocument.documentDescriptor.name)
  }

  func testFetchRequestPredicate() {
    let request: NSFetchRequest<NSManagedObject> = query.fetchRequest()
    XCTAssertEqual(request.predicate, query.predicate?.foundationPredicate)
  }

  func testFetchRequestFetchOffset() {
    let request: NSFetchRequest<NSManagedObject> = query.fetchRequest()
    XCTAssertEqual(request.fetchOffset, Int(query.skip))
  }

  func testFetchRequestFetchOffsetMaxUInt() {
    var query = self.query
    query.skip = UInt.max
    let request: NSFetchRequest<NSManagedObject> = query.fetchRequest()
    XCTAssertEqual(request.fetchOffset, Int.max)
  }

  func testFetchRequestFetchLimitNil() {
    let request: NSFetchRequest<NSManagedObject> = query.fetchRequest()
    XCTAssertEqual(request.fetchLimit, 0)
  }

  func testFetchRequestFetchLimit() {
    let limit = 24
    var query = self.query
    query.limit = UInt(limit)
    let request: NSFetchRequest<NSManagedObject> = query.fetchRequest()
    XCTAssertEqual(request.fetchLimit, limit)
  }

  func testFetchRequestFetchLimitMaxUInt() {
    let limit = UInt(Int32.max)

    var query = self.query
    query.limit = limit
    let request: NSFetchRequest<NSManagedObject> = query.fetchRequest()

    XCTAssertEqual(UInt(request.fetchLimit), limit)
  }

  func testFetchRequestSortDescriptorsWhenUnordered() {
    let request: NSFetchRequest<NSManagedObject> = query.fetchRequest()
    XCTAssertNil(request.sortDescriptors)
  }

  func testFetchRequestSortDescriptors() {
    let sortDescriptor = SortDescriptor(index: TestDocument.isTest, order: .ascending)
    let sortedQuery = query.sorted(by: sortDescriptor)
    let request: NSFetchRequest<NSManagedObject> = sortedQuery.fetchRequest()

    guard let sortDescriptors = request.sortDescriptors else {
      XCTFail("Sort descriptors empty.")
      return
    }

    XCTAssertEqual(sortDescriptors, [sortDescriptor].map { $0.foundationSortDescriptor })
  }

  func testFetchRequestResultType() {
    let requestObject: NSFetchRequest<NSManagedObject> = query.fetchRequest()
    XCTAssertEqual(requestObject.resultType, .managedObjectResultType)

    let requestId: NSFetchRequest<NSManagedObjectID> = query.fetchRequest()
    XCTAssertEqual(requestId.resultType, .managedObjectIDResultType)

    let requestDict: NSFetchRequest<NSDictionary> = query.fetchRequest()
    XCTAssertEqual(requestDict.resultType, .dictionaryResultType)

    let requestCount: NSFetchRequest<NSNumber> = query.fetchRequest()
    XCTAssertEqual(requestCount.resultType, .countResultType)
  }
}

private struct TestDocument: Document, Codable {
  static let isTest = Index<TestDocument, Bool>(name: "") { _ in false }
  static let documentDescriptor = DocumentDescriptor<TestDocument>(name: "TestDocument", identifier: Identifier { _ in return UUID().uuidString }, indices: [])

  func serializeDocument() throws -> Data {
    return Data()
  }

  static func deserializeDocument(from data: Data) throws -> TestDocument {
    return TestDocument()
  }
}
