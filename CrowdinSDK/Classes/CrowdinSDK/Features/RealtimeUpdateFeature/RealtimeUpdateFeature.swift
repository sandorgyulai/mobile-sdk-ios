//
//  RealtimeUpdateFeature.swift
//  CrowdinSDK
//
//  Created by Serhii Londar on 3/5/19.
//

import Foundation

class RealtimeUpdateFeature {
    static var shared: RealtimeUpdateFeature?
    
    var hashString: String
    
    private var controls = NSHashTable<AnyObject>.weakObjects()
    private var socketManger: CrowdinSocketManager!
    private var mappingManager: CrowdinMappingManagerProtocol
    
    init(strings: [String], plurals: [String], hash: String, sourceLanguage: String) {
        self.hashString = hash
        self.mappingManager = CrowdinMappingManager(strings: strings, plurals: plurals, hash: hash, sourceLanguage: sourceLanguage)
    }
    
    func subscribe(control: Refreshable) {
        guard let localizationKey = control.key else { return }
        guard let id = self.mappingManager.id(for: localizationKey) else { return }
        socketManger.subscribeUpdateDraft(localization: "en", stringId: id)
        socketManger.subscribeTopSuggestion(localization: "en", stringId: id)
        controls.add(control)
    }
    
    func refresh() {
        self.controls.allObjects.forEach { (control) in
            if let refreshable = control as? Refreshable {
                refreshable.refresh()
            }
        }
    }
    
    func refreshControl(with localizationKey: String, newText: String) {
        self.controls.allObjects.forEach { (control) in
            if let refreshable = control as? Refreshable {
                if let key = refreshable.key, key == localizationKey {
                    refreshable.refresh(text: newText)
                }
            }
        }
    }
    
    func start() {
        guard let loginVC = CrowdinLoginVC.instantiateVC else { return }
        loginVC.completion = { token, userAgent, cookies in
            self.start(with: token, userAgent: userAgent, cookies: cookies)
        }
        // TODO: Change screen presentation.
        UIApplication.shared.keyWindow?.rootViewController?.present(loginVC, animated: true, completion: { })
    }
    
    func start(with token: String, userAgent: String, cookies: [HTTPCookie]) {
        self.socketManger = CrowdinSocketManager(hashString: hashString, csrfToken: token, userAgent: userAgent, cookies: cookies)
        self.socketManger.didChangeString = { id, newValue in
            self.didChangeString(with: id, to: newValue)
        }
        
        self.socketManger.didChangePlural = { id, newValue in
            self.didChangePlural(with: id, to: newValue)
        }
    }
    
    func didChangeString(with id: Int, to newValue: String) {
        guard let key = mappingManager.stringLocalizationKey(for: id) else { return }
        self.refreshControl(with: key, newText: newValue)
    }
    
    func didChangePlural(with id: Int, to newValue: String) {
        guard let key = mappingManager.stringLocalizationKey(for: id) else { return }
        self.refreshControl(with: key, newText: newValue)
    }
}
