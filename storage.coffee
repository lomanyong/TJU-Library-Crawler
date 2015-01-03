async = require('async')
mongoose = require('mongoose')

mongoose.connect('localhost', 'tju_library')

BookSchema = new mongoose.Schema({
  title : String
  author : String
  isbn : String
  status : String
  library : String
  updated_at : String
  locid : [String]
  items : [{
    copynum : String
    leixing : String
    location : String
  }]
  info : [String]
})

BookModel = mongoose.model('Book', BookSchema)

module.exports.storeBooks = (books, callback) ->
  console.log "storage begin...Books' length #{books.length}"
  async.each(
    books,
    (book, cb) ->
      BookModel.findOne({title : book.title}, (err, item) ->
        if (err)
          cb err
        else
          if (!item)
            BookModel.create(book, (err) ->
              if (err)
                console.log "create error! : " + book.title
                cb err
              else
                cb null
            )
          else
            BookModel.update({title : item.title}, book, (err) ->
              if (err)
                console.log "update error! : " + book
                cb err
              else
                cb null
            )
      )
    (err) ->
      if (!err)
        BookModel.count({title : new RegExp(/^.*$/)}, (err, count) ->
          if (!err)
            console.log "all books count #{count}"
          console.log 'storage end...'
          callback null
        )
  )