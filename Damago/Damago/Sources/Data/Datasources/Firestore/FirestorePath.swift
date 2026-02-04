//
//  FirestorePath.swift
//  Damago
//
//  Created by 김재영 on 2/4/26.
//

enum FirestorePath {
    private enum CollectionName {
        static let users = "users"
        static let couples = "couples"
        static let damagos = "damagos"
        static let dailyQuestionAnswers = "dailyQuestionAnswers"
        static let balanceGameAnswers = "balanceGameAnswers"
    }
    
    private enum FieldName {
        static let coupleID = "coupleID"
    }

    case users(uid: String)
    case couples(coupleID: String)
    case damagos(damagoID: String)
    case ownedDamagos(coupleID: String)
    case dailyQuestionAnswers(coupleID: String, questionID: String)
    case balanceGameAnswers(coupleID: String, gameID: String)

    var fullPath: String {
        document.isEmpty ? collection : "\(collection)/\(document)"
    }
    
    var collection: String {
        switch self {
        case .users:
            return CollectionName.users
        case .couples:
            return CollectionName.couples
        case .damagos, .ownedDamagos:
            return CollectionName.damagos
        case .dailyQuestionAnswers(let coupleID, _):
            return "\(CollectionName.couples)/\(coupleID)/\(CollectionName.dailyQuestionAnswers)"
        case .balanceGameAnswers(let coupleID, _):
            return "\(CollectionName.couples)/\(coupleID)/\(CollectionName.balanceGameAnswers)"
        }
    }
    
    var document: String {
        switch self {
        case .users(let uid):
            return uid
        case .couples(let coupleID):
            return coupleID
        case .damagos(let damagoID):
            return damagoID
        case .dailyQuestionAnswers(_, let questionID):
            return questionID
        case .balanceGameAnswers(_, let gameID):
            return gameID
        case .ownedDamagos:
            return ""
        }
    }
    
    var queryInfo: (field: String, value: Any)? {
        switch self {
        case .ownedDamagos(let coupleID):
            return (field: FieldName.coupleID, value: coupleID)
        default:
            return nil
        }
    }
}
