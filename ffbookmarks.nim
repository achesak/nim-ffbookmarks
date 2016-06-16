# Nim module for working with Firefox bookmarks files.

# Written by Adam Chesak.
# Released under the MIT open source license.


## nim-ffbookmarks is a Nim module for working with Firefox bookmarks files. It can read and parse bookmarks files,
## in addition to converting to CSV and HTML. It can also filter duplicate bookmarks.
## 
## Examples:
##
## .. code-block:: nim
##    
##    # Load the bookmarks, convert them to CSV, and print the first ten rows.
##    var allBookmarks : FFBookmark = parseBookmarksFromFile("bookmarks.json")
##    var bookmarks : seq[FFBookmark] = allBookmarks.children[2].children  # children[2] is "Unsorted Bookmarks", by default
##    var csvData : string = formatCSV(bookmarks[0..9])
##    echo(csvData)
##   
##    # Convert the bookmarks to HTML and write them to a file.
##    writeHTML(bookmarks, "bookmarks.html")
##    
##    # Print the number of bookmarks, then remove any duplicates and print the
##    # number of unique bookmarks.
##    echo("Number of bookmarks: " & intToStr(len(bookmarks)))
##    var filtered : seq[FFBookmark] = removeDuplicates(bookmarks)
##    echo("Number of bookmarks (filtered): " & intToStr(len(filtered)))


import json
import times
import strutils
import csv


type
    FFBookmark* = tuple[id : int, guid : string, title : string, index : int, dateAdded : TTime, lastModified : TTime,
                         ffType : string, root : string, annos : FFAnnos, children : seq[FFBookmark], uri : string,
                         charset : string, iconuri : string]
    
    FFAnnos* = tuple[name : string, flags : int, expires : int, value : string]


proc parseBookmarks*(data : string): FFBookmark = 
    ## Parses the bookmarks from the specified string.
    
    var b : JsonNode = parseJson(data)
    var ff : FFBookmark
    ff.id = int(b["id"].num)
    ff.guid = b["guid"].str
    ff.title = b["title"].str
    ff.index = int(b["index"].num)
    ff.dateAdded = fromSeconds(int(b["dateAdded"].num))
    ff.lastModified = fromSeconds(int(b["lastModified"].num))
    ff.ffType = b["type"].str
    ff.root = b["root"].str
    
    var ffc : JsonNode = b["children"]
    var ffcs : seq[FFBookmark] = newSeq[FFBookmark](len(ffc))
    for i in 0..len(ffc)-1:
        
        var ffn : FFBookmark
        ffn.id = int(ffc[i]["id"].num)
        ffn.guid = ffc[i]["guid"].str
        ffn.title = ffc[i]["title"].str
        ffn.index = int(ffc[i]["index"].num)
        ffn.dateAdded = fromSeconds(int(ffc[i]["dateAdded"].num))
        ffn.lastModified = fromSeconds(int(ffc[i]["lastModified"].num))
        ffn.ffType = ffc[i]["type"].str
        ffn.root = ffc[i]["root"].str
        if ffc[i].hasKey("annos"):
            var ffa : FFAnnos
            ffa.name = ffc[i]["annos"][0]["name"].str
            ffa.flags = int(ffc[i]["annos"][0]["flags"].num)
            ffa.expires = int(ffc[i]["annos"][0]["expires"].num)
            ffa.value = ffc[i]["annos"][0]["value"].str
            ffn.annos = ffa
        
        if ffc[i].hasKey("children"):
            var ffnc : JsonNode = ffc[i]["children"]
            var ffncs : seq[FFBookmark] = newSeq[FFBookmark](len(ffnc))
            
            for j in 0..len(ffnc)-1:
                var ffncc : FFBookmark
                ffncc.id = int(ffnc[j]["id"].num)
                ffncc.guid = ffnc[j]["guid"].str
                ffncc.title = ffnc[j]["title"].str
                ffncc.index = int(ffnc[j]["index"].num)
                ffncc.dateAdded = fromSeconds(int(ffnc[j]["dateAdded"].num))
                ffncc.lastModified = fromSeconds(int(ffnc[j]["lastModified"].num))
                ffncc.ffType = ffnc[j]["type"].str
                ffncc.uri = ffnc[j]["uri"].str
                if ffnc[j].hasKey("charset"):
                    ffncc.charset = ffnc[j]["charset"].str
                else:
                    ffncc.charset = ""
                if ffnc[j].hasKey("iconuri"):
                    ffncc.iconuri = ffnc[j]["iconuri"].str
                else:
                    ffncc.iconuri = ""
                if ffnc[j].hasKey("annos"):
                    var ffncca : FFAnnos  # These are some of the least descriptive variable names I've ever come up with.
                    ffncca.name = ffnc[j]["annos"][0]["name"].str
                    ffncca.flags = int(ffnc[j]["annos"][0]["flags"].num)
                    ffncca.expires = int(ffnc[j]["annos"][0]["expires"].num)
                    ffncca.value = ffnc[j]["annos"][0]["value"].str
                    ffncc.annos = ffncca
                ffncs[j] = ffncc
            
            ffn.children = ffncs
        
        ffcs[i] = ffn
    
    ff.children = ffcs
    
    return ff
                


