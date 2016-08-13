//
//  Renderer.swift
//  Siblog
//
//  Created by Simon Rodriguez on 27/01/2015.
//  Copyright (c) 2015 Simon Rodriguez. All rights reserved.
//

import Foundation

//TODO: générer sitemap.xml


/**
*  This class is in charge of rendering Articles objects as HTML pages on disk, generating an index page, a feed XML file and managing pictures and additional data.
*/
class Renderer {
    
    // MARK: Properties
    
    /// The array of articles to render
    let articlesToRender : [Article]
    
    /// The path of the output directory
    let exportPath: String
    
    /// The path to the directory where the template files are stored
    let templatePath : String
    
    /// The path to the additional resources directory
    let resourcesPath : String
    
    /// The path to the folder containing the articles files
    let articlesPath : String
    
    /// The title of the blog
    let blogTitle : String
    
    /// The root directory of the site once uploaded to the server
    let siteRoot : String

    /// Stores the HTML content of the article being currently generated
    private var articleHtml : NSString = ""
    
    /// Stores the HTML content of the index page
    private var indexHtml : NSString = ""
    
    /// The HTML code corresponding to a given articleon the index page
    private var snippetHtml : NSString = ""
    
    /// HTML content of the header
    private var headerHtml : NSString = ""
    
    /// HTML content for code syntax highlighting
    private var syntaxHtml : NSString = ""
    
    /// HTML content of the footer
    private var footerHtml : NSString = ""
    
    /// Index of the article being currently generated
    private var insertIndex = 0
    
    /// Shared instance of the Markdown parser
    private var markdown : Markdown
    
    
    
    // MARK: Initialisation
    
    /**
    Initialisation method for the Renderer
    
    - parameter articles:     an array of articles to render
    - parameter articlesPath: the path to the articles folder on disk
    - parameter exportPath:   the path of the output folder
    - parameter rootPath:     the path of the directory where the ressources directory is
    - parameter templatePath: the path to the tempalte folder
    - parameter defaultWidth: the default width of images inserted in articles
    - parameter blogTitle:    the title of the blog
    - parameter imagesLink:   if true, the images in articles are linking to the full size version of themselves
    - parameter siteRoot:     the root of the site once uploaded
    */
    init(articles: [Article], articlesPath : String, exportPath : String, rootPath : String, templatePath: String, defaultWidth : String, blogTitle : String, imagesLink : Bool, siteRoot : String){
        self.exportPath = exportPath
        self.articlesPath = articlesPath
        self.templatePath = templatePath
        self.resourcesPath = rootPath.stringByAppendingPathComponent("resources")
        self.articlesToRender = articles
        self.blogTitle = blogTitle
        self.siteRoot = siteRoot
        var options = MarkdownOptions()
        options.defaultWidth = defaultWidth
        options.imagesAsLinks = imagesLink
        markdown = Markdown(options: options)
        if !NSFileManager.defaultManager().fileExistsAtPath(exportPath) {
            do {
                try NSFileManager.defaultManager().createDirectoryAtPath(exportPath, withIntermediateDirectories: true, attributes: nil)
            } catch _ {
            }
        }
        initializeTemplate()
        loadTemplate()
    }
    
    
    
    // MARK: Template management
    
    /**
    Copies the template files in the output folder
    */
    private func initializeTemplate(){
        let templateFiles = (try! NSFileManager.defaultManager().contentsOfDirectoryAtPath(templatePath)) 
        for path in templateFiles{
            if !NSFileManager.defaultManager().fileExistsAtPath(exportPath.stringByAppendingPathComponent(path.lastPathComponent)){
                do {
                    try NSFileManager.defaultManager().copyItemAtPath(templatePath.stringByAppendingPathComponent(path), toPath: exportPath.stringByAppendingPathComponent(path.lastPathComponent))
                } catch _ {
                }
            }
        }
        do {
            //NSFileManager.defaultManager().removeItemAtPath(exportPath.stringByAppendingPathComponent("index.html"), error: nil)
            try NSFileManager.defaultManager().removeItemAtPath(exportPath.stringByAppendingPathComponent("article.html"))
        } catch _ {
        }
    }
	
