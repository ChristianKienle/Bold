![Alt text](/GFX/logo.png?raw=true "Bold Logo")

[![Build Status](https://travis-ci.org/ChristianKienle/Bold.svg?branch=master)](https://travis-ci.org/ChristianKienle/Bold)

A lightweight and extensible SQLite wrapper written in Swift by [@CocoaPimper](https://twitter.com/CocoaPimper). 


# Why yet another SQLite wrapper?
I wanted to dive into Swift and writing a SQLite wrapper seemed like a good thing to do. So **Bold** is basically a just for fun project. 


# Simple Example
The example below creates an in-memory database, opens it, creates a table, inserts a row and then queries the table. Please note that the result is closed automatically after a complete iteration by using `for-in`.

    let db = Database(URL:":memory:")
    let _ = db.open()
    db.executeUpdate(query: "CREATE TABLE Person (firstName, lastName)")
    
    let args = ["firstName" : "Christian", "lastName" : "Kienle"]
    db.executeUpdate(query: "INSERT INTO Person (firstName, lastName) VALUES (:firstName, :lastName)", arguments:args)
    
    let result = db.executeQuery(query: "SELECT firstName, lastName FROM Person")
    for row in result {
        guard let firstName = row.stringValue(forColumn: "firstName"), lastName = row.stringValue(forColumn: "lastName") else {
            return
        }
        println("firstName: \(firstName)")
        println("lastName: \(lastName)")
    }
    // The result is automatically closed after a complete iteration.

# Extend Bold: Custom Types
I wanted **Bold** to be easily extensible. There are basically two things that can be extended:

1. Support for custom data types in the input arguments.
2. Support for custom data types when accessing a row.

## Extend Types for Input Arguments
You can support custom data types for input arguments simply by implementing `Bindable`. Lets assume you have a custom class called `UUID` which represents a UUID and you would like to pass UUIDs to **Bold** when inserting a new row. You could implement `Bindable` by doing something like this:

    extension UUID : Bindable {
      public func bind(to statement:Statement, atIndex index:Int32) -> Bool {
  	    let value = stringRepresentation // assume this exists
  	    // call the existing implementation of `bind(to:atIndex:)`
        return value.bind(to: statement, atIndex:atIndex)
    }
    
This is all you have to do. Now you could use UUID like this in combination with **Bold**:

	let uuid = UUID()
  db.executeUpdate(query: "INSERT INTO Person (id) VALUES (:id)", arguments:["id" : uuid])
    
## Extend Types for Output Arguments
When you access the contents of a row you access the data by using methods like `stringValue(columnName:)`, `intValue(columnName:)` and so on. If you would like to add support for your own data type (for example a method that uses the binary data in a column to create a `UIImage`) you simply extend `Row`. Let's see how this works with our custom `UUID` class from above.

    extension Row {
        public func UUIDValue(columnName: String) -> UUID? {
            guard let stringValue = stringValue(forColumn: columnName) else {
                return nil
            }
            return UUID(stringValue)
        } 
    }
    
Now you can use `UUIDValue(columnName:)` when accessing the data of your rows.

# Lightweight
**Bold** is lightweight. This means that **Bold** does not try to be smart. For example it does not implement `SQLITE_BUSY`-handling like some other SQLite wrappers do. I believe that any implementation of `SQLITE_BUSY`-handling hides an underlying locking problem that you might have. Other wrappers simply wait for a couple of seconds until they time out. Please note that libsqlite3 already has ways to avoid `SQLITE_BUSY` related errors.

**Bold** also exposes the raw `sqlite3` database handle and the raw `sqlite3_stmt` handle. You should try to avoid accessing those but if you need to access them they are there.
