//
//  main.swift
//  Siblog
//
//  Created by Simon Rodriguez on 25/01/2015.
//  Copyright (c) 2015 Simon Rodriguez. All rights reserved.
//

import Foundation


func main(args : [String] = []){
    //println(Process.arguments)
    var args = Process.arguments
    if args.count > 1 {
        args.removeAtIndex(0)
        mainSwitch(args)
        exit(0)
    } else {
        mainloop()
    }
}

func mainloop() {
    println("Welcome in {#Thoth}, a static blog generator.")
    let prompt: Prompt = Prompt(argv0: C_ARGV[0])
    while true {
        if let input1 = prompt.gets() {
            var input2 = input1.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            input2 = input2.stringByReplacingOccurrencesOfString("\\ ", withString: "{#PLAC3HO£D€R$}", options: nil, range: nil)
            var args = input2.componentsSeparatedByString(" ")
            /*
            arg[0] : command
            arg[1] : path
            arg[2],... : options
            */
            args = args.filter({
                (x : String) -> Bool in
                !x.isEmpty
            })
            args = args.map({
                (x : String) -> String in
                x.stringByReplacingOccurrencesOfString("{#PLAC3HO£D€R$}", withString: "\\ ", options: nil, range: nil)
            })
            
            mainSwitch(args)
        } else {
            println("Error : Null input")
        }
    }
}

func mainSwitch(var args : [String]) {
    if args.count > 1 {
        switch args[0] {
        case "setup":
            if !NSFileManager.defaultManager().fileExistsAtPath(args[1]) {
                NSFileManager.defaultManager().createDirectoryAtPath(args[1], withIntermediateDirectories: true, attributes: nil, error: nil)
            }
            ConfigLoader.generateConfigFileAtPath(args[1])
            let folders = ["articles","template","output","resources"] as [String]
            for folder in folders {
                if !NSFileManager.defaultManager().fileExistsAtPath(args[1].stringByAppendingPathComponent(folder)){
                    NSFileManager.defaultManager().createDirectoryAtPath(args[1].stringByAppendingPathComponent(folder), withIntermediateDirectories: true, attributes: nil, error: nil)
                }
            }
        case "check":
            if let config = loadConfigurationFromPath(args[1]) {
                println("The config file seems ok")
            }
        case "index","resources","first","upload","scribe","generate":
            if let config = loadConfigurationFromPath(args[1]) {
                let man = Manager(rootPath: args[1], configuration: config)
                switch args[0] {
                case "index":
                    man.index()
                case "resources":
                    man.resources()
                case "first":
                    man.generate(3)
                    man.upload(option: 3)
                case "generate":
                    args.removeRange(Range(start: 0, end: 2))
                    if let option = interprateArguments(args) {
                        man.generate(option)
                    }
                case "upload":
                    args.removeRange(Range(start: 0,end: 2))
                    if let option = interprateArguments(args) {
                        man.upload(option: option)
                    }
                case "scribe":
                    args.removeRange(Range(start: 0, end: 2))
                    if let option = interprateArguments(args) {
                        man.generate(option)
                        man.upload(option: option)
                    }
                default:
                    break
                }
            }
            
        default:
            if NSFileManager.defaultManager().fileExistsAtPath(args[0]) {
                let potentialPath = args[0]
                if let config = loadConfigurationFromPath(potentialPath) {
                    args.removeAtIndex(0)
                    if let option = interprateArguments(args){
                        let man = Manager(rootPath: potentialPath, configuration: config)
                        man.generate(option)
                        man.upload(option: option)
                    }
                }
            } else {
                println("Unknown command. Type \"help\" to get a list of available commands.")
            }
            break
        }
    } else if args.count == 1 {
        //Commands with no arguments except the first
        switch args[0] {
        case "help":
            printhelp()
        case "exit":
            exit(0)
        case "ibis":
            printbonus()
        case "version","-version","-v","--version","--v":
            printversion()
        case "setup","chech","index","resources","first","upload","scribe","generate":
            println("Missing argument. Type \"help\" to get a list of available commands.")
        default:
            if NSFileManager.defaultManager().fileExistsAtPath(args[0]) {
                let potentialPath = args[0]
                if let config = loadConfigurationFromPath(potentialPath) {
                    args.removeAtIndex(0)
                    if let option = interprateArguments(args){
                        let man = Manager(rootPath: potentialPath, configuration: config)
                        man.generate(option)
                        man.upload(option: option)
                    }
                }
            } else {
                println("Unknown command. Type \"help\" to get a list of available commands.")
            }
        }
    } else {
        println("Empty command. Type \"help\" to get a list of available commands.")
    }
}

