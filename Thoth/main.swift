//
//  main.swift
//  Siblog
//
//  Created by Simon Rodriguez on 25/01/2015.
//  Copyright (c) 2015 Simon Rodriguez. All rights reserved.
//

import Foundation


func main(args : [String] = []){
    
    if Process.arguments.count > 1 {
        generateWithRootPath(Process.arguments[1])
        exit(0)
    }
    
    println("Welcome in {#THOTH}, a static blog generator.")
    let prompt: Prompt = Prompt(argv0: C_ARGV[0])
    
    while true {
        if let input = prompt.gets() {
            var input2 = input.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            if input2 == "help" {
                println("Here's your help")
            } else if input2.hasPrefix("generate ") {
                //For now, no options so no need to split
                let rootPath = input2.substringFromIndex(advance(input.startIndex,9))
                generateWithRootPath(rootPath)
            } else if input2 == "exit" {
                exit(0)
            } else {
                println("Unknown command. Type \"help\" to get a list of available commands.")
            }
        } else {
            println("Error : Null input")
        }
    }

}

func generateWithRootPath(rootPath : String) {
    if NSFileManager.defaultManager().fileExistsAtPath(rootPath) {
        if NSFileManager.defaultManager().fileExistsAtPath(rootPath.stringByAppendingPathComponent("config")) {
            let configuration = ConfigLoader.loadConfigFileAtPath(rootPath.stringByAppendingPathComponent("config"))
            let loader = Loader(folderPath: configuration.articlesPath, defaultAuthor: configuration.defaultAuthor, dateStyle:configuration.dateStyle)
            loader.sortArticles()
            let renderer = Renderer(articles: loader.articles, exportPath: configuration.outputPath, rootPath: rootPath, defaultWidth:configuration.imageWidth, blogTitle: configuration.blogTitle)
            renderer.fullExport()
            println("Export done !")
        } else {
            println("No config file found in the designated directory.")
        }
    } else {
         println("The folder at path \(rootPath) doesn't exist.")
    }
}

main()



