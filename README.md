About
=====

nim-ffbookmarks is a Nim module for working with Firefox bookmarks files. It can read and parse bookmarks files,
in addition to converting to CSV and HTML. It can also filter duplicate bookmarks.

Examples:

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

License
=======

nim-ffbookmarks is released under the MIT open source license.
