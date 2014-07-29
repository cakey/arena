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

gulp.task "scripts", ->
  gulp.src(["src/**/*.coffee"])
    .pipe(concat("app.js"))
    .pipe(coffee(bare: true).on("error", gutil.log))
    .pipe gulp.dest("./public")
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

gulp.task "default", ["scripts", "styles", "jade", "assets"], ->

  http.createServer(ecstatic(root: __dirname + "/public")).listen 8090
  console.log "Listening on :8090"

  gulp.watch "src/**/*.coffee", ["scripts"]
  gulp.watch "src/**/*.scss", ["styles"]
  gulp.watch "src/**/*.jade", ["jade"]
  gulp.watch "src/assets/**/*", ["assets"]
