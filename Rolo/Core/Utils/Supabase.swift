//
//  Supabase.swift
//  Rolo
//
//  Created by tsuriel.eichenstein on 4/30/25.
//

import Foundation
import Supabase

let supabase = SupabaseClient(supabaseURL: URL(string: supabaseProjectURL)!,
                              supabaseKey: supabaseAPIKey)
