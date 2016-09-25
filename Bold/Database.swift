import Foundation

/**
 Instances of this class represent a single database connection. You create a database by providing a URL to a database file on disk. You can also specify ":memory:" as the URL which will create an in-memory database.
 
 - Before you can use the database you have to call open().
 - When you no longer need the database instance you should close() it.
 - You query a database by using executeQuery(query:arguments:). Use this method to execute (SELECT) statements that give you an actual result back.
 - For other statement types (INSERT, UPDATE, DELETE, ...) you have to use executeupdate(query:arguments:).
 */
final public class Database {
  fileprivate var URL: String
  private var databaseHandle: OpaquePointer?
  
  /**
   Creates a Database instance.
   
   :param: URL The URL to the database. Use ":memory:" to create an in-memory database.
   
   :returns: A database instance which can now be opened.
   */
  public init(URL: String) {
    self.URL = URL
  }
  
  /**
   Tries to open the database.
   
   :returns: true if the database could be opened, otherwise false.
   */
  public func open() -> Bool {
    return sqlite3_open(URL, &databaseHandle) == SQLITE_OK
  }
  
  /**
   Tries to close the database.
   
   :returns: true if the database could be closed, otherwise false.
   */
  public func close() -> Bool {
    return sqlite3_close(databaseHandle) == SQLITE_OK
  }
  
  /**
   Executes a query with indexed parameters.
   
   - The first '?' is replaced by the first item in the arguments array.
   - The second '?' is replaced by the second item in the arguments array - and so on.
   - The number of placeholders has to be equal to the number of items in the arguments array.
   - See the Bindable protocol for a description of the supported types in the arguments array.
   
   Example:
   
   executeQuery("SELECT * FROM Table WHERE columnA = ?, columnB = ?", arguments:["hello", 123])
   
   :param: query A SQL query which can contain placeholders (?) for the actual values.
   :param: arguments Instances that conform the the Bindable protocol.
   :returns: An instance of QueryResult and never nil. Inspect the QueryResult to find out about the returned rows or about the error.
   */
  public func executeQuery(query: String, arguments: [Bindable?]) -> QueryResult {
    guard let statement = prepare(statements: query).statement else {
      return .failure(error(reason: .prepareFailed))
    }
    var success = true
    arguments.enumerated().forEach { (index, argument) in
      let columnIndex = index + 1
      let status = statement.bind(Int32(columnIndex), value: argument)
      guard status == true else {
        success = false
        return
      }
    }
    guard success else {
      return .failure(error(reason: .bindFailed))
    }
    return .success(ResultSet(statement: statement))
  }
  
  /**
   Executes a query with named parameters.
   
   - A named parameter has the form: ':parameter_name'.
   - The parameters are replaced by the values in the arguments dictionary.
   - For example: A parameter named ':firstName' is replaced by the value in the arguments dictionary which has the same name as the parameter.
   - Unknown keys in the arguments dictionary are ingored.
   
   Example:
   
   executeQuery("SELECT * FROM Table WHERE columnA = :colA, columnB = colB", arguments:["colA" : "hello", "colB" : 123])
   
   :param: query A SQL query which can contain named placeholders (:parameter_name) for the actual values.
   :param: arguments Instances that conform the the Bindable protocol.
   :returns: An instance of QueryResult and never nil. Inspect the QueryResult to find out about the returned rows or about the error.
   */
  public func executeQuery(query: String, arguments: [String : Bindable?]) -> QueryResult {
    guard let statement = prepare(statements: query).statement else {
      return .failure(error(reason: .prepareFailed))
    }
    for (argumentName, argumentValue) in arguments {
      let parameterName = ":" + argumentName
      guard let rawName = parameterName.cString(using: String.Encoding.utf8) else {
        NSLog("Failed to bind parameter named '%@'.", argumentName)
        return .failure(error(reason: .bindFailed))
      }
      let index = sqlite3_bind_parameter_index(statement.statementHandle, rawName)
      guard index != 0 else {
        NSLog("Failed to bind parameter named '%@'.", argumentName)
        return .failure(error(reason: .bindFailed))
      }
      guard statement.bind(index, value: argumentValue) else {
        return .failure(error(reason: .bindFailed))
      }
    }
    return .success(ResultSet(statement: statement))
  }
  
