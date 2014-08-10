gulp = require "gulp"
gutil = require "gulp-util"
http = require "http"
ecstatic = require "ecstatic"
karma = require("karma").server
$ = require('gulp-load-plugins')()

gulp.task 'scripts', ->
    return gulp.src('src/coffee/app.coffee', { read: false })
        .pipe($.browserify({
          transform: ['coffeeify'],
          extensions: ['.coffee']
        })).on("error", gutil.log).on("error", gutil.beep)
        .pipe($.rename('app.js'))
        .pipe(gulp.dest('./public'))


gulp.task 'tests', ->
    return gulp.src('src/tests/test.coffee', { read: false })
        .pipe($.browserify({
          transform: ['coffeeify'],
          extensions: ['.coffee']
        })).on("error", gutil.log).on("error", gutil.beep)
        .pipe($.rename('tests.js'))
        .pipe(gulp.dest('./gen'))

gulp.task "styles", ->
    return gulp.src(["./src/**/*.scss"])
        .pipe($.concat("app.css"))
        .pipe($.sass(errLogToConsole: true).on("error", gutil.log).on("error", gutil.beep))
        .pipe gulp.dest("./public")

gulp.task "jade", ->
    gulp.src("./src/jade/index.jade")
        .pipe($.jade().on("error", gutil.log).on("error", gutil.beep))
        .pipe gulp.dest("./public")


gulp.task "clean", ->
    gulp.src("./public",
        read: false
    ).pipe $.clean()

gulp.task "assets", ->
    gulp.src("./src/assets/**/*")
        .pipe gulp.dest("./public")

gulp.task "lint", ->
    return gulp.src(["src/**/*.coffee"])
        .pipe($.coffeelint())
        .pipe($.coffeelint.reporter())
        .pipe($.coffeelint.reporter('fail'))
        .on("error", gutil.beep)

karmaCommonConf =
    browsers: ['Chrome']
    frameworks: ['mocha']
    files: [
        'gen/tests.js',
    ]
    reporters: ['mocha', 'beep'],

gulp.task "tdd", (done) ->
    karma.start karmaCommonConf, done

gulp.task "default", ["lint", "scripts", "tests", "styles", "jade", "assets"], ->

    http.createServer(ecstatic(root: __dirname + "/public")).listen 8090
    console.log "Listening on :8090"

    gulp.watch "src/**/*.coffee", ["lint", "scripts", "tests"]
    gulp.watch "src/**/*.scss", ["styles"]
    gulp.watch "src/**/*.jade", ["jade"]
    gulp.watch "src/assets/**/*", ["assets"]
