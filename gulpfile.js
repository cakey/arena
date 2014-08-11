require('coffee-script/register');
var gutil = require('gulp-util');

var gulpfile = 'Gulpfile.coffee';
gutil.log('Using file', gutil.colors.magenta(gulpfile));

require('./' + gulpfile);