    /**
    Loads the template data (HTML snippets) from the template files
    */
    private func loadTemplate(){
        if let data: NSData = NSFileManager.defaultManager().contentsAtPath(templatePath.stringByAppendingPathComponent("article.html")) {
            if let str = NSString(data: data, encoding : NSUTF8StringEncoding) {
                articleHtml = str
            } else {
                print("Unable to load the article.html template.")
            }
        } else {
            print("Unable to load the article.html template.")
        }
        
        if let data: NSData = NSFileManager.defaultManager().contentsAtPath(templatePath.stringByAppendingPathComponent("syntax.html")) {
            if let str = NSString(data: data, encoding : NSUTF8StringEncoding) {
                syntaxHtml = str
            } else {
                print("Unable to load the syntax highlighting header template, default to \"\".")
                syntaxHtml = ""
            }
        } else {
            
        }
        
        if let data: NSData = NSFileManager.defaultManager().contentsAtPath(templatePath.stringByAppendingPathComponent("index.html")) {
            if let str = NSString(data: data, encoding : NSUTF8StringEncoding) {
                indexHtml = str
            } else {
                print("Unable to load the index.html template.")
            }
        } else {
            print("Unable to load the index.html template.")
        }
        
        if indexHtml.length > 0 {
            snippetHtml = extractSnippetHtml(indexHtml)
            if snippetHtml.length == 0 {
                print("Unable to extract the short-article snippet from the index.html template file.")
                return
            }
            headerHtml = indexHtml.substringToIndex(insertIndex)
            //println("\(snippetHtml.length),\(insertIndex)")
            footerHtml = indexHtml.substringFromIndex(insertIndex + 30 + snippetHtml.length)
        }
    }
	
    /**
    Restores the template content in the output folder
    */
    private func restoreTemplate(){
        let templateFiles = (try! NSFileManager.defaultManager().contentsOfDirectoryAtPath(templatePath)) 
        for path in templateFiles{
            do {
                try NSFileManager.defaultManager().copyItemAtPath(templatePath.stringByAppendingPathComponent(path), toPath: exportPath.stringByAppendingPathComponent(path.lastPathComponent))
            } catch _ {
            }
        }
        do {
            try NSFileManager.defaultManager().removeItemAtPath(exportPath.stringByAppendingPathComponent("index.html"))
        } catch _ {
        }
        do {
            try NSFileManager.defaultManager().removeItemAtPath(exportPath.stringByAppendingPathComponent("article.html"))
        } catch _ {
        }
    }
	
	/**
	Extracts the HTMl code corresponding to an article on the index page
	
	- parameter code: the HTML code of the index page from the template
	
	- returns: the extracted HTML snippet
	*/
	private func extractSnippetHtml(code : NSString)-> NSString{
		let scanner = NSScanner(string:  code as String)
		var res : NSString?
		scanner.scanUpToString("{#ARTICLE_BEGIN}", intoString: nil)
		insertIndex = scanner.scanLocation
		scanner.scanUpToString("{#ARTICLE_END}", intoString: &res)
		if let str2 : NSString = res?.substringFromIndex(16) {
			return str2
		}
		return ""
	}
	
	
	
	//MARK: Combining functions
	
	/**
	Renders the index page, and updates the resources directory.
	*/
    func updateIndex(){
		for article in articlesToRender {
			if !article.isDraft {
				var contentHtml = markdown.transform(article.content)
				contentHtml = addFootnotes(contentHtml)
				article.content = contentHtml
			}
		}
        renderIndex()
        copyResources(false)
    }
	
	/**
	Default export. Renders the new articles, clean and renders drafts again, renders the index and draft index pages, and updates the resources directory.
	*/
    func defaultExport(){
        renderArticles(false)
        renderDrafts(true)
        renderIndex()
        renderDraftIndex()
        copyResources(false)
        print("Index written at path " + exportPath.stringByAppendingPathComponent("index.html"))
    }
	
