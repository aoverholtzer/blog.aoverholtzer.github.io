import Foundation
import Publish
import Plot
import HighlightJSPublishPlugin

// This type acts as the configuration for your website.
struct OverdesignedBlog: Website {
    enum SectionID: String, WebsiteSectionID {
        // Add the sections that you want your website to contain here:
        case posts
    }

    struct ItemMetadata: WebsiteItemMetadata {
        // Add any site-specific metadata that you want to use here.
    }

    // Update these properties to configure your website:
    var url = URL(string: "https://blog.overdesigned.com")!
    var name = "overdesigned blog"
    var description = "A blog by Adam Overholtzer"
    var language: Language { .english }
    var imagePath: Path? { nil }
    var favicon = Favicon()
}

// This will generate your website using the built-in Foundation theme:
try OverdesignedBlog()
//    .publish(withTheme: .overdesigned,
//             rssFeedSections: [.posts],
//             plugins: [ .highlightJS() ])
    .publish(using: [
    .installPlugin(.highlightJS()),
    .addMarkdownFiles(),
    .copyResources(),
    .generateHTML(withTheme: .overdesigned),
    .generateRSSFeed(including: [.posts]),
    //.generateSiteMap()
    .deploy(using: .gitHub("aoverholtzer/blog.aoverholtzer.github.io"))
])
