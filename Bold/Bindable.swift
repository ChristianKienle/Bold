import Foundation

// MARK: Bindable Protocol
/**
  Types which conform to Bindable can be used as arguments for the following methods:
  
  - executeQuery(query:arguments:)
  - executeQuery(query)
  - executeUpdate(query:arguments:)
  - executeUpdate(query:)

  In order to a type to be bindable it has to know how to bind itself to a column in a Statement. If you want to add support for custom types simply implement Bindable in an extension for those types.

  The following types adopt this protocol by default:
  
  - String
  - Int
  - Double
  - NSData
  - Bool
*/
public protocol Bindable  {
  /**
    Binds a SQL representation of self to a column in a given statement. If you want to implement this method you have two options:
  
    1. Use an existing implementation of Bindable. For example: If your custom type can be represented by a simple string then create a string representation of self and then use the existing implementation of Bindable string.bindTo(statement:atIndex)
    2. If you have special needs then you can access the raw SQLite statement handle (statement.statementHandle) and call one of the sqlite3_bind* functions. This allows you to fully customize the binding process.
  
    :param: to statement A statement which self has to be bound.
    :param: atIndex The index of the column which self has to be bound.
    :returns: true if self could be bound to the statement, otherwise false.
  */
  func bind(to statement: Statement, atIndex index: Int32) -> Bool
}

// MARK: Convenience
private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

// MARK: Types conforming to Bindable by default
extension String : Bindable {
  public func bind(to statement:Statement, atIndex index : Int32) -> Bool {
    return utf8CString.withUnsafeBufferPointer { ptr in
      return sqlite3_bind_text(statement.statementHandle, index, ptr.baseAddress, -1, SQLITE_TRANSIENT) == SQLITE_OK
    }
  }
}

extension Int : Bindable {
  public func bind(to statement: Statement, atIndex index: Int32) -> Bool {
    let status = sqlite3_bind_int(statement.statementHandle, index, Int32(self))
    return status == SQLITE_OK
  }
}

extension Double : Bindable {
  public func bind(to statement: Statement, atIndex index:Int32) -> Bool {
    let status = sqlite3_bind_double(statement.statementHandle, index, self)
    return status == SQLITE_OK
  }
}

extension Data : Bindable {
  public func bind(to statement: Statement, atIndex index: Int32) -> Bool {
    var values = [UInt8](repeating:0, count:count)
    copyBytes(to: &values, count: count)
    let status = sqlite3_bind_blob(statement.statementHandle, index, values, Int32(count), SQLITE_TRANSIENT)
    return status == SQLITE_OK
  }
}

extension Bool : Bindable {
  public func bind(to statement: Statement, atIndex index:Int32) -> Bool {
    let intValue = self ? 1 : 0
    return intValue.bind(to: statement, atIndex: index)
  }
}