	/**
	Regenerates all published articles, renders the index page and update the resources directory.
	*/
    func articlesOnly(){
        renderArticles(true)
        renderIndex()
        copyResources(false)
        print("Index written at path " + exportPath.stringByAppendingPathComponent("index.html"))
    }
	
	/**
	Regenerates all published articles, update drafts, renders index and draft index pages, and updates the resources directory.
	*/
    func articlesForceOnly() {
        renderArticles(true)
        renderDrafts(false)
        renderIndex()
        renderDraftIndex()
        copyResources(false)
        print("Index written at path " + exportPath.stringByAppendingPathComponent("index.html"))
    }
	
	/**
	Regenerates all draft articles, renders the drafts index page and update the resources directory.
	*/
    func draftsOnly(){
        renderDrafts(true)
        renderDraftIndex()
        copyResources(false)
        print("Drafts index written at path " + exportPath.stringByAppendingPathComponent("index-drafts.html"))
    }
	
	/**
	Regenerates all draft articles, update published articles, renders index and draft index pages, and updates the resources directory.
	*/
    func draftsForceOnly() {
        renderDrafts(true)
        renderArticles(false)
        renderDraftIndex()
        renderIndex()
        copyResources(false)
        print("Drafts index written at path " + exportPath.stringByAppendingPathComponent("index-drafts.html"))
    }
	
	/**
	Cleans the output directory, restores the template, generates all articles and drafts, the index and drafts index pages, and copies the resources directory.
	*/
    func fullExport() {
        clean()
        restoreTemplate()
        renderArticles(true)
        renderDrafts(true)
        renderIndex()
        renderDraftIndex()
        copyResources(true)
        print("Index written at path " + exportPath.stringByAppendingPathComponent("index.html"))
    }
	
	/**
	Force-update the resources directory
	*/
    func updateResources(){
        copyResources(true)
    }
	
	/**
	Copies additional resources in the output directory.

	- parameter forceUpdate: if true, previous resources will be erased
	*/
	private func copyResources(forceUpdate : Bool){
		if NSFileManager.defaultManager().fileExistsAtPath(resourcesPath) {
			let exportResourcesPath = exportPath.stringByAppendingPathComponent("resources")
			if !NSFileManager.defaultManager().fileExistsAtPath(exportResourcesPath) {
				do {
                    try NSFileManager.defaultManager().createDirectoryAtPath(exportResourcesPath, withIntermediateDirectories: true, attributes: nil)
                } catch _ {
                }
			}
			let paths = (try! NSFileManager.defaultManager().contentsOfDirectoryAtPath(resourcesPath))
			for path in paths {
				if forceUpdate || !NSFileManager.defaultManager().fileExistsAtPath(exportResourcesPath.stringByAppendingPathComponent(path as String)){
					do {
                        try NSFileManager.defaultManager().copyItemAtPath(resourcesPath.stringByAppendingPathComponent(path as String), toPath: exportResourcesPath.stringByAppendingPathComponent(path as String))
                    } catch _ {
                    }
				}
			}
		}
		
	}
	
	
	
	//MARK: Rendering
	
	/**
	Renders the published articles as HTML files on disk, parsing the markdown content and mananging the pictures and ressources.
	
	- parameter forceUpdate: true if previously generated articles should be generated
	*/
    private func renderArticles(forceUpdate : Bool){
        if forceUpdate {
            cleanFolder("articles")
        }
        for article in articlesToRender {
            if !article.isDraft {
                renderArticle(article, inFolder: "articles", forceUpdate : forceUpdate)
            }
        }
    }
	
