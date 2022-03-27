# MenuReader
macOS app menu items reader

![preview](https://github.com/MORECATS/MenuReader/blob/main/MenuReader/MenuReader_preview.png)

Sample usage:
> let xcodeMenu = MenuReader.getMenuItem(app: NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == "com.apple.Xcode" }))

Perform action:
> MenuReader.performAction(at: xcodeMenu.filter({ $0.title == "About Xcode" }).first!)
