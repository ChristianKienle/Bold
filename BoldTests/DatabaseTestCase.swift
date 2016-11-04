import XCTest
import Bold

struct Person {
  let firstName:String
  let lastName:String
  let age:Int
}

class DatabaseTestCase: XCTestCase {
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
  
  // Helper
  func createPersonTable() {
    let arguments:[Bindable?] = Array<Bindable?>()
    let result = self.database.update("CREATE TABLE PERSON (firstName text, lastName text, age integer)", arguments:arguments )
    XCTAssertTrue(result.isSuccess)
  }
  
  func insertPerson(_ person:Person) {
    let result = self.database.update("INSERT INTO PERSON (firstName, lastName, age) VALUES (?, ?, ?)", arguments: [person.firstName, person.lastName, person.age])
    XCTAssertTrue(result.isSuccess)
  }
}
