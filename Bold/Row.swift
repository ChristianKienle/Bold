import Foundation

/**
  Represents a row in a result set. You cann add support for custom types just by extending Row. For an example look at boolValue(columnName:) which is simply uses intValue(columnName:) internally.
*/
public struct Row {
  private let valuesByColumnNames = [String: Bindable?]()
  init(valuesByColumnNames:[String: Bindable?]) {
    self.valuesByColumnNames = valuesByColumnNames
  }
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
  public func stringValue(columnName:String) -> String? {
    return value(columnName)
  }
  
  /**
    Used to get the int value at a specific column in the row.
    :param: columnName The name of the column you want to get the value of.
    :returns: The integer stored in the specified column.
  */
  public func intValue(columnName:String) -> Int? {
    return value(columnName)
  }
  
  /**
    Used to get the double value at a specific column in the row.
    :param: columnName The name of the column you want to get the value of.
    :returns: The double value stored in the specified column.
  */
  public func doubleValue(columnName:String) -> Double? {
    return value(columnName)
  }
  
  /**
    Used to get the data value at a specific column in the row.
    :param: columnName The name of the column you want to get the value of.
    :returns: The data stored in the specified column.
  */
  public func dataValue(columnName:String) -> NSData? {
    return value(columnName)
  }

  private func value<T>(columnName:String) -> T? {
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
  public func boolValue(columnName:String) -> Bool? {
    if let intValue = intValue(columnName) {
      return Bool(intValue)
    }
    return nil
  }
}