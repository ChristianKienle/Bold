import Foundation

/**
  Represents a result set. You usually do not interact with the result set directly but you can.
*/
final public class ResultSet {
  fileprivate let statement: Statement
  
  // MARK: Creating
  public init(statement: Statement) {
    self.statement = statement
  }
  
  // MARK: General
  /**
    Moves the cursor to the next row in the result set. Before you can access anything in the result set you have to call next at least once.
  
    :returns: true if there is another row, false if there isn't or if an error occurred.
  */
  public func next() -> Bool {
    return step() == SQLITE_ROW
  }
  
  /**
    Closes the result set.
  
    :returns: true if the result set could be closed, otherwise false.
  */
  public func close() -> Bool {
    return statement.close()
  }
  
  /**
    Returns the number of columns in the result set.
  */
  public var columnCount:Int32 {
    return sqlite3_column_count(statement.statementHandle)
  }

  internal func step() -> Int32 {
    return sqlite3_step(statement.statementHandle)
  }
}

// MARK: Get a row representation
public extension ResultSet {
  /**
    Gets the current row.
  */
  public var row: Row {
    var valuesByColumnNames = [String:Bindable?]()
    let columnIndexes = (0..<columnCount)
    columnIndexes.forEach { index in
      guard let rawColumnName = sqlite3_column_name(statement.statementHandle, index) else {
        return
      }
      let columnName = String(cString: rawColumnName)
      let value = self.value(forColumn: index)
      valuesByColumnNames[columnName] = value
    }
    return Row(valuesByColumnNames:valuesByColumnNames)
  }
}

// MARK: Getting values
extension ResultSet {
  /**
    Used to get the string value of the column at a specific column in the current row.
    :param: columnIndex The index of the column.
    :returns: The string value of the column at the specified column in the current row.
  */
  public func stringValue(forColumn columnIndex:Int32) -> String {
    guard let text = sqlite3_column_text(statement.statementHandle, columnIndex) else {
      return ""
    }
    return String(cString: text)
  }
  
  /**
    Used to get the32 string value of the column at a specific column in the current row.
    :param: columnIndex The index of the column.
    :returns: The int32 value of the column at the specified column in the current row.
  */
  public func int32Value(forColumn columnIndex:Int32) -> Int32 {
    let value:Int32 = sqlite3_column_int(statement.statementHandle, columnIndex)
    return value
  }
  
  /**
    Used to get the int value of the column at a specific column in the current row.
    :param: columnIndex The index of the column.
    :returns: The int value of the column at the specified column in the current row.
  */
  public func intValue(forColumn columnIndex:Int32) -> Int {
    let value = int32Value(forColumn: columnIndex)
    return Int(value)
  }
  
  /**
    Used to get the double value of the column at a specific column in the current row.
    :param: columnIndex The index of the column.
    :returns: The double value of the column at the specified column in the current row.
  */
  public func doubleValue(forColumn columnIndex:Int32) -> Double {
    let value = sqlite3_column_double(statement.statementHandle, columnIndex)
    return value
  }
  
  /**
    Used to get the data value of the column at a specific column in the current row.
    :param: columnIndex The index of the column.
    :returns: The data value of the column at the specified column in the current row.
  */
  public func dataValue(forColumn columnIndex:Int32) -> Data {
    let rawData:UnsafeRawPointer = sqlite3_column_blob(statement.statementHandle, columnIndex)
    let size:Int = Int(sqlite3_column_bytes(statement.statementHandle, columnIndex))
    let value = Data(bytes: rawData, count: size)
    return value
  }
  
  internal func value(forColumn
    columnIndex:Int32) -> Bindable? {
    let columnType = sqlite3_column_type(statement.statementHandle, columnIndex)
    if columnType == SQLITE_TEXT {
      return stringValue(forColumn: columnIndex)
    }
    if columnType == SQLITE_INTEGER {
      return intValue(forColumn: columnIndex)
    }
    if columnType == SQLITE_FLOAT {
      return doubleValue(forColumn: columnIndex)
    }
    if columnType == SQLITE_NULL {
      return nil
    }
    if columnType == SQLITE_BLOB {
      return dataValue(forColumn: columnIndex)
    }
    return nil
  }
}
