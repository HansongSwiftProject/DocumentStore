//
//  ReadWriteTransactionTests.swift
//  DocumentStore
//
//  Created by Mathijs Kadijk on 14-11-16.
//  Copyright © 2016 Mathijs Kadijk. All rights reserved.
//

import XCTest
@testable import DocumentStore

class ReadWriteTransactionTests: XCTestCase {

  private var testTransaction = MockTransaction()
  private var transaction = ReadWriteTransaction(transaction: MockTransaction())

  override func setUp() {
    super.setUp()
    testTransaction = MockTransaction()
    transaction = ReadWriteTransaction(transaction: testTransaction)
  }

  func testCount() {
    do {
      let count = try transaction.count(matching: Query<TestDocument>())
      XCTAssertEqual(count, 42)
      XCTAssertEqual(testTransaction.countCalls, 1)
      XCTAssertEqual(testTransaction.fetchCalls, 0)
      XCTAssertEqual(testTransaction.deleteCalls, 0)
      XCTAssertEqual(testTransaction.addCalls, 0)
      XCTAssertEqual(testTransaction.saveCalls, 0)
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testFetch() {
    do {
      let result = try transaction.fetch(matching: Query<TestDocument>())
      XCTAssertEqual(result.count, 2)
      XCTAssertEqual(testTransaction.countCalls, 0)
      XCTAssertEqual(testTransaction.fetchCalls, 1)
      XCTAssertEqual(testTransaction.deleteCalls, 0)
      XCTAssertEqual(testTransaction.addCalls, 0)
      XCTAssertEqual(testTransaction.saveCalls, 0)
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testDelete() {
    do {
      let count = try transaction.delete(matching: Query<TestDocument>())
      XCTAssertEqual(count, 1)
      XCTAssertEqual(testTransaction.countCalls, 0)
      XCTAssertEqual(testTransaction.fetchCalls, 0)
      XCTAssertEqual(testTransaction.deleteCalls, 1)
      XCTAssertEqual(testTransaction.addCalls, 0)
      XCTAssertEqual(testTransaction.saveCalls, 0)
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testAdd() {
    do {
      let document = TestDocument()
      try transaction.add(document: document)
      XCTAssertEqual(testTransaction.countCalls, 0)
      XCTAssertEqual(testTransaction.fetchCalls, 0)
      XCTAssertEqual(testTransaction.deleteCalls, 0)
      XCTAssertEqual(testTransaction.addCalls, 1)
      XCTAssertEqual(testTransaction.saveCalls, 0)
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testSave() {
    do {
      try transaction.saveChanges()
      XCTAssertEqual(testTransaction.countCalls, 0)
      XCTAssertEqual(testTransaction.fetchCalls, 0)
      XCTAssertEqual(testTransaction.deleteCalls, 0)
      XCTAssertEqual(testTransaction.addCalls, 0)
      XCTAssertEqual(testTransaction.saveCalls, 1)
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }
}

private struct TestDocument: Document {
  static let documentDescriptor = DocumentDescriptor<TestDocument>(identifier: "", indices: [])

  func serializeDocument() throws -> Data {
    return Data()
  }

  static func deserializeDocument(from data: Data) throws -> TestDocument {
    return TestDocument()
  }
}
