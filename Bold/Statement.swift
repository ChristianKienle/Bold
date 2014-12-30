import Foundation

public class Statement {
  let statementHandle:COpaquePointer = nil
  let database:Database
  
  internal init(statementHandle:COpaquePointer, database:Database) {
    self.statementHandle = statementHandle
    self.database = database
  }
  
  internal func close() -> Bool {
    return sqlite3_finalize(statementHandle) == SQLITE_OK
  }
  
  internal func reset() -> Bool {
    return sqlite3_reset(statementHandle) == SQLITE_OK
  }
  
  // bind() supports the following types for value:
  // - String
  // - Int
  // - Double
  // - NSData
  // - nil
  internal func bind(columnIndex:Int32, value:Bindable?) -> Bool {
    if let value = value {
      return value.bindTo(self, atIndex: columnIndex)
    }
    return sqlite3_bind_null(statementHandle, columnIndex) == SQLITE_OK
  }
  
  internal func next() -> Bool {
    let status = sqlite3_step(statementHandle)
    return (status == SQLITE_ROW) || (status == SQLITE_DONE)
  }
  
  internal func value(columnIndex:Int32) -> String {
    let text = sqlite3_column_text(self.statementHandle, columnIndex)
    return String.fromCString(UnsafePointer<CChar>(text))!
  }
  
  private func columnType(columnIndex:Int32) -> Int32 {
    return sqlite3_column_type(self.statementHandle, columnIndex)
  }
}