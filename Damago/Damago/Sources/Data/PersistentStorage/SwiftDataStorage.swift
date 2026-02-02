//
//  SwiftDataStorage.swift
//  Damago
//
//  Created by 김재영 on 1/22/26.
//

import SwiftData
import Foundation

final class SwiftDataStorage {
    static let shared = SwiftDataStorage()
    
    let container: ModelContainer
    let context: ModelContext
    
    @MainActor
    init(appGroupID: String = AppGroupConstants.defaultID) {
        do {
            let schema = Schema([
                DailyQuestionEntity.self
            ])
            
            guard let containerURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: appGroupID
            ) else {
                fatalError("App Group 컨테이너에 접근할 수 없습니다. App Group ID를 확인해주세요.")
            }
            
            let storeURL = containerURL.appendingPathComponent("default.store")
            let modelConfiguration = ModelConfiguration(schema: schema, url: storeURL)
            
            self.container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            self.context = container.mainContext
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
