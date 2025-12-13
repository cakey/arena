const gulp = require('gulp');
const sass = require('gulp-sass')(require('sass'));
const pug = require('gulp-pug');
const concat = require('gulp-concat');
const rename = require('gulp-rename');
const livereload = require('gulp-livereload');
const browserify = require('browserify');
const source = require('vinyl-source-stream');
const express = require('express');
const log = require('fancy-log');

// Scripts task - compile CoffeeScript with React
function scripts() {
    return browserify({
        entries: ['src/client/app.coffee'],
        extensions: ['.coffee'],
        transform: ['coffee-reactify']
    })
    .bundle()
    .on('error', function(err) {
        log.error(err.message);
        this.emit('end');
    })
    .pipe(source('app.js'))
    .pipe(gulp.dest('./public'))
    .pipe(livereload());
}

// Tests task
function tests() {
    return browserify({
        entries: ['src/tests/test.coffee'],
        extensions: ['.coffee'],
        transform: ['coffeeify']
    })
    .bundle()
    .on('error', function(err) {
        log.error(err.message);
        this.emit('end');
    })
    .pipe(source('tests.js'))
    .pipe(gulp.dest('./gen'));
}

// Styles task - compile SCSS
function styles() {
    return gulp.src(['./src/**/*.scss'])
        .pipe(concat('app.css'))
        .pipe(sass().on('error', sass.logError))
        .pipe(gulp.dest('./public'))
        .pipe(livereload());
}

// Jade/Pug task - compile templates
function jade() {
    return gulp.src('./src/jade/index.jade')
        .pipe(pug().on('error', function(err) {
            log.error(err.message);
            this.emit('end');
        }))
        .pipe(gulp.dest('./public'))
        .pipe(livereload());
}

// Assets task - copy static files
function assets() {
    return gulp.src('./src/assets/**/*')
        .pipe(gulp.dest('./public'))
        .pipe(livereload());
}

// Watch task
function watch() {
    livereload.listen();
    gulp.watch('src/**/*.coffee', gulp.parallel(scripts, tests));
    gulp.watch('src/**/*.scss', styles);
    gulp.watch('src/**/*.jade', jade);
    gulp.watch('src/assets/**/*', assets);
}

// Server task
function serve(done) {
    const app = express();
    app.use(require('connect-livereload')());
    app.use(express.static(__dirname + '/public'));

    const port = 8765;
    app.listen(port, function() {
        log('=== Listening on port ' + port + '. ===');
        done();
    });
}

// Default task
exports.default = gulp.series(
    gulp.parallel(scripts, tests, styles, jade, assets),
    gulp.parallel(serve, watch)
);

exports.scripts = scripts;
exports.styles = styles;
exports.jade = jade;
exports.assets = assets;
exports.tests = tests;
