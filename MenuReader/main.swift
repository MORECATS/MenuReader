//
//  main.swift
//  MenuReader
//
//  Created by YICAI YANG on 2021/11/12.
//

import Foundation
import AppKit

extension String
{
    var allIsDigits: Bool { allSatisfy({ Int(String($0)) != nil }) }
}

if CommandLine.arguments.count > 1
{
    let name = CommandLine.arguments[1]
    var menuRoot: MenuReader.MenuItem?
    
    if name.allIsDigits,
       let pid = pid_t(name),
       let menu = MenuReader.getMenuItems(pid: pid)
    {
        menuRoot = menu
        MenuReader.prettyPrint(menu)
    }
    else if let app = NSWorkspace.shared.runningApplications.first(where: { $0.localizedName == name }),
            let menu = MenuReader.getMenuItems(app: app)
    {
        menuRoot = menu
        MenuReader.prettyPrint(menu)
    }
    
    if CommandLine.arguments.count == 3,
       let action = CommandLine.arguments.last,
       let menuRoot = menuRoot,
       let item = menuRoot.findSubitems(with: action)?.first
    {
        MenuReader.performAction(at: item)
    }
}
else if let menu = MenuReader.getMenuItems()
{
    MenuReader.prettyPrint(menu)
    
    let items = menu.findSubitems(with: "Report an Issue")
    print("items: \(items?.first?.name)")
    if let item = items?.first
    {
        MenuReader.performAction(at: item)
    }
}
