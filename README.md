# MenuReader
macOS app menu items reader

![preview](https://github.com/MORECATS/MenuReader/blob/main/MenuReader/MenuReader_preview.png)

Sample usage:
> let top = MenuReader.getMenuItem(app: "Xcode")

Perform action:
> MenuReader.performAction(at: top.findSubitems(with: "About Xcode").first!)
