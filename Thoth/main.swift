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
        let rootPath = Process.arguments[1]
        if let config = loadConfigurationFromPath(rootPath) {
            let man = Manager(rootPath: rootPath, configuration: config)
            man.generate()
        }
        exit(0)
    }
    
    mainloop()
    /*if let data =  NSFileManager.defaultManager().contentsAtPath("/Developer/XCode/Siblog/Test/articles/Aquarii1.md"){
        var content = NSString(data: data, encoding: NSUTF8StringEncoding)
        var mrk = Markdown(options: nil)
        content = mrk.transform(content!)
        println("\(mrk.imagesUrl)")
    }*/
    
}

func mainloop() {
    println("Welcome in {#Thoth}, a static blog generator.")
    let prompt: Prompt = Prompt(argv0: C_ARGV[0])
    
    while true {
        if let input1 = prompt.gets() {
            var input = input1.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            if input == "help" {
                println("Here's your help")
            } else if input.hasPrefix("generate ") {
                input = input.substringFromIndex(advance(input.startIndex,9))
                input.componentsSeparatedByString(" ")
                let rootPath = input.substringFromIndex(advance(input.startIndex,9))
                if let config = loadConfigurationFromPath(rootPath) {
                    let man = Manager(rootPath: rootPath, configuration: config)
                    man.generate()
                }
            } else if input == "exit" {
                exit(0)
            } else {
                println("Unknown command. Type \"help\" to get a list of available commands.")
            }
        } else {
            println("Error : Null input")
        }
    }
}

func loadConfigurationFromPath(rootPath : String)-> Config? {
    if NSFileManager.defaultManager().fileExistsAtPath(rootPath) {
        if NSFileManager.defaultManager().fileExistsAtPath(rootPath.stringByAppendingPathComponent("config")) {
            return ConfigLoader.loadConfigFileAtPath(rootPath.stringByAppendingPathComponent("config"))
        } else {
            println("No config file found in the designated directory.")
        }
    } else {
        println("The folder at path \(rootPath) doesn't exist.")
    }
    return nil
}

main()



