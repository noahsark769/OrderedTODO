//
//  DatabaseManager.swift
//  OrderedTODO
//
//  Created by Noah Gilmore on 12/26/19.
//  Copyright © 2019 Noah Gilmore. All rights reserved.
//

import Foundation
import GRDB
import Combine

struct ListModel: Codable {
    var id: Int64?
    let name: String
    let isDated: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case isDated = "is_dated"
    }
}

extension ListModel.CodingKeys: ColumnExpression {}

extension ListModel: TableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
        static let isDated = Column(CodingKeys.isDated)
    }

    static var databaseTableName: String {
        return "list_model"
    }
}

extension ListModel: FetchableRecord {}

extension ListModel: MutablePersistableRecord {
    // Update auto-incremented id upon successful insertion
    mutating func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
}

extension ListModel: Identifiable {}

func createDatabaseMigrator() -> DatabaseMigrator {
    var migrator = DatabaseMigrator()

    // Define any migrations here
    migrator.registerMigration("Create ListModel") { db in
        try db.create(table: "c") { t in
            t.autoIncrementedPrimaryKey("id")
            t.column("name", .text).notNull()
            t.column("is_dated", .boolean).notNull().defaults(to: false)
        }
    }

    return migrator
}

// TODO: Several things in here use try! actually catching errors would be better.
final class DatabaseManager {
    static let shared = DatabaseManager()

    let queue: DatabaseQueue

    init() {
        self.queue = try! DatabaseQueue(path: Self.databaseFilePath())
    }

    private static func databaseFilePath() -> String {
        guard let documentsDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Issue with documents directory url")
        }
        return documentsDirectoryUrl.path.appending("ordered-todo-database.sqlite")
    }

    func migrateToLatest() {
        let migrator = createDatabaseMigrator()
        try! migrator.migrate(self.queue)
    }
}
