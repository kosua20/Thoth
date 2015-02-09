#{#THOT}, a simple static blog generator.

## Meet Thoth
{#Thoth} (or more commonly Thoth) is a new, simple static blog generator. Just write your articles in Markdown, put them in a directory, point Thoth to this directory, a template and an output directory, and *voilà* !  

**Warning : Thoth is currently a work in progress. Please use it carefully, and at your own risks.**  

You can use it as a command-line tool
```
$ thoth
Welcome in {#THOTH}, a static blog generator.
> generate /path/to/your/blog/folder
Export done !
> help
```
or make it generate your whole site in a one-line command
```
$ thoth /path/to/your/blog/folder
```
## Functionnalities
### Templates
Create your own templates : Thoth uses a keywords system for inserting your articles content in the template you created or downloaded. Those keywords are simple and easy-to-use. You can for instance use :
- ```{#TITLE}``` to insert an article title
- ```{#AUTHOR}``` to insert the author name
- ```{#SUMMARY}``` to insert a shortened version of an article
- ...

### Extended markdown parsing
You can create inline footnotes using the common format :
```
[^ here's the content of my footnote]
```
You can also easily manage your images size in markdown, either by setting a default width, or defining it using the following syntax : 
```
![alttext](path/to/image.png "800,600,title")
``` 
or just 
```
![alttext](path/to/image.png "800,title")
``` 
to automatically set the height according to the picture ratio.
Pictures from your articles which are stored on your computer are also retrieved by Thoth and copied in article-specific folders, for an easier management.

### Config file
A simple, human-readable config file. No XML, JSON or YAML. just a simple flat text file, nothing more.

### Authors and Contributors
Created in Swift using Xcode by Simon Rodriguez.
Markdown parsing courtesy of (author, repo, license)
Command-line extended support brought by lib...

### Support or Contact
Having trouble with Thoth? Contact contact@simonrodriguez.fr and we'll try to help you.