	/**
	Renders the index page listing all published articles, and the feed.xml RSS file.
	*/
	private func renderIndex() {
        //println("Rendering index")
		indexHtml = footerHtml.copy() as! NSString
		
		var feedXml = "<?xml version=\"1.0\" ?>\n"
			+ "<rss version=\"2.0\">\n"
			+ "<channel>\n"
			+ "<title>\(blogTitle)</title>\n"
		feedXml = feedXml + "<link>http://" + siteRoot + "</link>\n"
			+ "<description>\(blogTitle), a blog.</description>\n"
		let dateOutputFormatter = NSDateFormatter()
		dateOutputFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
		dateOutputFormatter.locale = NSLocale(localeIdentifier: "en")
		
		for article in articlesToRender {
			if !article.isDraft {
				var html : NSString = snippetHtml.copy() as! NSString
				html = html.stringByReplacingOccurrencesOfString("{#TITLE}", withString: article.title)
				html = html.stringByReplacingOccurrencesOfString("{#DATE}", withString: article.dateString)
				html = html.stringByReplacingOccurrencesOfString("{#AUTHOR}", withString: article.author)
				html = html.stringByReplacingOccurrencesOfString("{#LINK}", withString: "articles/"+article.getUrlPathname())
				let contentHtml : NSString = article.getSummary()
				html = html.stringByReplacingOccurrencesOfString("{#SUMMARY}", withString: contentHtml as String)
				indexHtml = NSString(format: "%@\n%@", html,indexHtml)
				
				let dateOutput = dateOutputFormatter.stringFromDate(article.date!)
				// println("date: \(article.date)")
				feedXml = feedXml
					+ "<item>\n"
				feedXml = feedXml + "<title>\(article.title)</title>\n"
					+ "<pubDate>" + dateOutput + "</pubDate>\n"
					+ "<link>http://" + siteRoot + "/articles/\(article.getUrlPathname())</link>\n"
					+ "<description>\(contentHtml)</description>\n"
				feedXml = feedXml + "<guid>http://" + siteRoot + "/articles/\(article.getUrlPathname())</guid>\n"
					+ "</item>\n"
			}
		}
		
		feedXml = feedXml + "</channel>\n</rss>"
		indexHtml = headerHtml.stringByAppendingString(indexHtml as String)
		indexHtml = indexHtml.stringByReplacingOccurrencesOfString("{#BLOG_TITLE}", withString: blogTitle)
	NSFileManager.defaultManager().createFileAtPath(exportPath.stringByAppendingPathComponent("index.html"), contents: indexHtml.dataUsingEncoding(NSUTF8StringEncoding), attributes: nil)
	NSFileManager.defaultManager().createFileAtPath(exportPath.stringByAppendingPathComponent("feed.xml"), contents: feedXml.dataUsingEncoding(NSUTF8StringEncoding), attributes: nil)
		
	}
	
	/**
	Renders the draft index page, listing only draft articles.
	*/
	private func renderDraftIndex() {
		indexHtml = footerHtml.copy() as! NSString
		for article in articlesToRender {
			if article.isDraft {
				var html : NSString = snippetHtml.copy() as! NSString
				html = html.stringByReplacingOccurrencesOfString("{#TITLE}", withString: article.title)
				html = html.stringByReplacingOccurrencesOfString("{#DATE}", withString: article.dateString)
				html = html.stringByReplacingOccurrencesOfString("{#AUTHOR}", withString: article.author)
				html = html.stringByReplacingOccurrencesOfString("{#LINK}", withString: "drafts/"+article.getUrlPathname())
				let contentHtml = article.getSummary()
				html = html.stringByReplacingOccurrencesOfString("{#SUMMARY}", withString: contentHtml as String)
				indexHtml = NSString(format: "%@\n%@", html,indexHtml)
			}
		}
		indexHtml = headerHtml.stringByAppendingString(indexHtml as String)
		indexHtml = indexHtml.stringByReplacingOccurrencesOfString("{#BLOG_TITLE}", withString: blogTitle.stringByAppendingString(" - Drafts"))
		NSFileManager.defaultManager().createFileAtPath(exportPath.stringByAppendingPathComponent("index-drafts.html"), contents: indexHtml.dataUsingEncoding(NSUTF8StringEncoding), attributes: nil)
	}
	
	/**
	Renders the drafts articles as HTML files on disk, parsing the markdown content and mananging the pictures and ressources.
	
	- parameter forceUpdate: true if previously generated drafts should be generated
	*/
    private func renderDrafts(forceUpdate : Bool){
        if forceUpdate {
            cleanFolder("drafts")
        }
        for article in articlesToRender {
            if article.isDraft {
                renderArticle(article, inFolder: "drafts", forceUpdate : forceUpdate)
            }
        }
    }
	
