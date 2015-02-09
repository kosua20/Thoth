//
//  Parser.swift
//  Siblog
//
//  Created by Simon Rodriguez on 25/01/2015.
//  Copyright (c) 2015 Simon Rodriguez. All rights reserved.
//

import Foundation

class Article {
    var title:String
    var content:String
    var date:NSDate?
    var author:String
    var isDraft:Bool
    var dateString : String
    //class let setToKeep = NSMutableCharacterSet(charactersInString: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_")

    
    init(title: String, date: NSDate?, author: String, content:String, isDraft: Bool, dateString: String){
        self.title = title
        self.date = date
        self.author = author
        self.content = content
        self.isDraft = isDraft
        self.dateString = dateString
    }
    
    convenience init(title: String, date: NSDate?, author: String, content:String, dateString : String){
        
        self.init(title: title,date: date,author: author,content: content,isDraft: date==nil, dateString: date==nil ? "DRAFT" : dateString)
    }
    
    class func getSetToKeep() -> NSMutableCharacterSet {
        return NSMutableCharacterSet(charactersInString: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_")
    }
    
    func getSummary() -> NSString {
        let content2 = content as NSString
        var summary = content2.substringToIndex(min(300, content2.length)) + "..."
        let range : NSRange = content2.rangeOfString("---")
        if range.length > 0 {
            summary = content2.substringToIndex(min(300,range.location))
        }
        return summary
    }
    
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

class Loader {
    let folderPath: String
    var articles: [Article]
    var defaultAuthor: String
    let formatter : NSDateFormatter = NSDateFormatter();
    
    init(folderPath: String, defaultAuthor: String, dateStyle: String){
        //Attributes
        self.folderPath = folderPath
        self.defaultAuthor = defaultAuthor
        self.articles = []
        //DateFormatter
        self.formatter.dateFormat = dateStyle
        //Reading files
        let fileManager = NSFileManager.defaultManager()
        let directoryEnum = fileManager.enumeratorAtPath(folderPath)
        while var file: AnyObject = directoryEnum?.nextObject() {
           if (file as String).pathExtension == "md" {
                // process the document
                self.loadFileAtPath(file as String)
            }
        }
    }
    
    func loadFileAtPath(path : String){
        if let data: NSData = NSFileManager.defaultManager().contentsAtPath(folderPath.stringByAppendingPathComponent(path)) {
            if let str = NSString(data: data, encoding : NSUTF8StringEncoding) {
                var arrayFull = str.componentsSeparatedByString("\n\n") as [String]
                if arrayFull.count > 1 {
                    //Splitting the header
                    let arrayHeader = arrayFull[0].componentsSeparatedByString("\n") as [String]
                    //Treating the title (possible markdown on the beginning)
                    var title = arrayHeader[0]
                    title = title.stringByReplacingOccurrencesOfString("##", withString: "");
                    title = title.stringByReplacingOccurrencesOfString("#", withString: "", range: Range(start: title.startIndex, end: advance(title.startIndex,1)))
                    //Treating the date
                    var date = "draft"
                    var trueDate : NSDate? = nil;
                    if arrayHeader.count > 1{
                         date = arrayHeader[1]
                    }
                    if date.lowercaseString != "draft" {
                            trueDate = formatter.dateFromString(date)!
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
    
    func sortArticles(){
        sort(&articles,isFirstArticleEarlier)
    }
    
    func isFirstArticleEarlier(article1 : Article, article2: Article) -> Bool {
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