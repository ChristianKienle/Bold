import Cocoa
import XCTest
import Bold

class BoldTests: DatabaseTestCase {
  
  func testNullValues() {
    createPersonTable()
    let result = database.update("INSERT INTO PERSON (firstName, lastName, age) VALUES (:firstName, :lastName, :age)", arguments: ["firstName":"Christian", "lastName":nil, "age":nil])
    XCTAssertTrue(result.isSuccess)
    let queryResult = database.query("SELECT firstName, lastName, age FROM PERSON")
    XCTAssertTrue(queryResult.isSuccess)
    for row in queryResult {
      XCTAssertEqual(row.allColumnNames, ["firstName", "lastName", "age"])
      let firstName = row.stringValue(forColumn: "firstName")
      let lastName = row.stringValue(forColumn: "lastName")
      let age = row.intValue(forColumn: "age")
      XCTAssertNotNil(firstName)
      XCTAssertNil(lastName)
      XCTAssertNil(age)
    }
  }
  
  func testResultSetCanBeClosed() {
    createPersonTable()
    let result = database.update("INSERT INTO PERSON (firstName, lastName, age) VALUES (:firstName, :lastName, :age)", arguments: ["firstName":"Christian", "lastName":nil, "age":nil])
    XCTAssertTrue(result.isSuccess)
    let queryResult = database.query("SELECT * FROM PERSON")
    XCTAssertTrue(queryResult.isSuccess)
    XCTAssertTrue(queryResult.closeResultSet())
  }
  
  func testTransactions() {
    createPersonTable()
    XCTAssertTrue(database.beginTransaction())
    guard database.update("INSERT INTO PERSON (firstName, lastName, age) VALUES (:firstName, :lastName, :age)", arguments: ["firstName":"Christian", "lastName":nil, "age":nil]).isSuccess else {
      XCTFail()
      return
    }
    XCTAssertTrue(database.rollback())
    XCTAssertTrue(database.beginTransaction())
    guard database.update("INSERT INTO PERSON (firstName, lastName, age) VALUES (:firstName, :lastName, :age)", arguments: ["firstName":"Christian", "lastName":nil, "age":nil]).isSuccess else {
      XCTFail()
      return
    }
    XCTAssertTrue(database.commit())
    let queryResult = database.query("SELECT COUNT(*) AS COUNT FROM PERSON")
    XCTAssertTrue(queryResult.isSuccess)
    guard let set = queryResult.resultSet else {
      XCTFail(queryResult.error?.message ?? "")
      return
    }
    XCTAssertTrue(set.next())
    let row = set.row
    guard let count = row["COUNT"].int, count == 1 else {
      XCTFail()
      return
    }
  }
  
  func testAsyncTransactions() {
    createPersonTable()
    let ex = expectation(description: "wait for transaction to finish")
    database.async { transaction in
      guard self.database.update("INSERT INTO PERSON (firstName, lastName, age) VALUES (:firstName, :lastName, :age)", arguments: ["firstName":"Christian", "lastName":nil, "age":nil]).isSuccess else {
        XCTFail()
        return
      }
      ex.fulfill()
    }

    waitForExpectations(timeout: 0.5, handler: { error in
      let queryResult = self.database.query("SELECT COUNT(*) AS COUNT FROM PERSON")
      XCTAssertTrue(queryResult.isSuccess)
      guard let set = queryResult.resultSet else {
        XCTFail(queryResult.error?.message ?? "")
        return
      }
      XCTAssertTrue(set.next())
      let row = set.row
      guard let count = row["COUNT"].int, count == 1 else {
        XCTFail()
        return
      }
    })
  }
  
  func testMalformedQuery() {
    let result = self.database.query("CREATE TABL PERSON (firstName, lastName, age)")
    XCTAssertTrue(result.isSuccess == false)
  }
  
