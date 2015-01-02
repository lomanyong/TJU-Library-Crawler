async = require('async')
request = require('request')
cheerio = require('cheerio')
formatter = require('dateformat')
db = require('./storage')

BASEURL = "http://ilink.lib.tju.edu.cn"

###
  访问图书馆首页，获取基本的书目参考咨询的URL
###
module.exports.getFirstUrl = (callback) ->
  request(
    "http://ilink.lib.tju.edu.cn/uhtbin/cgisirsi/0/0/0/49",
    (err, res, body) ->
      if (err)
        return ''
      $ = cheerio.load body
      url = $("li.menu_link > a")[2].attribs.href # 书目参考咨询
      #console.log "书目参考咨询:" + url + " loading..."
      callback(url)
  )

###
  获取图书分类导引的URL
###
module.exports.getSecondUrl = (url, callback) ->
  request(
    BASEURL + url,
    (err, res, body) ->
      if (err)
        return ''
      $ = cheerio.load body
      url = $("ul.gatelist_table > li > a")[2].attribs.href # 图书分类导引
      #console.log "图书分类导引:" + url + " loading..."
      callback(url)
  )

###
  获取各个分类的链接，并对标志做存储，在之后抓取时做去重判定
###
module.exports.getTypeUrls = (url, callback) ->
  request(
    BASEURL + url,
    (err, res, body) ->
      if (err)
        return ''
      $ = cheerio.load body
      url = $("ul.gatelist_table > li > a")[0].attribs.href # 分类 暂时为军事
      #console.log "军事类:" + url + " loading..."
#      urls = []
#      $("ul.gatelist_table > li > a").each ->
#        urls.push $(@)[0].attribs.href.trim()
#      console.log urls

      callback(url)
  )

###
  分析列表界面
###
module.exports.analyzeList = (url, callback) ->
  request(
    BASEURL + url,
    (err, res, body) ->
      if (err)
        return ''
      analyzePageBody(body, (result) ->
        console.log result
        callback(result)
      )
  )

###
  并发抓取详情界面
###
module.exports.fetchData = (res, callback) ->
  parallelFechBookDetail(res, () ->
    callback(res)
  )

module.exports.fetchNextPage = (res, callback) ->
  async.eachSeries(
    [2..res.allpage]
    (param, cb) ->
      request(
        url : BASEURL + res.url
        method : 'POST'
        headers : {
          'User-Agent' : 'Mozilla/5.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/30.0.1599.101 Safari/537.36'
          'Host' : 'ilink.lib.tju.edu.cn'
          'Origin' : 'http://ilink.lib.tju.edu.cn'
          'Referer' : BASEURL + res.url
        }
        form : {
          first_hit : res.first_hit
          last_hit : res.last_hit
          form_type : 'JUMP^' + (20 * (param - 1) + 1)
        }
        (err, res, body) ->
          console.log 'loading...: JUMP^' + param
          analyzePageBody(body, (result) ->
            parallelFechBookDetail(result, () ->
              cb(null)
            )
          )
      )
    (err) ->
      if (!err)
        callback()
  )

parallelFechBookDetail = (res, callback) ->
  books = []
  async.each(
    [res.first_hit..res.last_hit]
    (param, cb) ->
      book = fetchDetail(res.url, param, res.first_hit, res.last_hit, (book) ->
        console.log "VIEW^" + param
        #console.log book
        books.push book
        cb(null)
      )
    (err) ->
      if (!err)
        db.storeBooks(books, (err) ->
          if (!err)
            callback()
        )
  )

analyzePageBody = (body, callback) ->
  $ = cheerio.load body
  url = $("form.hit_list_form")[0].attribs.action
  length = $(body).find('ul.hit_list_row').length
  first_hit = $("input[name = 'first_hit']").val()
  last_hit = $("input[name = 'last_hit']").val()
  page = $("div.searchsummary_pagination > strong").html().trim()
  allnum = $("div.searchsummary > em").html().trim()
  allpage = parseInt(allnum / 20) + 1
  console.log "详情:" + url + " loading..."

  result =
    url : url
    page : page
    first_hit : first_hit
    last_hit : last_hit
    len : length
    is_last_page : page * 20 > allnum
    nextpage : 'JUMP^' + (page * 20 + 1)
    allpage : allpage

  callback(result)

fetchDetail = (url, param, start, end, callback) ->
  formdata =
    first_hit : start
    last_hit : end
    form_type : ''
  formdata['VIEW^'+param] = '详细资料'

  request(
    {
      url : BASEURL + url
      method : 'POST'
      headers : {
        'User-Agent' : 'Mozilla/5.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/30.0.1599.101 Safari/537.36'
        'Host' : 'ilink.lib.tju.edu.cn'
        'Origin' : 'http://ilink.lib.tju.edu.cn'
        'Referer' : BASEURL + url
      }
      form : formdata
    }
    (err, res, body) ->
      $ = cheerio.load body

      index = []
      content = []
      $("dt.viewmarctags").each ->
        index.push $(@).text().trim()
      $("dd.viewmarctags").each ->
        content.push $(@).text().trim()

      detail = []
      for i in [0..(index.length - 1)]
        tmp = index[i] + content[i]
        detail.push tmp

      info = {}
      info.locid = []
      info.items = []

      $("table[cellpadding='0'] > tr").each ->
        tds = $(@).find('td')
        if tds.length == 1
          info.location = $(tds[0]).text().trim()
        else if tds.length == 4
          if $(tds[1]).text().trim() != "复本号"
            if $(tds[0]).text().trim() != ""
              info.locid.push($(tds[0]).text().trim())
            info.items.push(
              {
                copynum : $(tds[1]).text().trim()
                type : $(tds[2]).text().trim()
                location : $(tds[3]).text().trim()
              }
            )

      book =
        title : $("dd.title").text().trim()
        author : $("dd.author").text().trim()
        isbn : $("dd.isbn").text().trim()
        status : $("dd.copy_info").text().trim()
        library : info.location
        locid : info.locid
        items : info.items
        updated_at : formatter(new Date, "yyyy-mm-dd HH:MM:ss")
        info : detail

      callback(book)
  )