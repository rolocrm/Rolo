//
//  PostHogAnalytics.swift
//  Rolo
//
//  Created by tsuriel.eichenstein on 7/30/25.
//

import Foundation
import PostHog
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let POSTHOG_API_KEY = "phx_yheQPCzdyQJoL9Ay57aD3ZP6prDCG9EQZTfBUDz27HMjTxZ"
        let POSTHOG_HOST = "https://us.i.posthog.com"

        let config = PostHogConfig(apiKey: POSTHOG_API_KEY, host: POSTHOG_HOST)
        
        PostHogSDK.shared.setup(config)

        return true
    }
}

//phx_FALmsNFGOUCikG4fWCn082YJjgLeYHpxVXVOnL76YZZEtIt

// installed one phc_rys7qKdszXJPN6x3WYshSyhOHOYRSgG2SAk6s0f9FYn
