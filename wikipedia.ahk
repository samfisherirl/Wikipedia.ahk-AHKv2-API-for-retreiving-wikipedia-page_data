/* Example.ahk
;Source github.com/samfisherirl
#Include JXON.ahk
#Include Wikipedia.ahk
; set content header
wiki := Wikipedia("python coding") ;python coding is NOT an exact match to the page title 
page := wiki.query()
this return value stores only the primary match. 
    up to 5 results will be returned with object.pages
    matches are based on keywords and not title 1:1
        page := {
                @Prop categories : "",
                @Prop category_list: [],
                @Prop links: "",
                @Prop text: "",
                @Prop link_list: [],
                @Prop summary: ""
                @Prop title: page_title,
                @Prop url: page_url
        }

MsgBox(page.text) ; the first result's text contents
MsgBox(page.categories) ; this is a concaeted string but change to category_list and returns an array
MsgBox(page.links) ; this is a concaeted string but change to link_list and returns an array
enumerate_pages_returned(wiki.pages)


enumerate_pages_returned(wiki_pages){
    ;wiki.pages.ownprops()
        msg := Format("Match number{5} is {1}: `n{2}`n{3}`n`n{4}", page.title, page.links, page.categories, page.text, A_Index)
        MsgBox(msg)
    }
}
*/

Class Wikipedia
{
    /* Wikipedia
    * __New(keywords, headers:=?)
    * @param keywords used to search up to 5 wiki pages for the most matches
    * @param headers user agent
    * * @method Get winhttp simple request handler
    * * * @param URL
    * * @method query returns first page match, stores top matches in object
    */
    __New(
        keywords,
        headers := "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36"
    )
    {
        this.url := Format("https://en.wikipedia.org/w/api.php?action=query&format=json&list=search&srsearch={1}&srprop=size&srlimit=5", keywords)
        this.headers := headers
        this.page_text := ""
        this.matches := Map()
        this.page := ""
            /*
            @Prop categories : "",
            @Prop category_list: [],
            @Prop links: "",
            @Prop text: "",
            @Prop link_list: []
            }
            page_title = result["title"]
            page_url = f"https://en.wikipedia.org/wiki/{page_title.replace(' ', '_')}"
            page_response = requests.get(page_url)
            page_content = page_response.json()
            page_extract = page_content["query"]["pages"][0]["extract"]
            */
        this.pages := []
        try {
            this.response := this.Get(this.url)
        }
        catch {
            this.response := false
        }
    }
    Get(url)
    {
        https := ComObject("WinHttp.WinHttpRequest.5.1")
        https.Open("GET", url, false)
        https.SetRequestHeader("User-Agent", Trim(this.headers))
        https.Send()
        https.WaitforResponse()
        try {
            this.response := https.ResponseText
        }
        catch {
            this.response := false
        }
        return this.response
    }
    query()
    {
        if not (this.response) {
            response := this.Get(this.url)
        }
        else {
            response := this.response
        }
        if InStr(this.response, "query") && InStr(this.response, "search")
        {
            jdata := Jxon_Load(&response)
            results := jdata["query"]["search"]
            if results {
                this.page_text := false
                for result in results {
                    page_title := result["title"]
                    page_title := StrReplace(page_title, " ", "_")
                    page_url := "https://en.wikipedia.org/w/api.php?action=query&format=json&prop=extracts|categories|extlinks&explaintext=True&titles=" page_title "&format=json"
                    this.matches.Set(page_title, page_url)
                    response := this.Get(page_url)
                    jdata := Jxon_Load(&response)
                    for pageID, val in jdata['query']['pages'] {
                        page_data := jdata['query']['pages'][pageID]
                        page := {
                            categories: "",
                            category_list: [],
                            links: "",
                            text: "",
                            link_list: [],
                            summary: "",
                            title: page_title,
                            url: page_url
                        }
                        if page_data["categories"] {
                            categories := page_data["categories"]
                            for category in categories {
                                page.category_list.Push(category["title"])
                                page.categories .= category["title"] "`n"
                            }
                        }
                        if page_data["extlinks"] {
                            extlinks := page_data["extlinks"]
                            for extlink in extlinks {
                                page.link_list.Push(extlink["*"])
                                page.links .= extlink["*"] "`n"
                            }
                        }
                        if not (this.page_text) {
                            this.page_text := jdata['query']['pages'][pageID]['extract']
                            this.page := page
                        }
                        page.summary := this.retieve_summary(page_title)
                        if not page.summary {
                            if InStr(page.text, "`n`n") {
                                page.summary := StrSplit(page.text, "`n`n")[1]
                            }
                        }
                        page.text := this.page_text
                        this.pages.Push(page)
                    }
                }
            return this.page
            }
        }
    }
    retieve_summary(page_title){
        response := this.Get("https://en.wikipedia.org/api/rest_v1/page/summary/" page_title)
        if response {
            data := Jxon_Load(&response)
            if data["extract"] {
                return data["extract"]
            }
        }
    }
}


;response := https.request(StrReplace(url, " ", "%20"))
;response := http.request(url)
