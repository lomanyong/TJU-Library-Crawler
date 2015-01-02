async = require('async')
mongoose = require('mongoose')

mongoose.connect('localhost', 'tju_library')

BookSchema = new mongoose.Schema({
  title : String
  author : String
  isbn : String
  status : String
  library : String
  updated_at : Date
  locid : [String]
  items : [{
    copynum : String
    type : String
    location : String
  }]
  info : [String]
})

BookModel = mongoose.model('Book', BookSchema)

module.exports.storeBooks = (books, callback) ->
  console.log 'storage begin...'
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
                cb err
              else
                cb null
            )
      )
    (err) ->
      if (!err)
        console.log 'storage end...'
        callback null
  )