import Foundation

/**
  Instances of this class represent a single database connection. You create a database by providing a URL to a database file on disk. You can also specify ":memory:" as the URL which will create an in-memory database.

  - Before you can use the database you have to call open().
  - When you no longer need the database instance you should close() it.
  - You query a database by using executeQuery(query:arguments:). Use this method to execute (SELECT) statements that give you an actual result back.
  - For other statement types (INSERT, UPDATE, DELETE, ...) you have to use executeupdate(query:arguments:).
*/
public class Database {
  private var URL:String
  var databaseHandle = COpaquePointer.null()
  
  /**
    Creates a Database instance.
  
    :param: URL The URL to the database. Use ":memory:" to create an in-memory database.
  
    :returns: A database instance which can now be opened.
  */
  public init(URL:String) {
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
  public func executeQuery(query:String, arguments:[Bindable?]) -> QueryResult {
    if let statement = prepare(query).statement {
      var argumentIndex:Int32 = 1
      for argument in arguments {
        let status = statement.bind(argumentIndex, value: argument)
        if !status {
          return .Failure(error(.BindFailed))
        }
        argumentIndex++
      }
      return .Success(ResultSet(statement: statement))
    }
    return .Failure(error(.PrepareFailed))
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
  public func executeQuery(query:String, arguments:Dictionary<String, Bindable?>) -> QueryResult {
    if let statement = prepare(query).statement {
      for (argumentName, argumentValue) in arguments {
        let parameterName = ":" + argumentName
        let rawName = parameterName.cStringUsingEncoding(NSUTF8StringEncoding)
        let index = sqlite3_bind_parameter_index(statement.statementHandle, rawName!)
        if index == 0 {
          NSLog("Failed to bind parameter named '%@'.", argumentName)
          return .Failure(error(.BindFailed))
        }
        
        let bound = statement.bind(index, value: argumentValue)
        if !bound {
          return .Failure(error(.BindFailed))
        }
      }
      return .Success(ResultSet(statement: statement))
    }
    return .Failure(error(.PrepareFailed))
  }
  
  /**
  Executes a query without any arguments/parameters. This is a convenience method that simply calls executeQuery(query:arguments:) with an empty arguments array. See executeQuery(query:arguments:) for more information.
  */
  public func executeQuery(query:String) -> QueryResult {
    return executeQuery(query, arguments:[Bindable?]())
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
  public func executeUpdate(query:String, arguments:[Bindable?]) -> UpdateResult {
    let result = executeQuery(query, arguments:arguments)
    var updateResult = UpdateResult.Success
    if updateResult.isFailure {
      return .Failure(error(.ExecuteQueryFailed))
    }
    var success = false
    result.consumeResultSetAndClose { resultSet in
      success = resultSet.step() == SQLITE_DONE
    }
    return success ? .Success : .Failure(error(.ExecuteQueryFailed))
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
  public func executeUpdate(query:String, arguments:Dictionary<String, Bindable?>) -> UpdateResult {
    if let resultSet = executeQuery(query, arguments: arguments).resultSet {
      return resultSet.step() == SQLITE_DONE ? .Success : .Failure(error(.StepFailed))
    }
    return .Failure(error(.ExecuteQueryFailed))
  }
  
  /**
  Executes an update query without any arguments/parameters. This is a convenience method that simply calls executeUpdate(query:arguments:) with an empty arguments array. See executeUpdate(query:arguments:) for more information.
  */
  public func executeUpdate(query:String) -> UpdateResult {
    return executeUpdate(query, arguments:[Bindable?]())
  }
  
  // MARK: Prepare
  private func prepare(statements:String) -> PreparationResult {
    let sql = statements.cStringUsingEncoding(NSUTF8StringEncoding)
    var handle: COpaquePointer = nil
    let status = sqlite3_prepare_v2(databaseHandle, sql!, -1, &handle, nil)
    if status == SQLITE_OK {
      return .Success(statement:Statement(statementHandle:handle, database:self))
    }
    return .Failure(error:error(.PrepareFailed))
  }
  
  // MARK: Error
  private var SQLiteErrorCode:Int32 {
    return sqlite3_errcode(databaseHandle)
  }
  
  private var errorMessage:String {
    let rawMessage = sqlite3_errmsg(databaseHandle)
    if rawMessage == nil {
      return ""
    }
    let message = String(UTF8String:rawMessage)
    if let message = message {
      return message
    }
    return ""
  }
  
  private func error(code:Error.Code) -> Error {
    return Error(code:code, message:errorMessage, SQLiteErrorCode:SQLiteErrorCode)
  }
}

// MARK: Printable and DebugPrintable
extension Database : Printable {
  public var description: String {
    return "Database at \(URL)"
  }
}

extension Database : DebugPrintable {
  public var debugDescription: String {
    return "\(description) {error message: \(errorMessage), SQLite error code: \(SQLiteErrorCode)}"
  }
}