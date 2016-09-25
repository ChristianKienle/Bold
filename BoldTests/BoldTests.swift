import Cocoa
import XCTest
import Bold

struct Person {
  let firstName:String
  let lastName:String
  let age:Int
}

class BoldTests: XCTestCase {
  var database: Database!
  override func setUp() {
    super.setUp()
    self.database = Database(URL: ":memory:")
    let _ = self.database?.open()
  }
  
  override func tearDown() {
    super.tearDown()
    let _ = self.database?.close()
  }
  
  func testNullValues() {
    createPersonTable()
    let result = database.executeUpdate("INSERT INTO PERSON (firstName, lastName, age) VALUES (:firstName, :lastName, :age)", arguments: ["firstName":"Christian", "lastName":nil, "age":nil])
    XCTAssertTrue(result.isSuccess)
    let queryResult = database.executeQuery("SELECT * FROM PERSON")
    XCTAssertTrue(queryResult.isSuccess)
    for row in queryResult {
      let firstName = row.stringValue("firstName")
      let lastName = row.stringValue("lastName")
      let age = row.intValue("age")
      XCTAssertNotNil(firstName)
      XCTAssertNil(lastName)
      XCTAssertNil(age)
    }
  }
  
  func testMalformedQuery() {
    let result = self.database.executeQuery("CREATE TABL PERSON (firstName, lastName, age)")
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
    let result = self.database.executeQuery("SELECT firstName, lastName, age FROM PERSON", arguments: [])
    var count = 0
    for row in result {
      count += 1
      let firstName = row.stringValue("firstName")
      NSLog("fn: %@", firstName!)
      return ()
    }
    XCTAssertTrue(count==3)
  }
  
  func testInsertWithArgumentArray() {
    self.createPersonTable()
    let arguments:Array<Bindable?> = ["Christian", "Kienle", 1]
    
    // Insert Person
    let result = self.database.executeUpdate("INSERT INTO PERSON (firstName, lastName, age) VALUES (?, ?, ?)", arguments: arguments)
    XCTAssertTrue(result.isSuccess)
  }
  
  func testInserWithArgumentsDictionary() {
    self.createPersonTable()
    
    // Insert Person
    let result = self.database.executeUpdate("INSERT INTO PERSON (firstName, lastName) VALUES (:firstName, :lastName)", arguments: ["firstName" : "Christian", "lastName" : "Kienle"])
    XCTAssertTrue(result.isSuccess)
  }
  
  func testCreateTable() {
    var result = self.database.executeUpdate("CREATE TABLE PERSON (firstName, lastName)", arguments: Array<Bindable?>())
    XCTAssertTrue(result.isSuccess)
    
    result = self.database.executeUpdate("INSERT INTO PERSON (firstName, lastName) VALUES (?, ?)", arguments: ["Christian", "Kienle"])
    XCTAssertTrue(result.isSuccess)
    
    let queryResult = self.database.executeQuery("SELECT firstName, lastName FROM PERSON", arguments:Array<Bindable?>())
    XCTAssertTrue(queryResult.isSuccess)
    queryResult.consumeResultSet { resultSet in
      while resultSet.next() {
        let name = resultSet.stringValue(0)
        XCTAssertEqual("Christian", name)
      }
    }
    XCTAssert(true, "Pass")
  }
  
  func testExecuteUpdate() {
    let result = self.database.executeQuery("SELECT * FROM PENIS", arguments: Array<Bindable?>())
    switch result {
    case .success( _):
      NSLog("success")
    case .failure( _):
      NSLog("error");
    }
  }
  
  // Helper
  fileprivate func createPersonTable() {
    let arguments:[Bindable?] = Array<Bindable?>()
    let result = self.database.executeUpdate("CREATE TABLE PERSON (firstName text, lastName text, age integer)", arguments:arguments )
    XCTAssertTrue(result.isSuccess)
  }
  
  fileprivate func insertPerson(_ person:Person) {
    let result = self.database.executeUpdate("INSERT INTO PERSON (firstName, lastName, age) VALUES (?, ?, ?)", arguments: [person.firstName, person.lastName, person.age])
    XCTAssertTrue(result.isSuccess)
  }
}
