const gulp = require('gulp');
const sass = require('gulp-sass')(require('sass'));
const pug = require('gulp-pug');
const concat = require('gulp-concat');
const livereload = require('gulp-livereload');
const esbuild = require('esbuild');
const express = require('express');
const log = require('fancy-log');

function scripts() {
  return esbuild.build({
    entryPoints: ['src/client/app.ts'],
    bundle: true,
    outfile: 'public/app.js',
    platform: 'browser',
    sourcemap: true,
    minify: true,
    treeShaking: true,
    logLevel: 'info'
  }).then(() => {
    livereload.changed('public/app.js');
  }).catch((e) => { log.error(e); });
}

function styles() {
  return gulp.src(['./src/**/*.scss'])
    .pipe(concat('app.scss'))
    .pipe(sass().on('error', sass.logError))
    .pipe(gulp.dest('./public'))
    .pipe(livereload());
}

function jade() {
  return gulp.src('./src/jade/index.jade')
    .pipe(pug().on('error', (err) => { log.error(err.message); }))
    .pipe(gulp.dest('./public'))
    .pipe(livereload());
}

function assets() {
  return gulp.src('./src/assets/**/*')
    .pipe(gulp.dest('./public'))
    .pipe(livereload());
}

function watch() {
  livereload.listen();
  gulp.watch('src/**/*.ts', scripts);
  gulp.watch('src/**/*.tsx', scripts);
  gulp.watch('src/**/*.scss', styles);
  gulp.watch('src/**/*.jade', jade);
  gulp.watch('src/assets/**/*', assets);
}

function serve(done) {
  const app = express();
  app.use(require('connect-livereload')());
  app.use(express.static(__dirname + '/public'));
  app.listen(8765, () => { log('=== Listening on port 8765. ==='); done(); });
}

exports.default = gulp.series(
  gulp.parallel(scripts, styles, jade, assets),
  gulp.parallel(serve, watch)
);
exports.scripts = scripts;
exports.styles = styles;
exports.jade = jade;
exports.assets = assets;
