import Foundation

final public class Statement {
  let statementHandle: OpaquePointer?
  let database: Database
  
  internal init(statementHandle: OpaquePointer, database: Database) {
    self.statementHandle = statementHandle
    self.database = database
  }
  
  internal func close() -> Bool {
    return sqlite3_finalize(statementHandle) == SQLITE_OK
  }
  
  // bind() supports the following types for value:
  // - String
  // - Int
  // - Double
  // - NSData
  // - nil
  internal func bind(_ columnIndex:Int32, value:Bindable?) -> Bool {
    guard let value = value else {
      return sqlite3_bind_null(statementHandle, columnIndex) == SQLITE_OK
    }
    return value.bind(to: self, atIndex: columnIndex)
  }
}
