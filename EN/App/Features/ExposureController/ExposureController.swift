/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation

final class ExposureController: ExposureControlling {
    init(mutableStatusStream: MutableExposureStateStreaming,
         exposureManager: ExposureManaging?) {
        self.mutableStatusStream = mutableStatusStream
        self.exposureManager = exposureManager
        
        activateExposureManager()
    }
    
    // MARK: - ExposureControlling
    
    func requestExposureNotificationPermission() {
        exposureManager?.setExposureNotificationEnabled(true) { _ in
            self.updateStatusStream()
        }
    }
    
    func requestPushNotificationPermission() {
        // Not implemented yet
    }
    
    func confirmExposureNotification() {
        // Not implemented yet
    }
    
    // MARK: - Private
    
    private func activateExposureManager() {
        guard let exposureManager = exposureManager else {
            updateStatusStream()
            return
        }
        
        exposureManager.activate { _ in
            self.updateStatusStream()
        }
    }
    
    private func updateStatusStream() {
        guard let exposureManager = exposureManager else {
            mutableStatusStream.update(state: .init(notified: isNotified,
                                                    activeState: .inactive(.requiresOSUpdate))
            )
            
            return
        }
        
        let activeState: ExposureActiveState
        
        switch exposureManager.getExposureNotificationStatus() {
        case .active:
            activeState = .active
        case .inactive(let error) where error == .bluetoothOff:
            activeState = .inactive(.bluetoothOff)
        case .inactive(let error) where error == .disabled || error == .restricted:
            activeState = .inactive(.disabled)
        case .inactive(let error) where error == .notAuthorized:
            activeState = .notAuthorized
        case .inactive(let error) where error == .unknown:
            // Most likely due to code signing issues
            activeState = .inactive(.disabled)
        case .inactive(_):
            activeState = .inactive(.disabled)
        case .notAuthorized:
            activeState = .notAuthorized
        }
        
        mutableStatusStream.update(state: .init(notified: isNotified,
                                                activeState: activeState)
        )
    }
    
    private var isNotified: Bool {
        // TODO: Replace with right value
        return false
    }
    
    private let mutableStatusStream: MutableExposureStateStreaming
    private let exposureManager: ExposureManaging?
}
