//
//  QueryTests.swift
//  DocumentStore
//
//  Created by Mathijs Kadijk on 12-11-16.
//  Copyright © 2016 Mathijs Kadijk. All rights reserved.
//

import XCTest
@testable import DocumentStore

class QueryTests: XCTestCase {

  private var query = Query<TestDocument>()

  override func setUp() {
    super.setUp()
    query = Query<TestDocument>()
  }

  func testNoRestrictionsByDefault() {
    XCTAssertNil(query.predicate)
    XCTAssertEqual(query.skip, 0)
    XCTAssertNil(query.limit)
  }

  // MARK: Limiting

  func testSkipping() {
    XCTAssertEqual(query.skip, 0)

    query = query.skipping(upTo: 3)
    XCTAssertEqual(query.skip, 3)

    query = query.skipping(upTo: 0)
    XCTAssertEqual(query.skip, 3)

    query = query.skipping(upTo: 1)
    XCTAssertEqual(query.skip, 4)
  }

  func testLimited() {
    XCTAssertNil(query.limit)

    query = query.limited(upTo: 3)
    XCTAssertEqual(query.limit, 3)

    query = query.limited(upTo: 2)
    XCTAssertEqual(query.limit, 2)

    query = query.limited(upTo: 3)
    XCTAssertEqual(query.limit, 2)
  }

  // MARK: Filtering

  func testFiltered() {
    XCTAssertNil(query.predicate)

    let predicate: Predicate<TestDocument> = TestDocument.isTest == false
    query = query.filtered(by: predicate)
    XCTAssertEqual(query.predicate?.foundationPredicate, predicate.foundationPredicate)

    query = query.filtered(by: predicate)
    XCTAssertEqual(query.predicate?.foundationPredicate, (predicate && predicate).foundationPredicate)
  }

  // MARK: Sorting

  func testSorted() {

    let sortDescriptor = SortDescriptor(index: TestDocument.isTest, order: .ascending)
    var orderedQuery = query.sorted(by: sortDescriptor)
    XCTAssertEqual(orderedQuery.sortDescriptors.map { $0.foundationSortDescriptor }, [sortDescriptor.foundationSortDescriptor])

    let otherSortDescriptor = SortDescriptor(index: TestDocument.isTest, order: .descending)
    orderedQuery = orderedQuery.sorted(by: otherSortDescriptor)
    XCTAssertEqual(orderedQuery.sortDescriptors.map { $0.foundationSortDescriptor }, [otherSortDescriptor.foundationSortDescriptor])
  }

  func testThenSorted() {
    let appendedSortDescriptor = SortDescriptor(index: TestDocument.isTest, order: .ascending)

    var query = self.query
    query.sortDescriptors = [SortDescriptor(index: TestDocument.isTest, order: .descending)]

    let sortedQuery = query.thenSorted(by: appendedSortDescriptor)
    let allSortDescriptors = query.sortDescriptors + [appendedSortDescriptor]
    XCTAssertEqual(sortedQuery.sortDescriptors.map { $0.foundationSortDescriptor }, allSortDescriptors.map { $0.foundationSortDescriptor })
  }
}

private struct TestDocument: Document, Codable {
  static let isTest = Index<TestDocument, Bool>(name: "") { _ in false }
  static let documentDescriptor = DocumentDescriptor<TestDocument>(name: "", identifier: Identifier { _ in return UUID().uuidString }, indices: [])
}
