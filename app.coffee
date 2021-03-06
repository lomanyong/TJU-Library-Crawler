# 图书馆书目信息爬虫
async = require('async')
crawler = require('./crawler')

async.waterfall([
  (callback) ->
    console.log 'fetch first url begin...'
    url = crawler.getFirstUrl((url) ->
      if (url == '')
        callback('error! First URL not correct.')
      else
        callback(null, url)
    )

  (url, callback) ->
    console.log 'fetch second url begin...'
    url = crawler.getSecondUrl(url, (url) ->
      if (url == '')
        callback('error! Second URL not correct.')
      else
        callback(null, url)
    )

  (url, callback) ->
    console.log 'fecth type urls begin...'
    url = crawler.getTypeUrls(url, (url) ->
      if (url == '')
        callback('error! Type URLs not correct.')
      else
        callback(null, url)
    )

  (url, callback) ->
    console.log 'fetch first page list begin...'
    result = crawler.analyzeList(url, (result) ->
      if (result == '')
        callback('error! Analyze list error!')
      else
        callback(null, result)
    )

  (res, callback) ->
    console.log 'fetch first page detail begin...'
    crawler.fetchData(res, (res) ->
      callback(null, res)
    )

  (result, callback) ->
    console.log 'fetch next page begin...'
    if (result.is_last_page)
      callback(null)
    else
      crawler.fetchNextPage(result, () ->
        callback(null)
      )

], (err) ->
  if (!err)
    console.log "All Completed."
  else
    console.log err
)