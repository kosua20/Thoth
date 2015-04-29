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
    var date:NSDate?
    
    /// The author of the article
    var author:String
    
    /// Denotes if the article is a draft or a published article
    var isDraft:Bool
    
    /// The string in the article file representing the date and the status of the article
    var dateString : String
    
    /// A short summary composed of the beginning of the article text, stripped of its HTML components
    private var summary : NSString
    
    
    
    // MARK: Initialisation
    
    /**
    Initialisation method
    
    :param: title      the title of the article
    :param: date       the date of the article (optional)
    :param: author     the author of the article
    :param: content    the content of the article
    :param: isDraft    denotes if the article is a draft or a published article
    :param: dateString a string representing the date and status of the article
    */
    
    init(title: String, date: NSDate?, author: String, content:String, isDraft: Bool, dateString: String){
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
    
    :param: title      the title of the article
    :param: date       the date of the article (optional)
    :param: author     the author of the article
    :param: content    the content of the article
    :param: dateString a string representing the date and state of the article
    */
    
    convenience init(title: String, date: NSDate?, author: String, content:String, dateString : String){
        self.init(title: title,date: date,author: author,content: content,isDraft: date==nil, dateString: date==nil ? "DRAFT" : dateString)
    }
    
    
    
    // MARK: Getters
    
    /**
    Returns the set of characters to keep for the summary generation. *This is a substitute for a class property*.
    
    :returns:   the set of characters to keep for the URL pathname generation.
    */
    class func getSetToKeep() -> NSMutableCharacterSet {
        return NSMutableCharacterSet(charactersInString: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_")
    }
    
    
    /**
    Returns a summary of the beginning of the article, stripped from its non-textual elements
    
    :returns: A NSString containing the summary.
    */
    func getSummary() -> NSString {
        if summary.length == 0 {
            let content2 = content as NSString
            var summaryNew = content2.substringToIndex(min(300, content2.length)) + "..."
            let range : NSRange = content2.rangeOfString("---")
            if range.length > 0 {
                summaryNew = content2.substringToIndex(min(300,range.location))
            }
            summary = summaryNew;
        }
        return summary
    }
    
    
    /**
    Returns the URL path name associated with the article and its title, conforms to the URL characters set.
    
    :returns: A String representing the URL path name of the article.
    */
    
    func getUrlPathname() -> String {
        var a = dateString.stringByAppendingString("_").stringByAppendingString(title)
        a = a.lowercaseString.decomposedStringWithCanonicalMapping
        a = a.stringByReplacingOccurrencesOfString("/", withString: "-")
        a = a.stringByReplacingOccurrencesOfString(" ", withString: "_")
        a = "".join(a.componentsSeparatedByCharactersInSet(Article.getSetToKeep().invertedSet))
        a = a.stringByAppendingString(".html")
        return a
    }
}


/**
*  The laoder is responsible for loading the articles from files on the disk and generate the corresponding Articles objects
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
    let formatter : NSDateFormatter = NSDateFormatter();
    
    
    
    // MARK: Initialisation
    
    /**
    Initialisation method for the Loader class
    
    :param: folderPath    the path to the folder containing the articles .md files
    :param: defaultAuthor the name of he default author to use if no name is specified in an article file
    :param: dateStyle     the style of the date as written in the article file
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
        let fileManager = NSFileManager.defaultManager()
        let directoryEnum = fileManager.enumeratorAtPath(folderPath)
        while var file: AnyObject = directoryEnum?.nextObject() {
            if (file as! String).pathExtension == "md" && !((file as! String).lastPathComponent.hasPrefix("_") || (file as! String).lastPathComponent.hasPrefix("#")) {
                // process the document
                self.loadFileAtPath(file as! String)
            }
        }
    }
    
    
    
    // MARK: Articles functions
    
    /**
    Loads the articles .md files in the given folder, generates Articles objects from those and store them in the `articles` array.
    
    :param: path the path to the folder where the articles files are stored
    */
    
    func loadFileAtPath(path : String){
        if let data: NSData = NSFileManager.defaultManager().contentsAtPath(folderPath.stringByAppendingPathComponent(path)) {
            if let str = NSString(data: data, encoding : NSUTF8StringEncoding) {
                var arrayFull = str.componentsSeparatedByString("\n\n") as! [String]
                if arrayFull.count > 1 {
                    //Splitting the header
                    let arrayHeader = arrayFull[0].componentsSeparatedByString("\n") as [String]
                    //Treating the title (possible markdown on the beginning)
                    var title = arrayHeader[0]
                    title = title.stringByReplacingOccurrencesOfString("##", withString: "");
                    title = title.stringByReplacingOccurrencesOfString("#", withString: "", range: Range(start: title.startIndex, end: advance(title.startIndex,1,title.endIndex)))
                    //Treating the date
                    var date = "draft"
                    var trueDate : NSDate? = nil;
                    if arrayHeader.count > 1{
                        date = arrayHeader[1]
                    }
                    if date.lowercaseString != "draft" {
                        //date = date + "00:00"
                        trueDate = formatter.dateFromString(date)
                       
                    }
                    //Treating the author
                    var author = defaultAuthor
                    if arrayHeader.count > 2{
                        author = arrayHeader[2]
                    }
                    //Recreating the content of the article
                    arrayFull.removeRange(0..<1)
                    let articleContent = "\n\n".join(arrayFull)
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

    :param: showDrafts if set to yes, the drafts will also be displayed
    */

    func printArticles(showDrafts : Bool){
        for article in articles {
            if !article.isDraft {
                println(article.title + " - " + formatter.stringFromDate(article.date!) + " - " + article.author)
                //println("\t\t" + article.content.substringToIndex(advance(article.content.startIndex,30)))
            } else if showDrafts {
                println(article.title + " - DRAFT - " + article.author)
                // println("\t\t" + article.content.substringToIndex(advance(article.content.startIndex,30)))
            }
        }
    }
    
    
    /**
    Sorts the articles stored in the `articles` array by date of publication. The drafts articles are placed at the end of the array  
    */
    
    func sortArticles(){
        sort(&articles,isFirstArticleEarlier)
    }
    
    
    /**
    Compare the two articles passed in arguments by their dates. By convention the drafts are considered older than any dated article.
    
    :param: article1 the first article to compare
    :param: article2 the second article to compare
    
    :returns: true is the first article has an earlier date than the first, else false
    */
    
    private func isFirstArticleEarlier(article1 : Article, article2: Article) -> Bool {
        if let article1Date = article1.date {
            if let article2Date = article2.date {
                return article1Date.timeIntervalSinceDate(article2Date) <= 0
            } else {
                return true;
            }
        } else {
            return false
        }
    }
}