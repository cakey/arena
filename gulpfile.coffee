coffee = require "gulp-coffee"
concat = require "gulp-concat"
gulp = require "gulp"
gutil = require "gulp-util"
sass = require "gulp-sass"
serve = require "gulp-serve"
http = require "http"
ecstatic = require "ecstatic"
jade = require "gulp-jade"
clean = require "gulp-clean"
coffeelint = require "gulp-coffeelint"
karma = require("karma").server
browserify = require 'gulp-browserify'
rename = require 'gulp-rename'

gulp.task 'scripts', ->
    gulp.src('src/coffee/app.coffee', { read: false })
        .pipe(browserify({
          transform: ['coffeeify'],
          extensions: ['.coffee']
        })).on("error", gutil.log)
        .pipe(rename('app.js'))
        .pipe(gulp.dest('./public'))
    return

gulp.task 'tests', ->
    gulp.src('src/tests/test.coffee', { read: false })
        .pipe(browserify({
          transform: ['coffeeify'],
          extensions: ['.coffee']
        }))
        .pipe(rename('tests.js'))
        .pipe(gulp.dest('./gen'))
    return

gulp.task "styles", ->
    gulp.src(["./src/**/*.scss"])
        .pipe(concat("app.css"))
        .pipe(sass(errLogToConsole: true))
        .pipe gulp.dest("./public")
    return

gulp.task "jade", ->
    gulp.src("./src/jade/index.jade")
        .pipe(jade().on("error", gutil.log))
        .pipe gulp.dest("./public")
    return

gulp.task "clean", ->
    gulp.src("./public",
        read: false
    ).pipe clean()

gulp.task "assets", ->
    gulp.src("./src/assets/**/*")
        .pipe gulp.dest("./public")

gulp.task "lint", ->
    gulp.src(["src/**/*.coffee"])
        .pipe(coffeelint())
        .pipe(coffeelint.reporter())
    return

karmaCommonConf =
    browsers: ['Chrome']
    frameworks: ['mocha']
    files: [
        'gen/tests.js',
    ]

gulp.task "tdd", (done) ->
    karma.start karmaCommonConf, done

gulp.task "default", ["lint", "scripts", "tests", "styles", "jade", "assets"], ->

    http.createServer(ecstatic(root: __dirname + "/public")).listen 8090
    console.log "Listening on :8090"

    gulp.watch "src/**/*.coffee", ["lint", "scripts", "tests"]
    gulp.watch "src/**/*.scss", ["styles"]
    gulp.watch "src/**/*.jade", ["jade"]
    gulp.watch "src/assets/**/*", ["assets"]
