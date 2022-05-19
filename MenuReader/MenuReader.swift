//
//  MenuReader.swift
//  MenuReader
//
//  Created by YICAI YANG on 2021/11/12.
//

import Foundation
import AppKit

extension MenuReader
{
    class MenuItem: Equatable
    {
        let name: String
        let axUIElement: AXUIElement?
        let parent: MenuItem?
        
        let shortcuts: [String]?
        
        var subitems = [MenuItem]()
        
        init(name: String, axUIElement: AXUIElement?, parent: MenuItem?, shortcuts: [String]? = nil)
        {
            self.name = name
            self.axUIElement = axUIElement
            self.parent = parent
            self.shortcuts = shortcuts
        }
                
        func filter(_ isIncluded: (MenuItem) -> Bool) -> [MenuItem]?
        {
            var items = [MenuItem]()
            filter(isIncluded, items: &items)
            return items.isEmpty ? nil : items
        }
        
        private func filter(_ isIncluded: (MenuItem) -> Bool, items: inout [MenuItem])
        {
            items += subitems.filter(isIncluded)
            subitems.forEach() {
                $0.filter(isIncluded, items: &items)
            }
        }
        
        // If you like to get any menu item attributes like enabled, shortcuts..., try to do with your own way...
        var enabled: Bool {
            guard let element = axUIElement else {
                return false
            }
            return (MenuReader.getAttribute(element: element, name: kAXEnabledAttribute) as? Bool) ?? false
        }
        
        static func == (lhs: MenuItem, rhs: MenuItem) -> Bool
        {
            lhs.name == rhs.name && lhs.axUIElement == rhs.axUIElement
        }
    }
}

extension MenuReader
{
    static func prettyPrint(_ menu: MenuItem)
    {
        guard !menu.subitems.isEmpty else {
            return
        }
        
        var padding: String = ""
        var parent = menu.parent
        while parent != nil
        {
            padding += "    "
            parent = parent?.parent
        }
        
        menu.subitems.forEach() { item in
            print("\(padding)\(item.name)")
            prettyPrint(item)
        }
    }
}

struct MenuReader
{
    static let modifierCombinations: [Int: String] = [0: "⌘",
                                                      1: "⇧ ⌘",
                                                      2: "⌥ ⌘",
                                                      3: "⌥ ⇧ ⌘",
                                                      4: "⌃ ⌘",
                                                      5: "⌃ ⇧ ⌘",
                                                      6: "⌃ ⌥ ⌘",
                                                      7: "⌃ ⌥ ⇧ ⌘",
                                                      8: "",
                                                      9: "⇧",
                                                      10: "⌥",
                                                      11: "⌥ ⇧",
                                                      12: "⌃",
                                                      13: "⌃ ⇧",
                                                      14: "⌃ ⌥",
                                                      15: "⌃ ⌥ ⇧"]
    
    static func getMenuItems(app: NSRunningApplication? = NSWorkspace.shared.frontmostApplication) -> MenuItem?
    {
        guard let app = app else {
            return nil
        }
        return getMenuItems(pid: app.processIdentifier)
    }
    
    static func getMenuItems(pid: pid_t) -> MenuItem?
    {
        let axApp = AXUIElementCreateApplication(pid)
        var menuBarValue: CFTypeRef? = nil
        let status = AXUIElementCopyAttributeValue(axApp, kAXMenuBarAttribute as CFString, &menuBarValue)
        guard status == .success else {
            print("error: \(status).")
            return nil
        }
        let menuBar = menuBarValue as! AXUIElement
        
        let top = MenuItem(name: "Root", axUIElement: nil, parent: nil)
                
        if let childrens = getAttribute(element: menuBar, name: kAXChildrenAttribute) as? [AXUIElement],
           !childrens.isEmpty
        {
            childrens.forEach() { element in
                guard var name = getAttribute(element: element, name: kAXTitleAttribute) as? String else {
                    return
                }
                
                if top.subitems.isEmpty, name == "Apple"
                {
                    name = ""
                }
                
                let menu = MenuItem(name: name, axUIElement: element, parent: top)
                top.subitems.append(menu)
                getSubitems(element: element, menu: menu)
            }
        }
        return top
    }
    
    static func getAttribute(element: AXUIElement, name: String) -> CFTypeRef?
    {
        var value: CFTypeRef? = nil
        AXUIElementCopyAttributeValue(element, name as CFString, &value)
        return value
    }
    
    static func getSubitems(element: AXUIElement, menu: MenuItem)
    {
        if let childrens = getAttribute(element: element, name: kAXChildrenAttribute) as? [AXUIElement],
           !childrens.isEmpty
        {
            childrens.forEach() { element in
                if let childrens = getAttribute(element: element, name: kAXChildrenAttribute) as? [AXUIElement],
                   !childrens.isEmpty
                {
                    childrens.forEach() { element in
                        if let name = getAttribute(element: element, name: kAXTitleAttribute) as? String, !name.isEmpty,
                           getAttribute(element: element, name: kAXSizeAttribute) != nil,
                           (getAttribute(element: element, name: kAXEnabledAttribute) as? Bool) == true
                        {
                            let shortcutKey = getAttribute(element: element, name: kAXMenuItemCmdCharAttribute) as? String
                            
                            var shortcuts: [String]? = nil
                            if let shortcutKey = shortcutKey, !shortcutKey.isEmpty,
                               let modifiersValue = getAttribute(element: element, name: kAXMenuItemCmdModifiersAttribute) as? Int
                            {
                                shortcuts = modifierCombinations[modifiersValue]?.components(separatedBy: " ")
                                shortcuts?.append(shortcutKey)
                            }
                            
                            let submenu = MenuItem(name: name, axUIElement: element, parent: menu, shortcuts: shortcuts)
                            menu.subitems.append(submenu)
                            getSubitems(element: element, menu: submenu)
                        }
                    }
                }
            }
        }
    }
    
    static func performAction(at item: MenuItem)
    {
        guard let element = item.axUIElement, item.enabled else {
            return
        }
        AXUIElementPerformAction(element, kAXPressAction as CFString)
    }
}

