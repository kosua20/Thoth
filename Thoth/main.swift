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
        if let (option, rootPath) = generateWithArguments(Process.arguments){
            if let config = loadConfigurationFromPath(rootPath) {
                let man = Manager(rootPath: rootPath, configuration: config)
                man.generate(option)
            }
        }
        exit(0)
    }
    mainloop()
}

func mainloop() {
    println("Welcome in {#Thoth}, a static blog generator.")
    let prompt: Prompt = Prompt(argv0: C_ARGV[0])
    
    while true {
        if let input1 = prompt.gets() {
            var input = input1.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            
            //-----------------help----------------------//
            if input == "help" {
                println("Here's your help")
                
            //--------------generation-------------------//
            } else if input.hasPrefix("generate ") {
                input = input.stringByReplacingOccurrencesOfString("\\ ", withString: "{#PLAC3HO£D€R$}", options: nil, range: nil)
                let args = input.componentsSeparatedByString(" ")
                if let (option, rootPath1) = generateWithArguments(args){
                    var rootPath = rootPath1.stringByReplacingOccurrencesOfString("{#PLAC3HO£D€R$}", withString: "\\ ", options: nil, range: nil)
                    if let config = loadConfigurationFromPath(rootPath) {
                        let man = Manager(rootPath: rootPath, configuration: config)
                        man.generate(option)
                    }
                }
                
            //----------------index----------------------//
            } else if input.hasPrefix("index "){
                input = input.substringFromIndex(advance(input.startIndex,6))
                if let config = loadConfigurationFromPath(input) {
                    let man = Manager(rootPath: input, configuration: config)
                    man.index()
                }
                
            //--------------ressources-------------------//
            } else if input.hasPrefix("ressources "){
                input = input.substringFromIndex(advance(input.startIndex,11))
                if let config = loadConfigurationFromPath(input) {
                    let man = Manager(rootPath: input, configuration: config)
                    man.ressources()
                }
                
            //-----------------exit----------------------//
            } else if input == "exit" {
                exit(0)
                
            //-------------Unknown command---------------//
            } else {
                println("Unknown command. Type \"help\" to get a list of available commands.")
            }
        } else {
            println("Error : Null input")
        }
    }
}

func generateWithArguments(args : [String]) -> (Int, String)?{
    var option = 0
    for i in 1..<args.count-1 {
        if args[i].hasPrefix("-") && args[i].utf16Count == 2{
            //Keeping this structure for future combined arguments
            switch args[i] {
            case "-a":
                option = 1
            case "-d":
                option = 2
            case "-f":
                option = 3
            default:
                println("Unknown argument")
                return nil
            }
        } else {
            println("Unknown argument")
            return nil
        }
    }
    if let rootPath = args.last {
        return (option, rootPath)
    } else {
        println("No path provided")
        return nil
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