proc parseBookmarksFromFile*(filename : string): FFBookmark = 
    ## Parses the bookmarks from the specified file.
    
    return parseBookmarks(readFile(filename))


#proc writeBookmarks*(bookmarks : FFBookmark) {.noreturn.} = 
#    ## Writes the bookmarks to a file, formatted as JSON. ``bookmarks`` is the outermost
#    ## bookmarks element.


proc formatCSV*(bookmarks : seq[FFBookmark]): string = 
    ## Formats the bookmarks as CSV. ``bookmarks`` is a sequence of individual bookmark items.
    
    var c : seq[seq[string]] = newSeq[seq[string]](len(bookmarks))
    
    for i in 0..high(bookmarks):
        var s : seq[string] = newSeq[string](10)
        var b : FFBookmark = bookmarks[i]
        s[0] = intToStr(b.id)
        s[1] = b.guid
        s[2] = b.title
        s[3] = intToStr(b.index)
        s[4] = $b.dateAdded
        s[5] = $b.lastModified
        s[6] = b.charset
        s[7] = b.ffType
        s[8] = b.uri
        s[9] = b.iconuri
        c[i] = s
    
    return stringifyAll(c)


proc writeCSV*(bookmarks : seq[FFBookmark], filename : string) {.noreturn.} = 
    ## Formats the bookmarks as CSV then writes the CSV to the specified file.
    ## ``bookmarks`` is a sequence of individual bookmark items.
    
    writeFile(filename, formatCSV(bookmarks))


proc formatHTML*(bookmarks : seq[FFBookmark]): string = 
    ## Formats the bookmarks as HTML. ``bookmarks`` is a sequence of individual bookmark items.
    
    var h : string = "<table>\n<tr>"
    h &= "<th>ID</th><th>GUID</th><th>Title</th><th>Index</th><th>Date Added</th><th>Last Modified</th>"
    h &= "<th>Charset</th><th>Type</th><th>URI</th><th>Icon URI</th></tr>\n"
    
    for i in bookmarks:
        var g : string = "<tr><td>" & intToStr(i.id) & "</td>"
        g &= "<td>" & i.guid & "</td>"
        g &= "<td>" & i.title & "</td>"
        g &= "<td>" & intToStr(i.index) & "</td>"
        g &= "<td>" & $i.dateAdded & "</td>"
        g &= "<td>" & $i.lastModified & "</td>"
        g &= "<td>" & i.charset & "</td>"
        g &= "<td>" & i.ffType & "</td>"
        g &= "<td>" & i.uri & "</td>"
        g &= "<td>" & i.iconuri & "</td>"
        g &= "</tr>\n"
        h &= g
    
    var header : string = "<!DOCTYPE html>\n<html>\n<head>\n<title>nimrod-ff-bookmarks</title>\n</head>\n<body>\n"
    var body : string = "</body>\n</html>"
    
    return header & h & "</table>\n" & body
    


proc writeHTML*(bookmarks : seq[FFBookmark], filename : string) {.noreturn.} = 
    ## Formats the bookmarks as HTML then writes the HTML to the specified file. ``bookmarks``
    ## is a sequence of individual bookmark items.
    
    writeFile(filename, formatHTML(bookmarks))


proc removeDuplicates*(bookmarks : seq[FFBookmark]): seq[FFBookmark] = 
    ## Finds duplicates from the sequence of bookmarks and returns a new sequence with the
    ## duplicates removed. ``bookmarks`` is a sequence of individual bookmark items.
    
    var uniques : seq[FFBookmark] = @[]
    
    var matched : bool = false
    for i in bookmarks:
        for j in uniques:
            if i.uri == j.uri:
                matched = true
                break
        if matched:
            matched = false
            continue
        else:
            matched = false
            uniques.setLen(len(uniques) + 1)
            uniques[high(uniques)] = i
    
    return uniques


when isMainModule:
    
    # Load the bookmarks, convert them to CSV, and print the first ten rows.
    var allBookmarks : FFBookmark = parseBookmarksFromFile("bookmarks.json")
    var bookmarks : seq[FFBookmark] = allBookmarks.children[2].children  # children[2] is "Unsorted Bookmarks", by default
    var csvData : string = formatCSV(bookmarks[0..9])
    echo(csvData)
    
    # Convert the bookmarks to HTML and write them to a file.
    writeHTML(bookmarks, "bookmarks.html")
    
    # Print the number of bookmarks, then remove any duplicates and print the
    # number of unique bookmarks.
    echo("Number of bookmarks: " & intToStr(len(bookmarks)))
    var filtered : seq[FFBookmark] = removeDuplicates(bookmarks)
    echo("Number of bookmarks (filtered): " & intToStr(len(filtered)))