import Foundation

/**
 Represents a row in a result set. You cann add support for custom types just by extending Row. For an example look at boolValue(columnName:) which is simply uses intValue(columnName:) internally.
 */
public struct Row {
  fileprivate var valuesByColumnNames = [String: Bindable?]()
  init(valuesByColumnNames:[String: Bindable?]) {
    self.valuesByColumnNames = valuesByColumnNames
  }
  public subscript(column: String) -> SQLValue {
    return SQLValue()
  }
}

public struct SQLValue {
  
}

// MARK: General
extension Row {
  /**
   All column names of the row.
   */
  public var allColumnNames:[String] {
    return Array(self.valuesByColumnNames.keys)
  }
}

// MARK: Extracting Values
extension Row {
  /**
   Used to get the string value at a specific column in the row.
   :param: columnName The name of the column you want to get the value of.
   :returns: The string stored in the specified column.
   */
  public func stringValue(forColumn columnName:String) -> String? {
    return value(forColumn: columnName)
  }
  
  /**
   Used to get the int value at a specific column in the row.
   :param: columnName The name of the column you want to get the value of.
   :returns: The integer stored in the specified column.
   */
  public func intValue(forColumn columnName:String) -> Int? {
    return value(forColumn: columnName)
  }
  
  /**
   Used to get the double value at a specific column in the row.
   :param: columnName The name of the column you want to get the value of.
   :returns: The double value stored in the specified column.
   */
  public func doubleValue(forColumn columnName:String) -> Double? {
    return value(forColumn: columnName)
  }
  
  /**
   Used to get the data value at a specific column in the row.
   :param: columnName The name of the column you want to get the value of.
   :returns: The data stored in the specified column.
   */
  public func dataValue(forColumn columnName:String) -> Data? {
    return value(forColumn: columnName)
  }
  
  fileprivate func value<T>(forColumn columnName:String) -> T? {
    return self.valuesByColumnNames[columnName] as? T
  }
}

// MARK: Convenience
extension Row {
  /**
   Used to get the bool value at a specific column in the row.
   :param: columnName The name of the column you want to get the value of.
   :returns: The boolean value stored in the specified column.
   */
  public func boolValue(forColumn columnName:String) -> Bool? {
    guard let intValue = intValue(forColumn: columnName) else {
      return nil
    }
    switch intValue {
    case 0: return false
    case 1: return true
    default: return nil
    }
  }
}
