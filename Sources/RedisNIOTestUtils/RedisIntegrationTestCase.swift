//===----------------------------------------------------------------------===//
//
// This source file is part of the RedisNIO open source project
//
// Copyright (c) 2019 RedisNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of RedisNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIO
import RedisNIO
import XCTest

/// A helper `XCTestCase` subclass that does the standard work of creating a connection to use in test cases.
///
/// See `RedisConnection.connect(to:port:)` to understand how connections are made.
open class RedisIntegrationTestCase: XCTestCase {
    public var connection: RedisConnection!
    
    private let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 2)
    
    deinit {
        do {
            try self.eventLoopGroup.syncShutdownGracefully()
        } catch {
            print("Failed to gracefully shutdown ELG: \(error)")
        }
    }
    
    /// Creates a `RedisNIO.RedisConnection` for the next test case, calling `fatalError` if it was not successful.
    ///
    /// See `XCTest.XCTestCase.setUp()`
    open override func setUp() {
        do {
            connection = try self.makeNewConnection()
        } catch {
            fatalError("Failed to make a RedisConnection: \(error)")
        }
    }
    
    /// Sends a "FLUSHALL" command to Redis to clear it of any data from the previous test, then closes the connection.
    ///
    /// If any steps fail, a `fatalError` is thrown.
    ///
    /// See `XCTest.XCTestCase.tearDown()`
    open override func tearDown() {
        do {
            if self.connection.isConnected {
                _ = try self.connection.send(command: "FLUSHALL")
                    .flatMap { _ in self.connection.close() }
                    .wait()
            }
            
            self.connection = nil
        } catch {
            fatalError("Failed to properly cleanup connection: \(error)")
        }
    }
    
    /// Creates a new connection for use in tests.
    ///
    /// See `RedisConnection.connect(to:port:)`
    /// - Returns: The new `RedisNIO.RedisConnection`.
    public func makeNewConnection() throws -> RedisConnection {
        return try RedisConnection.connect(on: eventLoopGroup.next()).wait()
    }
}
