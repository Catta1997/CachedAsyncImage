//
//  ResourcesManager.swift
//  CachedAsyncImageTests
//
//  Created by Dmitry Kononchuk on 18.06.2023.
//  Copyright © 2023 Dmitry Kononchuk. All rights reserved.
//

#if canImport(UIKit)
import UIKit

/// Resources manager typealias.
public typealias RM = ResourcesManager

/// Resources manager.
public final class ResourcesManager {
    // MARK: - Public Properties
    
    public static let snow = UIColor(
        named: "snow",
        in: Bundle.module,
        compatibleWith: nil
    ) ?? UIColor()
    
    // MARK: - Public Methods
    
    public static func image(_ name: String) -> UIImage? {
        UIImage(named: name, in: Bundle.module, with: nil)
    }
}
#endif