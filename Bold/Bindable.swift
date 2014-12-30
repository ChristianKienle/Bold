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
  
    :param: statement A statement which self has to be bound.
    :param: atIndex The index of the column which self has to be bound.
    :returns: true if self could be bound to the statement, otherwise false.
  */
  func bindTo(statement:Statement, atIndex:Int32) -> Bool
}

// MARK: Convenience
private let SQLITE_TRANSIENT = sqlite3_destructor_type(COpaquePointer(bitPattern: -1))

// MARK: Types conforming to Bindable by default
extension String : Bindable {
  public func bindTo(statement:Statement, atIndex:Int32) -> Bool {
    let status = sqlite3_bind_text(statement.statementHandle, atIndex, self.cStringUsingEncoding(NSUTF8StringEncoding)!, -1, SQLITE_TRANSIENT)
    return status == SQLITE_OK
  }
}

extension Int : Bindable {
  public func bindTo(statement:Statement, atIndex:Int32) -> Bool {
    let status = sqlite3_bind_int(statement.statementHandle, atIndex, Int32(self))
    return status == SQLITE_OK
  }
}

extension Double : Bindable {
  public func bindTo(statement:Statement, atIndex:Int32) -> Bool {
    let status = sqlite3_bind_double(statement.statementHandle, atIndex, self)
    return status == SQLITE_OK
  }
}

extension NSData : Bindable {
  public func bindTo(statement:Statement, atIndex:Int32) -> Bool {
    var rawData = self.bytes
    let status = sqlite3_bind_blob(statement.statementHandle, atIndex, rawData, Int32(self.length), SQLITE_TRANSIENT)
    return status == SQLITE_OK
  }
}

extension Bool : Bindable {
  public func bindTo(statement:Statement, atIndex:Int32) -> Bool {
    let intValue = Int(self)
    return intValue.bindTo(statement, atIndex: atIndex)
  }
}
