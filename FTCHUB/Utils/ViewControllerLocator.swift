//
//  ViewControllerLocator.swift
//  FTCHUB
//

#if canImport(UIKit)
import UIKit

enum ViewControllerLocator {
    @MainActor
    static func topViewController(base: UIViewController? = nil) -> UIViewController? {
        let baseController: UIViewController? = {
            if let base {
                return base
            }
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
                .first(where: \.isKeyWindow)?
                .rootViewController
        }()

        if let navigationController = baseController as? UINavigationController {
            return topViewController(base: navigationController.visibleViewController)
        }
        if let tabController = baseController as? UITabBarController {
            return topViewController(base: tabController.selectedViewController)
        }
        if let presented = baseController?.presentedViewController {
            return topViewController(base: presented)
        }
        return baseController
    }
}
#endif