func interprateArguments(args : [String]) -> Int? {
    //No arguments provided -> default : 0
    if args.count == 0 { return 0 }
    var option = 0
    for i in 0..<args.count {
        switch args[i]{
        case "-a","--a","--articles":
            option = 1
        case "-d","--d","--drafts":
            option = 2
        case "-f","--f","--full":
            option = 3
        default:
            println("Unknown argument: \(args[i])")
            return nil
        }
    }
    return option
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


func printhelp(){
    let s = "setup <path>\tCreates the configuration files and folders (articles, template, output, ressources) in the indicated directory.\n"
        + "\t\tArgument:\n"
        + "\t\t<path> points to the directory where the configurations files and folders  should be created.\n\n"
        + "first <path>\tRuns the first generation/upload of the site\n\t\t"
        + "Argument:\n"
        + "\t\t<path> points to the directory containing the config file of the site to generate\n\n"
        + "generate <path> [-a|-d|-f]  Generates the site in the specified ouput folder. All existing files are kept.\n"
        + "\t\tDrafts are updated. New articles are added. Index is rebuilt.\n"
        + "\t\tArgument:\n"
        + "\t\t<path> points to the directory containing the config file of the site to generate\n"
        + "\t\tOptions:\n"
        + "\t\t-a rebuilds articles only\n"
        + "\t\t-d rebuilds drafts only\n"
        + "\t\t-f forces to rebuild everything\n\n"
        + "upload <path> [-a|-d|-f]  Upload the content of the site to the FTP set in the config file\n"
        + "\t\tArgument:\n"
        + "\t\t<path> points to the directory containing the config file of the site to generate\n"
        + "\t\tOptions:\n"
        + "\t\t-a uploads articles only\n"
        + "\t\t-d uploads drafts only\n"
        + "\t\t-f uploads everything (Warning: the content of the ftp directory where the site content is put will be deleted)\n\n"
        + "scribe <path> [-a|-d|-f]  Combines \"generate\" and \"upload\" with the corresponding path and option\n"
        + "\t\tArgument:\n"
        + "\t\t<path> points to the directory containing the config file of the site to generate and upload\n\n"
        + "index <path>\tRegenerates the index.html file.\n"
        + "\t\tArgument:\n"
        + "\t\t<path> points to the directory containing the config file\n\n"
        + "resources <path>  Rebuilds the resources directory.\n"
        + "\t\tArgument:\n"
        + "\t\t<path> points to the directory containing the config file\n\n"
        + "check <path>\tChecks the configuration file.\n"
        + "\t\tArgument:\n"
        + "\t\t<path> points to the directory containing the config file\n\n"
        + "help\t\tDisplays this help text\n\n"
        + "exit\t\tQuits the program"
    println(s)
}


func printversion(){
    println("{#Thoth} version 0.22")
}

func printbonus(){
    println("                                                         \n                                                         \n                        ,,,,,,,,,,                       \n                  ,yQQQQQQQQQQQQQQQQQQyQ                 \n               yQQQQRR^ ..       .``RWQQQQQ,             \n            ,QQQ#R    ,yyy,             \"WQQQQ           \n          ,QQQR^  ,,@R` , 7Q               \"@QQQ         \n         QQQR,y#RR`,,      @Q                `QQQQ       \n       ,QQQR@QyQRR^`7RQQ   ]Q                  YQQQ      \n     ,#RQgRRT.        ]#  ,Qh                   1QQQ     \n   ,#QQQQ~           ,#. y#^                     @QQQ    \n  ]Q#@QQL           y#  #R                        QQQ    \n   . QQQ           @R yR`                         @QQm   \n     QQQ         ,QL @R                           ]QQQ   \n     QQQ        ,Q` @L                            @QQM   \n     ]QQQ       Q. ]Q           ,,yyyyyy,,        QQQ    \n      QQQ       Q   QQ    ,yQQQRRRRRRRW@QQQRRQ,  {QQR    \n      4QQQ       @Q  ^RRR`@R^.           '7R@yQRQQQ#     \n       1QQQ       ?Q,     @y,                .`@QQ#      \n        \"QQQy       ?WRRQy,.`RWRQQyy,,,      ,QQQR       \n          KQQQy           `RQQ     ..^QQRRRQQQQE         \n            KQQQQQ           `RQy,,,,  KQgQQQRV          \n              `RQQQQQQ,           `]Q@QQQQRT             \n                  \"WQQQQQQQQQQQQQQQQQQRR^                \n                        `\"RRRRRRRR^.                     \n                                                         \n                                                         \n                                                         \n")
}


main()



