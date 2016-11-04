import Foundation
import XCTest
import Bold

class DatabaseTests : XCTestCase {
  override func setUp() {
    super.setUp()
  }
  
  override func tearDown() {
    super.tearDown()
  }
  
  func testThatExecuteUpdateFailsOnClosedDatabase() {
    let db = Database(URL:":memory:")
    XCTAssertTrue(db.update("CREATE TABLE Person (firstName, lastName)").isFailure)
  }

  func testThatExecuteQueryFailsWithBadStatement() {
    let db = Database(URL:":memory:")
    XCTAssertTrue(db.open())
    XCTAssertTrue(db.update("this is just random noise").isFailure)
  }
  
  func testThatPragmaVacuumWorks() {
    let db = Database(URL:":memory:")
    XCTAssertTrue(db.open())
    XCTAssertTrue(db.update("VACUUM").isSuccess)
  }
  
  func testThatResultIsCaseSensitive() {
    let db = Database(URL:":memory:")
    XCTAssertTrue(db.open())
    XCTAssertTrue(db.update("CREATE TABLE Person (firstName, lastName)").isSuccess)
    XCTAssertTrue(db.update("INSERT INTO Person (firstName, lastName) VALUES (:firstName, :lastName)", arguments:["firstName" : "Christian", "lastName" : "Kienle"]).isSuccess)
    let result = db.query("SELECT firstName, lastName FROM Person")
    XCTAssertTrue(result.isSuccess)
    var consumed = false
    for row in result {
      // Is anything there?
      XCTAssertNotNil(row.stringValue(forColumn: "firstName"))
      XCTAssertNotNil(row.stringValue(forColumn: "lastName"))
      
      // Is it correct?
      XCTAssertEqual(row.stringValue(forColumn: "firstName")!, "Christian")
      XCTAssertEqual(row.stringValue(forColumn: "lastName")!, "Kienle")
      
      // Are other column values nil?
      XCTAssertNil(row.stringValue(forColumn: "firstname"))
      XCTAssertNil(row.stringValue(forColumn: "lastname"))
      
      XCTAssertNil(row.stringValue(forColumn: "FIRSTNAME"))
      XCTAssertNil(row.stringValue(forColumn: "LASTNAME"))
      
      XCTAssertNil(row.stringValue(forColumn: "doesnotexist"))
      XCTAssertNil(row.stringValue(forColumn: "hahaha"))
      
      consumed = true
    }
    XCTAssertTrue(consumed)
  }
  
  // TODO: Test more types as they are supported.
  //       Currently supported: String, Int, Double, NSData and nil
  func testSupportedTypes() {
    let db = Database(URL:":memory:")
    XCTAssertTrue(db.open())
    // gender: a double value between 0 and 1
    XCTAssertTrue(db.update("CREATE TABLE Person (id, name, age, gender, info, picture, isCool)").isSuccess)
    
    let picture = Data(bytes: UnsafePointer<UInt8>([0xFF, 0xD9] as [UInt8]), count: 2)
    XCTAssertTrue(db.update("INSERT INTO Person (id, name, age, gender, info, picture, isCool) VALUES (:id, :name, :age, :gender, :info, :picture, :isCool)", arguments:["id" : "1", "name" : "Christian", "age" : 20, "gender" : 0.75, "info" : nil, "picture" : picture, "isCool" : true]).isSuccess)
    let result = db.query("SELECT id, name, age, gender, info, picture, isCool FROM Person")
    XCTAssertTrue(result.isSuccess)
    var consumed = false
    var rowCount = 0
    for row in result {
      // Is anything there?
      XCTAssertNotNil(row.stringValue(forColumn: "id"))
      XCTAssertNotNil(row.stringValue(forColumn: "name"))
      XCTAssertNotNil(row.intValue(forColumn: "age"))
      XCTAssertNotNil(row.doubleValue(forColumn: "gender"))
      XCTAssertNil(row.stringValue(forColumn: "info"))
      XCTAssertNotNil(row.dataValue(forColumn: "picture"))
      XCTAssertNotNil(row.boolValue(forColumn: "isCool"))
      
      // Is it correct?
      XCTAssertEqual(row.stringValue(forColumn: "id"), "1")
      XCTAssertEqual(row.stringValue(forColumn: "name")!, "Christian")
      XCTAssertEqual(row.intValue(forColumn: "age")!, 20)
      if let gender = row.doubleValue(forColumn: "gender") {
        XCTAssertEqualWithAccuracy(gender, 0.75, accuracy: 0.01)
        
      } else {
        XCTFail("gender cannot be nil")
      }
      XCTAssertEqual(row.dataValue(forColumn: "picture")!, picture)
      XCTAssertEqual(row.boolValue(forColumn: "isCool")!, true)
      
      consumed = true
      rowCount += 1
    }
    XCTAssertTrue(rowCount == 1)
    XCTAssertTrue(consumed)
  }
  
