//
//  DatabaseManager.swift
//  OrderedTODO
//
//  Created by Noah Gilmore on 12/26/19.
//  Copyright © 2019 Noah Gilmore. All rights reserved.
//

import Foundation
import GRDB

struct ListModel: Codable {
    let id: Int
    let name: String
    let isDated: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case isDated
    }

    typealias Columns = CodingKeys
}

extension ListModel.CodingKeys: ColumnExpression {}

extension ListModel: MutablePersistableRecord {
    func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = self.id
        container[Columns.isDated] = self.isDated
        container[Columns.name] = self.name
    }
}

extension ListModel: Identifiable {}

func createDatabaseMigrator() -> DatabaseMigrator {
    var migrator = DatabaseMigrator()

    // Define any migrations here
    migrator.registerMigration("Create ListModel") { db in
        try db.create(table: "list_model") { t in
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
