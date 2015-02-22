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
        if let (option, rootPath) = interprateArguments(Process.arguments){
            if let config = loadConfigurationFromPath(rootPath) {
                let man = Manager(rootPath: rootPath, configuration: config)
                man.generate(option)
                man.upload(option: option)
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
                //printbonus()
                
            //--------------generation-------------------//
            } else if input.hasPrefix("scribe ") {
                input = input.stringByReplacingOccurrencesOfString("\\ ", withString: "{#PLAC3HO£D€R$}", options: nil, range: nil)
                let args = input.componentsSeparatedByString(" ")
                if let (option, rootPath1) = interprateArguments(args){
                    var rootPath = rootPath1.stringByReplacingOccurrencesOfString("{#PLAC3HO£D€R$}", withString: "\\ ", options: nil, range: nil)
                    if let config = loadConfigurationFromPath(rootPath) {
                        //println("Configuration : \(config.articlesPath), \(config.outputPath),\(config.templatePath)")
                        let man = Manager(rootPath: rootPath, configuration: config)
                        println("Manager managed")
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
                
            //--------------resources-------------------//
            } else if input.hasPrefix("resources "){
                input = input.substringFromIndex(advance(input.startIndex,10))
                if let config = loadConfigurationFromPath(input) {
                    let man = Manager(rootPath: input, configuration: config)
                    man.resources()
                }
            //--------------upload-------------------//
            } else if input.hasPrefix("upload "){
                input = input.stringByReplacingOccurrencesOfString("\\ ", withString: "{#PLAC3HO£D€R$}", options: nil, range: nil)
                let args = input.componentsSeparatedByString(" ")
                if let (option, rootPath1) = interprateArguments(args){
                    var rootPath = rootPath1.stringByReplacingOccurrencesOfString("{#PLAC3HO£D€R$}", withString: "\\ ", options: nil, range: nil)
                    if let config = loadConfigurationFromPath(rootPath) {
                        let man = Manager(rootPath: rootPath, configuration: config)
                        man.upload(option: option)
                    }
                }
            //-----------------exit----------------------//
            } else if input == "exit" {
                exit(0)
                
            //-------------Unknown command---------------//
            } else if input == "ibis" {
                printbonus()
            } else {
                println("Unknown command. Type \"help\" to get a list of available commands.")
            }
        } else {
            println("Error : Null input")
        }
    }
}

func interprateArguments(args : [String]) -> (Int, String)?{
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

func printbonus(){
    println("                                                         \n                                                         \n                        ,,,,,,,,,,                       \n                  ,yQQQQQQQQQQQQQQQQQQyQ                 \n               yQQQQRR^ ..       .``RWQQQQQ,             \n            ,QQQ#R    ,yyy,             \"WQQQQ           \n          ,QQQR^  ,,@R` , 7Q               \"@QQQ         \n         QQQR,y#RR`,,      @Q                `QQQQ       \n       ,QQQR@QyQRR^`7RQQ   ]Q                  YQQQ      \n     ,#RQgRRT.        ]#  ,Qh                   1QQQ     \n   ,#QQQQ~           ,#. y#^                     @QQQ    \n  ]Q#@QQL           y#  #R                        QQQ    \n   . QQQ           @R yR`                         @QQm   \n     QQQ         ,QL @R                           ]QQQ   \n     QQQ        ,Q` @L                            @QQM   \n     ]QQQ       Q. ]Q           ,,yyyyyy,,        QQQ    \n      QQQ       Q   QQ    ,yQQQRRRRRRRW@QQQRRQ,  {QQR    \n      4QQQ       @Q  ^RRR`@R^.           '7R@yQRQQQ#     \n       1QQQ       ?Q,     @y,                .`@QQ#      \n        \"QQQy       ?WRRQy,.`RWRQQyy,,,      ,QQQR       \n          KQQQy           `RQQ     ..^QQRRRQQQQE         \n            KQQQQQ           `RQy,,,,  KQgQQQRV          \n              `RQQQQQQ,           `]Q@QQQQRT             \n                  \"WQQQQQQQQQQQQQQQQQQRR^                \n                        `\"RRRRRRRR^.                     \n                                                         \n                                                         \n                                                         \n")
}

main()