  func testConsumeRows() {
    self.createPersonTable()
    let persons = [Person(firstName: "Christian", lastName: "Kienle", age: 18),
      Person(firstName: "Amin", lastName: "Negm", age: 50),
      Person(firstName: "Andreas", lastName: "Kienle", age: 20)]
    for person in persons {
      insertPerson(person)
    }
    let result = self.database.query("SELECT firstName, lastName, age FROM PERSON", arguments: [:])
    var count = 0
    for row in result {
      count += 1
      XCTAssertNotNil(row.stringValue(forColumn: "firstName"))
    }
    XCTAssertTrue(count==3)
  }
  
  func testRowSubscripts() {

    XCTAssertTrue(database.update("CREATE TABLE Person (id, name, age, gender, info, picture, isCool)").isSuccess)
    
    let picture = Data(bytes: UnsafePointer<UInt8>([0xFF, 0xD9] as [UInt8]), count: 2)
    XCTAssertTrue(database.update("INSERT INTO Person (id, name, age, gender, info, picture, isCool) VALUES (:id, :name, :age, :gender, :info, :picture, :isCool)", arguments:["id" : "1", "name" : "Christian", "age" : 20, "gender" : 0.75, "info" : nil, "picture" : picture, "isCool" : true]).isSuccess)
    

    let result = database.query("SELECT * FROM Person", arguments: [:])
    guard result.isSuccess else {
      XCTFail(result.error?.message ?? "")
      return
    }
    guard let set = result.resultSet else {
      XCTFail()
      return
    }
    XCTAssertTrue(set.next())
    let row = set.row
    
    XCTAssertEqual(row["id"].string, "1")
    XCTAssertEqual(row["name"].string, "Christian")
    XCTAssertEqual(row["age"].int, 20)
    XCTAssertEqualWithAccuracy(Float(row["gender"].double ?? 0.0), Float(0.75), accuracy: Float(0.1))
    XCTAssertEqual(row["info"].string, nil)
    XCTAssertEqual(row["picture"].data, picture)
    XCTAssertEqual(row["isCool"].bool, nil)
  }

  
  func testInsertWithArgumentArray() {
    self.createPersonTable()
    let arguments:Array<Bindable?> = ["Christian", "Kienle", 1]
    
    // Insert Person
    let result = self.database.update("INSERT INTO PERSON (firstName, lastName, age) VALUES (?, ?, ?)", arguments: arguments)
    XCTAssertTrue(result.isSuccess)
  }
  
  func testInserWithArgumentsDictionary() {
    self.createPersonTable()
    
    // Insert Person
    let result = self.database.update("INSERT INTO PERSON (firstName, lastName) VALUES (:firstName, :lastName)", arguments: ["firstName" : "Christian", "lastName" : "Kienle"])
    XCTAssertTrue(result.isSuccess)
  }
  
  func testCreateTable() {
    var result = self.database.update("CREATE TABLE PERSON (firstName, lastName)", arguments: Array<Bindable?>())
    XCTAssertTrue(result.isSuccess)
    
    result = self.database.update("INSERT INTO PERSON (firstName, lastName) VALUES (?, ?)", arguments: ["Christian", "Kienle"])
    XCTAssertTrue(result.isSuccess)
    
    let queryResult = self.database.query("SELECT firstName, lastName FROM PERSON", arguments:Array<Bindable?>())
    XCTAssertTrue(queryResult.isSuccess)
    queryResult.consumeResultSet { resultSet in
      while resultSet.next() {
        let name = resultSet.row[columnIndex: 0].string
        XCTAssertEqual("Christian", name)
      }
    }
    XCTAssert(true, "Pass")
  }
  
  func testExecuteUpdate() {
    let result = self.database.query("SELECT * FROM DoesNotExist", arguments: Array<Bindable?>())
    XCTAssertTrue(result.isFailure)
    XCTAssertFalse(result.isSuccess)
    guard let error = result.error else {
      XCTFail("result set must have an error")
      return
    }
    XCTAssertEqual(error.code, Error.Code.prepareFailed)
  }

}
