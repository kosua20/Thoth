//
//  Parser.swift
//  Siblog
//
//  Created by Simon Rodriguez on 25/01/2015.
//  Copyright (c) 2015 Simon Rodriguez. All rights reserved.
//

import Foundation


/**
*  An Article object represents an article loaded into memory from a .md file on disk
*/

class Article {
    
    // MARK: Properties
    
    /// The title of the article
    var title:String
    
    /// The content of the article, formatted in Markdown
    var content:String
    
    /// The date of publication of the article (if it is not a draft)
    var date:Date?
    
    /// The author of the article
    var author:String
    
    /// Denotes if the article is a draft or a published article
    var isDraft:Bool
    
    /// The string in the article file representing the date and the status of the article
    var dateString : String
    
    /// A short summary composed of the beginning of the article text, stripped of its HTML components
    fileprivate var summary : NSString
    
    
    
    // MARK: Initialisation
    
    /**
    Initialisation method
    
    - parameter title:      the title of the article
    - parameter date:       the date of the article (optional)
    - parameter author:     the author of the article
    - parameter content:    the content of the article
    - parameter isDraft:    denotes if the article is a draft or a published article
    - parameter dateString: a string representing the date and status of the article
    */
    
    init(title: String, date: Date?, author: String, content:String, isDraft: Bool, dateString: String){
        self.title = title
        self.date = date
        self.author = author
        self.content = content
        self.isDraft = isDraft
        self.dateString = dateString
        self.summary = ""
    }
    
    
    /**
    A secondary initialisation method to handle drafts more easily
    
    - parameter title:      the title of the article
    - parameter date:       the date of the article (optional)
    - parameter author:     the author of the article
    - parameter content:    the content of the article
    - parameter dateString: a string representing the date and state of the article
    */
    
    convenience init(title: String, date: Date?, author: String, content:String, dateString : String){
        self.init(title: title,date: date,author: author,content: content,isDraft: date==nil, dateString: date==nil ? "DRAFT" : dateString)
    }
    
    
    
    // MARK: Getters
    
    /**
    Returns the set of characters to keep for the summary generation. *This is a substitute for a class property*.
    
    - returns:   the set of characters to keep for the URL pathname generation.
    */
    class func getSetToKeep() -> NSMutableCharacterSet {
        return NSMutableCharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_")
    }
    
    
    /**
    Returns a summary of the beginning of the article, stripped from its non-textual elements
    
    - returns: A NSString containing the summary.
    */
    func getSummary() -> NSString {
        if summary.length == 0 {
            let contentHtml = content.mutableCopy() as! NSMutableString
            let regex1 = try? NSRegularExpression(pattern: "<(?!\\/*sup)[^>]+>", options: NSRegularExpression.Options.caseInsensitive)
            regex1?.replaceMatches(in: contentHtml, options: NSRegularExpression.MatchingOptions.reportProgress, range: NSMakeRange(0, contentHtml.length), withTemplate: "")

			let summaryNew : NSString = contentHtml.replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\r", with: "") as NSString
			let summaryFinal = summaryNew.substring(to: min(400, summaryNew.length)).trimmingCharacters(in: CharacterSet.whitespaces)
           // let range : NSRange = content2.rangeOfString("---")
            //if range.length > 0 {
              //  summaryNew = content2.substringToIndex(min(400,range.location))
            //}
			summary = NSString(string: summaryFinal + "...");
        }
        
        return summary
    }
    
    
    /**
    Returns the URL path name associated with the article and its title, conforms to the URL characters set.
    
    - returns: A String representing the URL path name of the article.
    */
    
    func getUrlPathname() -> String {
        var a = (dateString + "_") + title
        a = a.lowercased().decomposedStringWithCanonicalMapping
        a = a.replacingOccurrences(of: "/", with: "-")
        a = a.replacingOccurrences(of: " ", with: "_")
        a = a.components(separatedBy: Article.getSetToKeep().inverted).joined(separator: "")
        a = a + ".html"
        return a
    }
}


/**
*  The loader is responsible for loading the articles from files on the disk and generate the corresponding Articles objects
*/
class Loader {
    
    // MARK: Properties
    
    /// The path to the folder containing the articles files
    let folderPath: String
    /// An array for storing the generated articles
    var articles: [Article]
    /// The default author name
    var defaultAuthor: String
    /// A shared Date formatter
    let formatter : DateFormatter = DateFormatter();
    
    
    
    // MARK: Initialisation
    