  /**
   Executes a query without any arguments/parameters. This is a convenience method that simply calls executeQuery(query:arguments:) with an empty arguments array. See executeQuery(query:arguments:) for more information.
   */
  public func executeQuery(query: String) -> QueryResult {
    return executeQuery(query: query, arguments: [Bindable?]())
  }
  
  /**
   Executes an update query (INSERT, UPDATE, DELETE, ...) with indexed parameters.
   
   - The first '?' is replaced by the first item in the arguments array.
   - The second '?' is replaced by the second item in the arguments array - and so on.
   - The number of placeholders has to be equal to the number of items in the arguments array.
   - See the Bindable protocol for a description of the supported types in the arguments array.
   
   Example:
   
   executeUpdate("INSERT INTO Table WHERE columnA = ?, columnB = ?", arguments:["hello", 123])
   
   :param: query A SQL query which can contain placeholders (?) for the actual values.
   :param: arguments Instances that conform the the Bindable protocol.
   :returns: An instance of UpdateResult and never nil. Inspect the UpdateResult to find out about the returned rows or about the error.
   */
  public func executeUpdate(query: String, arguments: [Bindable?]) -> UpdateResult {
    let result = executeQuery(query: query, arguments:arguments)
    var success = false
    result.consumeResultSetAndClose { resultSet in
      success = resultSet.step() == SQLITE_DONE
    }
    return success ? .success : .failure(error(reason: .executeQueryFailed))
  }
  
  /**
   Executes an update query (INSERT, UPDATE, DELETE, ...) with named parameters.
   
   - A named parameter has the form: ':parameter_name'.
   - The parameters are replaced by the values in the arguments dictionary.
   - For example: A parameter named ':firstName' is replaced by the value in the arguments dictionary which has the same name as the parameter.
   - Unknown keys in the arguments dictionary are ingored.
   
   Example:
   
   executeUpdate("INSERT INTO Table WHERE columnA = :colA, columnB = :colB", arguments:["colA" : "hello", "colB" : 123])
   
   :param: query A SQL query which can contain named placeholders (:parameter_name) for the actual values.
   :param: arguments Instances that conform the the Bindable protocol.
   :returns: An instance of UpdateResult and never nil. Inspect the UpdateResult to find out about the returned rows or about the error.
   */
  public func executeUpdate(query: String, arguments: [String : Bindable?]) -> UpdateResult {
    guard let resultSet = executeQuery(query: query, arguments: arguments).resultSet else {
      return .failure(error(reason: .executeQueryFailed))
    }
    return resultSet.step() == SQLITE_DONE ? .success : .failure(error(reason: .stepFailed))
  }
  
  /**
   Executes an update query without any arguments/parameters. This is a convenience method that simply calls executeUpdate(query:arguments:) with an empty arguments array. See executeUpdate(query:arguments:) for more information.
   */
  public func executeUpdate(query: String) -> UpdateResult {
    return executeUpdate(query: query, arguments: [Bindable?]())
  }
  
  // MARK: Prepare
  private func prepare(statements:String) -> PreparationResult {
    guard let sql = statements.cString(using: String.Encoding.utf8) else {
      return .failure(error: error(reason: .prepareFailed))
    }
    var _handle: OpaquePointer? = nil
    let status = sqlite3_prepare_v2(databaseHandle, sql, -1, &_handle, nil)
    guard status == SQLITE_OK, let handle = _handle else {
      return .failure(error:error(reason: .prepareFailed))
    }
    return .success(statement:Statement(statementHandle:handle, database:self))
  }
  
  // MARK: Error
  fileprivate var SQLiteErrorCode: Int32 {
    return sqlite3_errcode(databaseHandle)
  }
  
  fileprivate var errorMessage: String {
    guard let rawMessage = sqlite3_errmsg(databaseHandle) else {
      return ""
    }
    return String(cString: rawMessage)
  }
  
  fileprivate func error(reason code:Error.Code) -> Error {
    return Error(code:code, message:errorMessage, SQLiteErrorCode:SQLiteErrorCode)
  }
}
// MARK: Printable and DebugPrintable
extension Database : CustomStringConvertible {
  public var description: String {
    return "Database at \(URL)"
  }
}

extension Database : CustomDebugStringConvertible {
  public var debugDescription: String {
    return "\(description) {error message: \(errorMessage), SQLite error code: \(SQLiteErrorCode)}"
  }
}