	/**
	Renders a given article in the given folder, generating an HTML file and additionally copying linked images in a specific sub-folder.
	
	- parameter article:     the article to render
	- parameter folder:      the directory in which the generated HTML article should be exported
	- parameter forceUpdate: true if previous version of the article should be erased
	*/
    private func renderArticle(article : Article, inFolder folder : String, forceUpdate : Bool){
        //println("Rendering article: \(article.title)")
        let filePath = exportPath.stringByAppendingPathComponent(folder).stringByAppendingPathComponent(article.getUrlPathname())
        var contentHtml = markdown.transform(article.content)
        contentHtml = addFootnotes(contentHtml)
        article.content = contentHtml
        if forceUpdate || !NSFileManager.defaultManager().fileExistsAtPath(filePath){
            var html: NSString = articleHtml.copy() as! NSString
            html = html.stringByReplacingOccurrencesOfString("{#TITLE}", withString: article.title)
            html = html.stringByReplacingOccurrencesOfString("{#DATE}", withString: article.dateString)
            html = html.stringByReplacingOccurrencesOfString("{#AUTHOR}", withString: article.author)
            html = html.stringByReplacingOccurrencesOfString("{#BLOG_TITLE}", withString: blogTitle)
            html = html.stringByReplacingOccurrencesOfString("{#LINK}", withString: article.getUrlPathname())
            html = html.stringByReplacingOccurrencesOfString("{#SUMMARY}", withString: article.getSummary() as String)
           
            
            contentHtml = manageImages(contentHtml,links: markdown.imagesUrl, path: filePath, forceUpdate : forceUpdate)
            if (contentHtml.rangeOfString("<pre><code>")?.startIndex != nil ){
                html = html.stringByReplacingOccurrencesOfString("</head>", withString: "\n" + (syntaxHtml as String) + "\n</head>")
            }
            html = html.stringByReplacingOccurrencesOfString("{#CONTENT}", withString: contentHtml)
            
            NSFileManager.defaultManager().createFileAtPath(filePath, contents: html.dataUsingEncoding(NSUTF8StringEncoding), attributes: nil)
        }
    }
	
	
	
	//MARK: Additional processing
	
	/**
	Parses the article content to detect images links, copy the images files in an article-specific directory and update the links accordingly.
	
	- parameter content:     the content of the article
	- parameter links:       the list of images links present in the article
	- parameter filePath:	the path to the folder where the images files should be copied
	- parameter forceUpdate: indicates whether the images files should be force-updated or not
	
	- returns: return the updated HTML content of the article
	*/
    private func manageImages(var content : String, links : [String], path filePath : String, forceUpdate : Bool) -> String {
        if links.count > 0 {
            if !NSFileManager.defaultManager().fileExistsAtPath(filePath.stringByDeletingPathExtension) {
                do {
                    try NSFileManager.defaultManager().createDirectoryAtPath(filePath.stringByDeletingPathExtension, withIntermediateDirectories: true, attributes: nil)
                } catch _ {
                }
            }
            for link in links {
                if !link.hasPrefix("http://") && !link.hasPrefix("www.") {
                    //We are now sure the file is stored locally
                    let path = expandLink(link)
                    if NSFileManager.defaultManager().fileExistsAtPath(path) {
                        let newFilePath = filePath.stringByDeletingPathExtension.stringByAppendingPathComponent(path.lastPathComponent)
                        if forceUpdate || !NSFileManager.defaultManager().fileExistsAtPath(newFilePath) {
                            do {
                                try NSFileManager.defaultManager().copyItemAtPath(path, toPath: newFilePath)
                            } catch _ {
                            }
                            content = content.stringByReplacingOccurrencesOfString(link, withString: filePath.lastPathComponent.stringByDeletingPathExtension.stringByAppendingPathComponent(path.lastPathComponent), options: [], range: nil)
                        }
                    } else {
                        print("Warning: some images were not found")
                    }
                }
            }
        }
        return content
    }
	