    /**
    Initialisation method for the Loader class
    
    - parameter folderPath:    the path to the folder containing the articles .md files
    - parameter defaultAuthor: the name of he default author to use if no name is specified in an article file
    - parameter dateStyle:     the style of the date as written in the article file
    */
    
    init(folderPath: String, defaultAuthor: String, dateStyle: String){
        //Attributes
        self.folderPath = folderPath
        self.defaultAuthor = defaultAuthor
        self.articles = []
        //DateFormatter
        self.formatter.dateFormat = dateStyle //+ " HH:mm"
        //self.formatter.timeStyle = NSDateFormatterStyle.NoStyle
        //Reading files
        let fileManager = FileManager.default
        let directoryEnum = fileManager.enumerator(atPath: folderPath)
        while let file: AnyObject = directoryEnum?.nextObject() as AnyObject? {
            if (file as! String).pathExtension == "md" && !((file as! String).lastPathComponent.hasPrefix("_") || (file as! String).lastPathComponent.hasPrefix("#")) {
                // process the document
                self.loadFileAtPath(file as! String)
            }
        }
    }
    
    
    
    // MARK: Articles functions
    
    /**
    Loads the articles .md files in the given folder, generates Articles objects from those and store them in the `articles` array.
    
    - parameter path: the path to the folder where the articles files are stored
    */
    
    func loadFileAtPath(_ path : String){
        if let data: Data = FileManager.default.contents(atPath: folderPath.stringByAppendingPathComponent(path)) {
            if let str = NSString(data: data, encoding : String.Encoding.utf8.rawValue) {
                var arrayFull = str.components(separatedBy: "\n\n") 
                if arrayFull.count > 1 {
                    //Splitting the header
                    let arrayHeader = arrayFull[0].components(separatedBy: "\n") as [String]
                    //Treating the title (possible markdown on the beginning)
                    var title = arrayHeader[0]
                    title = title.replacingOccurrences(of: "##", with: "");
                    title = title.replacingOccurrences(of: "#", with: "", range: title.startIndex ..< title.characters.index(title.startIndex, offsetBy: 1, limitedBy: title.endIndex)!)
                    //Treating the date
                    var date = "draft"
                    var trueDate : Date? = nil;
                    if arrayHeader.count > 1{
                        date = arrayHeader[1]
                    }
                    if date.lowercased() != "draft" {
                        //date = date + "00:00"
                        trueDate = formatter.date(from: date)
                       
                    }
                    //Treating the author
                    var author = defaultAuthor
                    if arrayHeader.count > 2{
                        author = arrayHeader[2]
                    }
                    //Recreating the content of the article
                    arrayFull.removeSubrange(0..<1)
                    let articleContent = arrayFull.joined(separator: "\n\n")
                    //Creating the article
                    let art = Article(title: title, date: trueDate, author: author, content: articleContent, dateString:date)
                    articles.append(art)
                    return
                }
            }
        }
        //Fallback case
        let article = Article(title: "No title", date: nil, author: defaultAuthor, content: "No content - Probably an error in the generation of the page from the article. Or an empty article. Or worse.", isDraft: true, dateString:"error")
        articles.append(article)
    }
    
    
    /**
    Displays all articles in the console, for debugging purposes.

    - parameter showDrafts: if set to yes, the drafts will also be displayed
    */

    func printArticles(_ showDrafts : Bool){
        for article in articles {
            if !article.isDraft {
                print(article.title + " - " + formatter.string(from: article.date!) + " - " + article.author)
                //println("\t\t" + article.content.substringToIndex(advance(article.content.startIndex,30)))
            } else if showDrafts {
                print(article.title + " - DRAFT - " + article.author)
                // println("\t\t" + article.content.substringToIndex(advance(article.content.startIndex,30)))
            }
        }
    }
    
    
    /**
    Sorts the articles stored in the `articles` array by date of publication. The drafts articles are placed at the end of the array  
    */
    
    func sortArticles(){
        articles.sort(by: isFirstArticleEarlier)
    }
    
    
    /**
    Compare the two articles passed in arguments by their dates. By convention the drafts are considered older than any dated article.
    
    - parameter article1: the first article to compare
    - parameter article2: the second article to compare
    
    - returns: true is the first article has an earlier date than the first, else false
    */
    
    fileprivate func isFirstArticleEarlier(_ article1 : Article, article2: Article) -> Bool {
        if let article1Date = article1.date {
            if let article2Date = article2.date {
                return article1Date.timeIntervalSince(article2Date) <= 0
            } else {
                return true;
            }
        } else {
            return false
        }
    }
}
