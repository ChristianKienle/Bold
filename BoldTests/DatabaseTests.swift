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
    XCTAssertTrue(db.executeUpdate("CREATE TABLE Person (firstName, lastName)").isFailure)
  }

  func testThatExecuteQueryFailsWithBadStatement() {
    let db = Database(URL:":memory:")
    XCTAssertTrue(db.open())
    XCTAssertTrue(db.executeUpdate("this is just random noise").isFailure)
  }
  
  func testThatPragmaVacuumWorks() {
    let db = Database(URL:":memory:")
    XCTAssertTrue(db.open())
    XCTAssertTrue(db.executeUpdate("VACUUM").isSuccess)
  }
  
  func testThatResultIsCaseSensitive() {
    let db = Database(URL:":memory:")
    XCTAssertTrue(db.open())
    XCTAssertTrue(db.executeUpdate("CREATE TABLE Person (firstName, lastName)").isSuccess)
    XCTAssertTrue(db.executeUpdate("INSERT INTO Person (firstName, lastName) VALUES (:firstName, :lastName)", arguments:["firstName" : "Christian", "lastName" : "Kienle"]).isSuccess)
    let result = db.executeQuery("SELECT firstName, lastName FROM Person")
    XCTAssertTrue(result.isSuccess)
    var consumed = false
    for row in result {
      // Is anything there?
      XCTAssertNotNil(row.stringValue("firstName"))
      XCTAssertNotNil(row.stringValue("lastName"))
      
      // Is it correct?
      XCTAssertEqual(row.stringValue("firstName")!, "Christian")
      XCTAssertEqual(row.stringValue("lastName")!, "Kienle")
      
      // Are other column values nil?
      XCTAssertNil(row.stringValue("firstname"))
      XCTAssertNil(row.stringValue("lastname"))
      
      XCTAssertNil(row.stringValue("FIRSTNAME"))
      XCTAssertNil(row.stringValue("LASTNAME"))
      
      XCTAssertNil(row.stringValue("doesnotexist"))
      XCTAssertNil(row.stringValue("hahaha"))
      
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
    XCTAssertTrue(db.executeUpdate("CREATE TABLE Person (id, name, age, gender, info, picture, isCool)").isSuccess)
    
    let picture = Data(bytes: UnsafePointer<UInt8>([0xFF, 0xD9] as [UInt8]), count: 2)
    XCTAssertTrue(db.executeUpdate("INSERT INTO Person (id, name, age, gender, info, picture, isCool) VALUES (:id, :name, :age, :gender, :info, :picture, :isCool)", arguments:["id" : "1", "name" : "Christian", "age" : 20, "gender" : 0.75, "info" : nil, "picture" : picture, "isCool" : true]).isSuccess)
    let result = db.executeQuery("SELECT id, name, age, gender, info, picture, isCool FROM Person")
    XCTAssertTrue(result.isSuccess)
    var consumed = false
    var rowCount = 0
    for row in result {
      // Is anything there?
      XCTAssertNotNil(row.stringValue("id"))
      XCTAssertNotNil(row.stringValue("name"))
      XCTAssertNotNil(row.intValue("age"))
      XCTAssertNotNil(row.doubleValue("gender"))
      XCTAssertNil(row.stringValue("info"))
      XCTAssertNotNil(row.dataValue("picture"))
      XCTAssertNotNil(row.boolValue("isCool"))
      
      // Is it correct?
      XCTAssertEqual(row.stringValue("id")!, "1")
      XCTAssertEqual(row.stringValue("name")!, "Christian")
      XCTAssertEqual(row.intValue("age")!, 20)
      if let gender = row.doubleValue("gender") {
        XCTAssertEqualWithAccuracy(gender, 0.75, accuracy: 0.01)
        
      } else {
        XCTFail("gender cannot be nil")
      }
      XCTAssertEqual(row.dataValue("picture")!, picture)
      XCTAssertEqual(row.boolValue("isCool")!, true)
      
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
    XCTAssertTrue(db.executeUpdate("CREATE TABLE Person (firstName, lastName)").isSuccess)
    XCTAssertTrue(db.executeUpdate("INSERT INTO Person (firstName, lastName) VALUES (:firstName, :lastName)", arguments:["firstName" : "Christian", "lastName" : "Kienle"]).isSuccess)
    let result = db.executeQuery("SELECT firstName, lastName FROM Person")
    XCTAssertTrue(result.isSuccess)
    var consumed = false
    var rowCount = 0
    for row in result {
      // Is anything there?
      XCTAssertNotNil(row.stringValue("firstName"))
      XCTAssertNotNil(row.stringValue("lastName"))
      
      // Is it correct?
      XCTAssertEqual(row.stringValue("firstName")!, "Christian")
      XCTAssertEqual(row.stringValue("lastName")!, "Kienle")
      consumed = true
      rowCount += 1
    }
    XCTAssertTrue(rowCount == 1)
    XCTAssertTrue(consumed)
  }
  
  func testThatIndexedParametersWorks() {
    let db = Database(URL:":memory:")
    XCTAssertTrue(db.open())
    XCTAssertTrue(db.executeUpdate("CREATE TABLE Person (firstName, lastName)").isSuccess)
    XCTAssertTrue(db.executeUpdate("INSERT INTO Person (firstName, lastName) VALUES (?, ?)", arguments:["Christian", "Kienle"]).isSuccess)
    let result = db.executeQuery("SELECT firstName, lastName FROM Person")
    XCTAssertTrue(result.isSuccess)
    var consumed = false
    var rowCount = 0
    for row in result {
      // Is anything there?
      XCTAssertNotNil(row.stringValue("firstName"))
      XCTAssertNotNil(row.stringValue("lastName"))
      
      // Is it correct?
      XCTAssertEqual(row.stringValue("firstName")!, "Christian")
      XCTAssertEqual(row.stringValue("lastName")!, "Kienle")
      consumed = true
      rowCount += 1
    }
    XCTAssertTrue(rowCount == 1)
    XCTAssertTrue(consumed)
  }
  
  func testThatTooManyNamedArgumentsFail() {
    let db = Database(URL:":memory:")
    XCTAssertTrue(db.open())
    XCTAssertTrue(db.executeUpdate("CREATE TABLE Person (firstName, lastName)").isSuccess)
    XCTAssertTrue(db.executeUpdate("INSERT INTO Person (firstName, lastName) VALUES (:firstName, :lastName)", arguments:["firstName" : "Christian", "lastName" : "Kienle", "age" : 1]).isFailure)
  }

  func testThatTooManyIndexedArgumentsFail() {
    let db = Database(URL:":memory:")
    XCTAssertTrue(db.open())
    XCTAssertTrue(db.executeUpdate("CREATE TABLE Person (firstName, lastName)").isSuccess)
    XCTAssertTrue(db.executeUpdate("INSERT INTO Person (firstName, lastName) VALUES (?, ?)", arguments:["Christian", "Kienle", 1]).isFailure)
  }

  func testThatColumnNamesCanContainPeriods() {
    let db = Database(URL:":memory:")
    XCTAssertTrue(db.open())
    XCTAssertTrue(db.executeUpdate("CREATE TABLE Person (firstName, lastName)").isSuccess)
    XCTAssertTrue(db.executeUpdate("INSERT INTO Person (firstName, lastName) VALUES (:firstName, :lastName)", arguments:["firstName" : "Christian", "lastName" : "Kienle"]).isSuccess)
    let result = db.executeQuery("SELECT firstName as 't.fn', lastName as 't.ln' FROM Person")
    XCTAssertTrue(result.isSuccess)
    var consumed = false
    var rowCount = 0
    for row in result {
        // Is anything there?
        XCTAssertNotNil(row.stringValue("t.fn"))
        XCTAssertNotNil(row.stringValue("t.ln"))
        
        // Is it correct?
        XCTAssertEqual(row.stringValue("t.fn")!, "Christian")
        XCTAssertEqual(row.stringValue("t.ln")!, "Kienle")
        consumed = true
        rowCount += 1
    }
    XCTAssertTrue(rowCount == 1)
    XCTAssertTrue(consumed)
  }
  
  func testThatForLoopIsWorking() {
    let db = Database(URL:":memory:")
    XCTAssertTrue(db.open())
    XCTAssertTrue(db.executeUpdate("CREATE TABLE Person (firstName, lastName)").isSuccess)
    XCTAssertTrue(db.executeUpdate("INSERT INTO Person (firstName, lastName) VALUES (:firstName, :lastName)", arguments:["firstName" : "Christian", "lastName" : "Kienle"]).isSuccess)
    XCTAssertTrue(db.executeUpdate("INSERT INTO Person (firstName, lastName) VALUES (:firstName, :lastName)", arguments:["firstName" : "Irina", "lastName" : "Kienle"]).isSuccess)
    let result = db.executeQuery("SELECT firstName, lastName FROM Person")
    XCTAssertTrue(result.isSuccess)
    var count = 0
    for row in result {
      XCTAssertNotNil(row.stringValue("firstName"))
      XCTAssertNotNil(row.stringValue("lastName"))
      
      // Is it correct?
      if count == 0 {
        XCTAssertEqual(row.stringValue("firstName")!, "Christian")
        XCTAssertEqual(row.stringValue("lastName")!, "Kienle")
      }
      if count == 1 {
        XCTAssertEqual(row.stringValue("firstName")!, "Irina")
        XCTAssertEqual(row.stringValue("lastName")!, "Kienle")
      }
      count += 1
    }
    XCTAssertTrue(count == 2)
    
  }
}





