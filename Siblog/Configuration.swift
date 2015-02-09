//
//  Configuration.swift
//  Siblog
//
//  Created by Simon Rodriguez on 08/02/2015.
//  Copyright (c) 2015 Simon Rodriguez. All rights reserved.
//

import Foundation

struct Config {
    let templatePath = ""
    let articlesPath = ""
    let outputPath = ""
    let defaultAuthor = "John Appleseed"
    let dateStyle = "dd/mm/YYYY"
    let blogTitle = "A new blog"
    let imageWidth = "640"
    
}

class ConfigLoader {
    
    class func loadConfigFileAtPath(path: String) -> Config{
        //Defaults
        var templatePath = ""
        var articlesPath = ""
        var outputPath = ""
        var defaultAuthor = "John Appleseed"
        var dateStyle = "dd/mm/YYYY"
        var blogTitle = "A new blog"
        var imageWidth = "640"
        
        if let data = NSFileManager.defaultManager().contentsAtPath(path) {
            if let contentOfConfigFile = NSString(data: data, encoding: NSUTF8StringEncoding) {
               let lines = contentOfConfigFile.componentsSeparatedByString("\n")
                for line in lines {
                    if !line.hasPrefix("#"){
                        //Ignoring the comments
                        let newLines = line.componentsSeparatedByString(":") as [String]
                        if newLines.count > 1 {
                            //var value = newLines[1].stringByReplacingOccurrencesOfString("\\ ", withString: "{#PL@CEHO£D&R$}", options: nil, range: nil)
                            var value = newLines[1].stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
                            switch newLines[0] as String {
                                case "templatePath":
                                    templatePath = value
                                case "articlesPath":
                                    articlesPath = value
                                case "outputPath":
                                    outputPath = value
                                case "defaultAuthor":
                                    defaultAuthor = value
                                case "dateStyle":
                                    dateStyle = value
                                case "blogTitle":
                                    blogTitle = value
                                case "imageWidth":
                                    imageWidth = value
                            default:
                                break
                            }
                        }
                    }
                }
            }
        }
        return Config(templatePath: templatePath, articlesPath: articlesPath, outputPath: outputPath, defaultAuthor: defaultAuthor, dateStyle: dateStyle, blogTitle: blogTitle, imageWidth: imageWidth)
    }
    
    class func saveConfigFile(configuration : Config, atPath path : String){
        
    }

}