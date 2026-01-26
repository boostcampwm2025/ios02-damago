//
//  UserCodeDTO.swift
//  Damago
//
//  Created by Gemini on 1/26/26.
//

import Foundation

struct UserCodeDTO: Decodable {
    let myCode: String
    let partnerCode: String?
}
