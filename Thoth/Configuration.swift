//
//  Configuration.swift
//  Siblog
//
//  Created by Simon Rodriguez on 08/02/2015.
//  Copyright (c) 2015 Simon Rodriguez. All rights reserved.
//

import Foundation

struct Config {
    let selfPath = ""
    let templatePath = ""
    let articlesPath = ""
    let outputPath = ""
    let defaultAuthor = "John Appleseed"
    let dateStyle = "MM/dd/YYYY"
    let blogTitle = "A new blog"
    let imageWidth = "640"
    let imagesLinks = false
    let ftpAdress = ""
    let ftpUsername = ""
    let ftpPassword = ""
    let ftpPort = 21
    
}

class ConfigLoader {
    
    class func loadConfigFileAtPath(path: String) -> Config{
        //Defaults
        var templatePath = path.stringByDeletingLastPathComponent.stringByAppendingPathComponent("template")
        var articlesPath = path.stringByDeletingLastPathComponent.stringByAppendingPathComponent("articles")
        var outputPath = path.stringByDeletingLastPathComponent.stringByAppendingPathComponent("output")
        var defaultAuthor = ""
        var dateStyle = "MM/dd/YYYY"
        var blogTitle = "A new blog"
        var imageWidth = "640"
        var imagesLinks = false
        var ftpAdress = ""
        var ftpUsername = ""
        var ftpPassword = ""
        var ftpPort = 21
        
        if let data = NSFileManager.defaultManager().contentsAtPath(path) {
            if let contentOfConfigFile = NSString(data: data, encoding: NSUTF8StringEncoding) {
                let lines = contentOfConfigFile.componentsSeparatedByString("\n")
                for line in lines {
                    if !(line.hasPrefix("_") || line.hasPrefix("#")) {
                        //Ignoring the comments
                        let newLines = line.componentsSeparatedByString(":") as [String]
                        if newLines.count > 1 {
                            //var value = newLines[1].stringByReplacingOccurrencesOfString("\\ ", withString: "{#PL@CEHO£D&R$}", options: nil, range: nil)
                            var value = newLines[1].stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
                            if value != "" {
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
                                case "imagesLinks":
                                    imagesLinks = (value=="true")
                                case "ftpAdress":
                                    ftpAdress = value
                                case "ftpUsername":
                                    ftpUsername = value
                                case "ftpPassword":
                                    ftpPassword = value
                                case "ftpPort":
                                    if let intvalue = value.toInt() {
                                        ftpPort = intvalue
                                    }
                                default:
                                    break
                                }
                            }
                        }
                        
                    }
                }
            }
        }
        
        return Config(selfPath:path,templatePath: templatePath, articlesPath: articlesPath, outputPath: outputPath, defaultAuthor: defaultAuthor, dateStyle: dateStyle, blogTitle: blogTitle, imageWidth: imageWidth, imagesLinks: imagesLinks, ftpAdress: ftpAdress, ftpUsername:ftpUsername, ftpPassword:ftpPassword,ftpPort:ftpPort)
    }
    
    class func saveConfigFile(configuration : Config){
        let dict = [
            "templatePath":"# The path to the template folder\n#\t(defaults to rootPath/template)\n",
            "articlesPath":"# The path to the articles folder containing the .md files\n#\t(defaults to rootPath/articles)\n",
            "outputPath":"# The path where Thoth should output the generated content\n#\t(defaults to rootPath/output)\n",
            "blogTitle":"# The title of the blog\n#\t(defaults to \"A new blog\")\n",
            "defaultAuthor":"# The default author name to use on each article page\n#\t(defaults to the current Mac user)\n",
            "dateStyle":"# The date style used in each article (.md file)\n# Please see the NSDateFormatter documentation for this\n#\t(defaults to MM/dd/yyyy)\n",
            "imageWidth":"# The default width for each image in articles html pages.\n#\t(defaults to 640)\n",
            "imagesLinks":"# Set to true if you want each image of an article to link directly to the corresponding file\n#\t(defaults to false)\n",
            "ftpAdress":"# The ftp address pointing to the exact folder where the output should be uploaded\n",
            "ftpUsername":"# The ftp username\n",
            "ftpPassword":"# The ftp password (the best way is to create a specific user/password with restricted rights to access your FTP)\n",
            "ftpPort":"# The ftp port to use\n#\t(defaults to 21)\n",
        ]
        
        var s = "#{#Thoth} config file\n#The root path is deduced from the position of this config file\n\n"
        let ref = reflect(configuration)
        for i in 0..<ref.count {
            let tr = "\(ref[i].1.value)"
            let key = ref[i].0
            if key != "selfPath"{
                if let exp = dict[key] {
                    s = s + exp
                }
                s = s + key + ":" + "\t\t" + tr + "\n\n"
            }
        }
        if !NSFileManager.defaultManager().createFileAtPath(configuration.selfPath, contents: s.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false), attributes: nil) {
            println("Unable to save the config")
        }
    }
    
    class func generateConfigFileAtPath(path : String)-> Config{
        var configuration = Config(selfPath: path.stringByAppendingPathComponent("config"), templatePath: path.stringByAppendingPathComponent("template"), articlesPath: path.stringByAppendingPathComponent("articles"), outputPath: path.stringByAppendingPathComponent("output"), defaultAuthor: NSFullUserName(), dateStyle: "MM/dd/YYYY", blogTitle: "A new blog", imageWidth: "640", imagesLinks: false, ftpAdress: "", ftpUsername: "", ftpPassword: "", ftpPort: 21)
        
        saveConfigFile(configuration)
        return configuration
    }
    
}