	/**
	Convenience method to expand filepaths
	
	- parameter link: the path String to expand
	
	- returns: the expanded path
	*/
    private func expandLink(link : String) -> String {
        if link.hasPrefix("/") {
            //Absolute path
            return link
        } else {
            //Relative path
            //Apparemment NSFileManager gère ça tout seul, à tester avec des images dans un dossier du dossier parent.
            return articlesPath.stringByAppendingPathComponent(link)
        }
    }
	
	/**
	Parses the article content to extract and generate footnotes HTML code.
	
	- parameter content: the content of the article
	
	- returns: the HTML content of the article, with the footnotes added at the end
	*/
    private func addFootnotes(content : String) -> String{
        //TODO: gérer les footnotes référencées
        var count = 1
        let scanner1 = NSScanner(string: content)
        var newContent = ""
        var tempContent : NSString?
        var endContent = "\n<br>\n<br>\n<hr><ol>\n"
        var footNote : NSString?
        scanner1.scanUpToString("[^", intoString: &tempContent)
        if scanner1.atEnd {
            if let tempContent = tempContent {
                newContent = newContent.stringByAppendingString(tempContent as String)
            }
        }
        var isFirst = true
        var loopUsed = false
        while !scanner1.atEnd {
            loopUsed = true
            if let tempContent = tempContent {
                if isFirst {
                    newContent = newContent.stringByAppendingString(tempContent as String)
                    isFirst = false
                } else {
                    newContent = newContent.stringByAppendingString(tempContent.substringFromIndex(1))
                }
            }
            _ = scanner1.scanLocation
            scanner1.scanUpToString("]", intoString: &footNote)
            if var footNote : NSString = footNote {
                footNote = footNote.substringFromIndex(2)
                newContent = newContent.stringByAppendingString("<sup id=\"ref\(count)\"><a class=\"footnote-link\" href=\"#fn\(count)\" title=\"\" rel=\"footnote\">[\(count)]</a></sup>")
                endContent = endContent + "<li id=\"fn\(count)\" class=\"footnote\"><p>\(footNote) <a class=\"footnote-link\" href=\"#ref\(count)\" title=\"Return to footnote in the text.\" >&#8617;</a></p></li>\n"
                count+=1
            }
            scanner1.scanUpToString("[^", intoString: &tempContent)
        }
        if loopUsed {
            if let tempContent = tempContent {
                newContent = newContent.stringByAppendingString(tempContent.substringFromIndex(1))
            }
        }
        endContent += "</ol>\n"
        newContent += endContent
        return newContent
    }
	
	
	
	//MARK: Cleaning
	
	/**
	Removes everything from the output folder before regenerating the directories
	*/
	private func clean(){
		if NSFileManager.defaultManager().fileExistsAtPath(exportPath) {
			do {
                try NSFileManager.defaultManager().removeItemAtPath(exportPath)
            } catch _ {
            }
		}
		do {
            try NSFileManager.defaultManager().createDirectoryAtPath(exportPath, withIntermediateDirectories: true, attributes: nil)
        } catch _ {
        }
		do {
            try NSFileManager.defaultManager().createDirectoryAtPath(exportPath.stringByAppendingPathComponent("articles"), withIntermediateDirectories: true, attributes: nil)
        } catch _ {
        }
		do {
            try NSFileManager.defaultManager().createDirectoryAtPath(exportPath.stringByAppendingPathComponent("drafts"), withIntermediateDirectories: true, attributes: nil)
        } catch _ {
        }
	}
	
	/**
	Cleans the given directory (empties it).
	
	- parameter folder: the path to the folder to clean, relative to the export path
	*/
	private func cleanFolder(folder : String) {
		let folderPath = exportPath.stringByAppendingPathComponent(folder)
		if NSFileManager.defaultManager().fileExistsAtPath(folderPath) {
			do {
                try NSFileManager.defaultManager().removeItemAtPath(folderPath)
            } catch _ {
            }
		}
		do {
            try NSFileManager.defaultManager().createDirectoryAtPath(folderPath, withIntermediateDirectories: true, attributes: nil)
        } catch _ {
        }
	}

}