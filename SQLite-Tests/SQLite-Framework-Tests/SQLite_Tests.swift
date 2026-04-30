//
//  SQLite_Tests.swift
//  SQLite-Tests
//
//  Created by Jan Nitecki on 2026-02-04.
//

import XCTest
import SQLite_Decimal

final class SQLite_Tests: XCTestCase {
    
    var database: OpaquePointer? // Holds the database instance
    let decimalOption: String = "ENABLE_DECIMAL"
    let number1: Decimal = Decimal(string: "434342342342.43433")!
    let number2: Decimal = Decimal(string: "29989943.458483371268433")!
    let number3: Decimal = Decimal(string: "9")!
    let number4: Decimal = Decimal(string: "1000000000000")!

    override func setUpWithError() throws {
        // 1. Create a temporary database path for testing
        let dbObject = openDatabase()
        XCTAssertNotNil(dbObject)
        database = dbObject!
    }

    override func tearDownWithError() throws {
        // Clean up the database file
        if (database != nil) {
            sqlite3_close(database!);
            database = nil
        }
    }
    
    func testCompilationOptionsSupport() throws {
        var optionNumber = 0
        var options: [String] = []

        while true {
            let sql = "SELECT sqlite_compileoption_get(\(optionNumber));"
            var stmt: OpaquePointer?

            if sqlite3_prepare_v2(database, sql, -1, &stmt, nil) != SQLITE_OK {
                XCTFail("Failed to prepare statement")
                return
            }

            defer { sqlite3_finalize(stmt) }

            if sqlite3_step(stmt) == SQLITE_ROW {
                if let cString = sqlite3_column_text(stmt, 0) {
                    let option = String(cString: cString)
                    options.append(option)
                    optionNumber += 1
                } else {
                    // sqlite_compileoption_get returned NULL → exit loop
                    break
                }
            } else {
                XCTFail("Failed to step statement")
                break
            }
        }

        // Example assertion: at least 1 compile option exists
        XCTAssertFalse(options.isEmpty, "No compilation options found")
        print("SQLite compile options:", options)
    }
    
    func testDecimalOptionInOptionsList() throws {
        var optionNumber = 0
        var options: [String] = []

        while true {
            let sql = "SELECT sqlite_compileoption_get(\(optionNumber));"
            var stmt: OpaquePointer?

            guard sqlite3_prepare_v2(database, sql, -1, &stmt, nil) == SQLITE_OK else {
                XCTFail("Failed to prepare statement")
                return
            }

            defer { sqlite3_finalize(stmt) }

            if sqlite3_step(stmt) == SQLITE_ROW {
                if let cString = sqlite3_column_text(stmt, 0) {
                    let option = String(cString: cString)
                    options.append(option)
                    optionNumber += 1
                } else {
                    // No more compile options
                    break
                }
            } else {
                XCTFail("Failed to step statement")
                break
            }
        }

        // Assert the decimal option exists
        XCTAssertTrue(options.contains(decimalOption), "List does not contain: \(decimalOption)")
        print("SQLite compile options:", options)
    }
    
    func testDecimalOption() {
        let sql = "SELECT sqlite_compileoption_used('\(decimalOption)');"
        var stmt: OpaquePointer?

        // Prepare statement
        guard sqlite3_prepare_v2(database, sql, -1, &stmt, nil) == SQLITE_OK else {
            XCTFail("Failed to prepare statement")
            return
        }

        defer { sqlite3_finalize(stmt) }

        // Step to first (and only) row
        guard sqlite3_step(stmt) == SQLITE_ROW else {
            XCTFail("No row returned")
            return
        }

        // Get integer result
        let optionPresent = sqlite3_column_int(stmt, 0)

        // Assert it is 1 (option is present)
        XCTAssertEqual(optionPresent, 1, "Decimal option '\(decimalOption)' is not present")
    }
    
    func testUnknownOption() {
        let sql = "SELECT sqlite_compileoption_used('NON_EXISTENT_OPTION');"
        var stmt: OpaquePointer?

        guard sqlite3_prepare_v2(database, sql, -1, &stmt, nil) == SQLITE_OK else {
            XCTFail("Failed to prepare statement")
            return
        }
        defer { sqlite3_finalize(stmt) }

        guard sqlite3_step(stmt) == SQLITE_ROW else {
            XCTFail("No row returned")
            return
        }

        let optionAbsent = sqlite3_column_int(stmt, 0)
        XCTAssertEqual(optionAbsent, 0)
    }
    
    func testAddingDecimals() {
        let n1 = NSDecimalNumber(decimal: number1).stringValue
        let n2 = NSDecimalNumber(decimal: number2).stringValue

        let sql = "SELECT decimal_add('\(n1)', '\(n2)');"
        var stmt: OpaquePointer?

        guard sqlite3_prepare_v2(database, sql, -1, &stmt, nil) == SQLITE_OK else {
            XCTFail("Failed to prepare statement")
            return
        }
        defer { sqlite3_finalize(stmt) }

        guard sqlite3_step(stmt) == SQLITE_ROW else {
            XCTFail("No row returned")
            return
        }

        guard let cString = sqlite3_column_text(stmt, 0) else {
            XCTFail("Result is NULL")
            return
        }

        let resultString = String(cString: cString)
        let resultDecimal = Decimal(string: resultString)!

        XCTAssertEqual(resultDecimal, number1 + number2)
    }
    
    func openDatabase() -> OpaquePointer? {
        let fileManager = FileManager.default
        let documentsURL = try! fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )

        let dbURL = documentsURL.appendingPathComponent("app.db")
        //let database = dbURL.path()
        let database = ":memory"

        var db: OpaquePointer?
        if sqlite3_open(database, &db) == SQLITE_OK {
            return db
        } else {
            print("Unable to open database")
            return nil
        }
    }
    
    func executeDDL(db: OpaquePointer?, sql: String) {
        var errorMessage: UnsafeMutablePointer<Int8>?
        if sqlite3_exec(db, sql, nil, nil, &errorMessage) != SQLITE_OK {
            print("DDL error: \(String(cString: errorMessage!))")
            sqlite3_free(errorMessage)
        }
    }
    
    func insertUser(db: OpaquePointer?, name: String, email: String) {
        let sql = "INSERT INTO users (name, email) VALUES (?, ?);"
        var stmt: OpaquePointer?

        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, name, -1, nil)
            sqlite3_bind_text(stmt, 2, email, -1, nil)

            if sqlite3_step(stmt) != SQLITE_DONE {
                print("Insert failed")
            }
        } else {
            print("Prepare failed")
        }

        sqlite3_finalize(stmt)
    }
    
    func fetchUsers(db: OpaquePointer?) {
        let sql = "SELECT id, name, email FROM users;"
        var stmt: OpaquePointer?

        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                let id = sqlite3_column_int(stmt, 0)
                let name = String(cString: sqlite3_column_text(stmt, 1))
                let email = String(cString: sqlite3_column_text(stmt, 2))

                print(id, name, email)
            }
        }

        sqlite3_finalize(stmt)
    }
}
