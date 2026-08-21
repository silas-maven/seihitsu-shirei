import Foundation
import Security

/// Minimal generic-password Keychain access. Secrets never touch disk in plaintext.
///
/// Items are written with a non-interactive ACL so the app does not throw the "enter your login
/// keychain password" prompt on every launch. On a self-signed local build the default per-app
/// ACL is unreliable (and items created by the `security` CLI trust nothing), which is what
/// caused the repeated prompts. This is a personal, single-user tool, so making the item readable
/// without the interactive challenge is an acceptable trade-off.
enum Keychain {
    static func read(service: String, account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    @discardableResult
    static func write(service: String, account: String, value: String) -> Bool {
        let base: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(base as CFDictionary)
        var add = base
        add[kSecValueData as String] = Data(value.utf8)
        if let access = nonInteractiveAccess() {
            add[kSecAttrAccess as String] = access
        }
        return SecItemAdd(add as CFDictionary, nil) == errSecSuccess
    }

    /// Re-save any readable keys so they pick up the non-interactive ACL. Returns false if a read
    /// was cancelled/denied (so the caller can retry on a later launch); true otherwise.
    @discardableResult
    static func repairAccess(service: String, accounts: [String]) -> Bool {
        var completed = true
        for account in accounts {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
                kSecReturnData as String: true,
                kSecMatchLimit as String: kSecMatchLimitOne,
            ]
            var item: CFTypeRef?
            let status = SecItemCopyMatching(query as CFDictionary, &item)
            switch status {
            case errSecSuccess:
                if let data = item as? Data, let value = String(data: data, encoding: .utf8) {
                    _ = write(service: service, account: account, value: value)   // rewrite with the new ACL
                }
            case errSecItemNotFound:
                continue
            default:
                completed = false   // user cancelled or auth failed; leave the flag unset to retry
            }
        }
        return completed
    }

    /// An access object whose ACLs carry an empty (nil) application list, meaning any application
    /// may use the item without an interactive prompt.
    private static func nonInteractiveAccess() -> SecAccess? {
        var access: SecAccess?
        guard SecAccessCreate("Seihitsu" as CFString, nil, &access) == errSecSuccess,
              let access else { return nil }
        var aclList: CFArray?
        if SecAccessCopyACLList(access, &aclList) == errSecSuccess,
           let acls = aclList as? [SecACL] {
            for acl in acls {
                SecACLSetContents(acl, nil, "Seihitsu" as CFString, [])
            }
        }
        return access
    }
}