  // TODO: Also test different types
  func testThatNamedParametersWorks() {
    let db = Database(URL:":memory:")
    XCTAssertTrue(db.open())
    XCTAssertTrue(db.update("CREATE TABLE Person (firstName, lastName)").isSuccess)
    XCTAssertTrue(db.update("INSERT INTO Person (firstName, lastName) VALUES (:firstName, :lastName)", arguments:["firstName" : "Christian", "lastName" : "Kienle"]).isSuccess)
    let result = db.query("SELECT firstName, lastName FROM Person")
    XCTAssertTrue(result.isSuccess)
    var consumed = false
    var rowCount = 0
    for row in result {
      // Is anything there?
      XCTAssertNotNil(row.stringValue(forColumn: "firstName"))
      XCTAssertNotNil(row.stringValue(forColumn: "lastName"))
      
      // Is it correct?
      XCTAssertEqual(row.stringValue(forColumn: "firstName")!, "Christian")
      XCTAssertEqual(row.stringValue(forColumn: "lastName")!, "Kienle")
      consumed = true
      rowCount += 1
    }
    XCTAssertTrue(rowCount == 1)
    XCTAssertTrue(consumed)
  }
  
  func testThatIndexedParametersWorks() {
    let db = Database(URL:":memory:")
    XCTAssertTrue(db.open())
    XCTAssertTrue(db.update("CREATE TABLE Person (firstName, lastName)").isSuccess)
    XCTAssertTrue(db.update("INSERT INTO Person (firstName, lastName) VALUES (?, ?)", arguments:["Christian", "Kienle"]).isSuccess)
    let result = db.query("SELECT firstName, lastName FROM Person")
    XCTAssertTrue(result.isSuccess)
    var consumed = false
    var rowCount = 0
    for row in result {
      // Is anything there?
      XCTAssertNotNil(row.stringValue(forColumn: "firstName"))
      XCTAssertNotNil(row.stringValue(forColumn: "lastName"))
      
      // Is it correct?
      XCTAssertEqual(row.stringValue(forColumn: "firstName")!, "Christian")
      XCTAssertEqual(row.stringValue(forColumn: "lastName")!, "Kienle")
      consumed = true
      rowCount += 1
    }
    XCTAssertTrue(rowCount == 1)
    XCTAssertTrue(consumed)
  }
  
  func testThatTooManyNamedArgumentsFail() {
    let db = Database(URL:":memory:")
    XCTAssertTrue(db.open())
    XCTAssertTrue(db.update("CREATE TABLE Person (firstName, lastName)").isSuccess)
    XCTAssertTrue(db.update("INSERT INTO Person (firstName, lastName) VALUES (:firstName, :lastName)", arguments:["firstName" : "Christian", "lastName" : "Kienle", "age" : 1]).isFailure)
  }

  func testThatTooManyIndexedArgumentsFail() {
    let db = Database(URL:":memory:")
    XCTAssertTrue(db.open())
    XCTAssertTrue(db.update("CREATE TABLE Person (firstName, lastName)").isSuccess)
    let args: [Bindable?] = ["Christian", "Kienle", 1]
    XCTAssertTrue(db.update("INSERT INTO Person (firstName, lastName) VALUES (?, ?)", arguments: args).isFailure)
  }

  func testThatColumnNamesCanContainPeriods() {
    let db = Database(URL:":memory:")
    XCTAssertTrue(db.open())
    XCTAssertTrue(db.update("CREATE TABLE Person (firstName, lastName)").isSuccess)
    XCTAssertTrue(db.update("INSERT INTO Person (firstName, lastName) VALUES (:firstName, :lastName)", arguments:["firstName" : "Christian", "lastName" : "Kienle"]).isSuccess)
    let result = db.query("SELECT firstName as 't.fn', lastName as 't.ln' FROM Person")
    XCTAssertTrue(result.isSuccess)
    var consumed = false
    var rowCount = 0
    for row in result {
        // Is anything there?
        XCTAssertNotNil(row.stringValue(forColumn: "t.fn"))
        XCTAssertNotNil(row.stringValue(forColumn: "t.ln"))
        
        // Is it correct?
        XCTAssertEqual(row.stringValue(forColumn: "t.fn")!, "Christian")
        XCTAssertEqual(row.stringValue(forColumn: "t.ln")!, "Kienle")
        consumed = true
        rowCount += 1
    }
    XCTAssertTrue(rowCount == 1)
    XCTAssertTrue(consumed)
  }
  
  func testThatForLoopIsWorking() {
    let db = Database(URL:":memory:")
    XCTAssertTrue(db.open())
    XCTAssertTrue(db.update("CREATE TABLE Person (firstName, lastName)").isSuccess)
    XCTAssertTrue(db.update("INSERT INTO Person (firstName, lastName) VALUES (:firstName, :lastName)", arguments:["firstName" : "Christian", "lastName" : "Kienle"]).isSuccess)
    XCTAssertTrue(db.update("INSERT INTO Person (firstName, lastName) VALUES (:firstName, :lastName)", arguments:["firstName" : "Irina", "lastName" : "Kienle"]).isSuccess)
    let result = db.query("SELECT firstName, lastName FROM Person")
    XCTAssertTrue(result.isSuccess)
    var count = 0
    for row in result {
      XCTAssertNotNil(row.stringValue(forColumn: "firstName"))
      XCTAssertNotNil(row.stringValue(forColumn: "lastName"))
      
      // Is it correct?
      if count == 0 {
        XCTAssertEqual(row.stringValue(forColumn: "firstName")!, "Christian")
        XCTAssertEqual(row.stringValue(forColumn: "lastName")!, "Kienle")
      }
      if count == 1 {
        XCTAssertEqual(row.stringValue(forColumn: "firstName")!, "Irina")
        XCTAssertEqual(row.stringValue(forColumn: "lastName")!, "Kienle")
      }
      count += 1
    }
    XCTAssertTrue(count == 2)
    
  }
}





